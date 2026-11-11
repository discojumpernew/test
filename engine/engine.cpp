#include "engine.h"
#include "DBManager.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

#define LOG_DEBUG 1

#ifndef APP_VERSION
#define APP_VERSION "1.1.0"
#endif

QString shop_id_str;
unsigned bonus = 0;

Engine::Engine(QString appdir, QObject* parent)
    : QObject(parent)
{
    Engine::appdir = appdir;

    LoadIdentity();

    modbusController = new ModbusController();

    timer = new QTimer();
    delayTimer = new QTimer();
    reconnectTimer = new QTimer();
    initTimer = new QTimer();
    heartBeat = new QTimer();
    elapsedTimer = new QElapsedTimer();
    elapsedTimerSession = new QElapsedTimer();
    // timeoutErrorTimer = new QTimer();

    dbManager = new db::DBManager(this);

    QObject::connect(dbManager, &db::DBManager::PulseResult, this, &Engine::OnPulseResultDB, Qt::QueuedConnection);
    QObject::connect(dbManager, &db::DBManager::AddUserResult, this, &Engine::OnAddUserResultDB, Qt::QueuedConnection);
    QObject::connect(dbManager, &db::DBManager::TryLoginResult, this, &Engine::OnTryLoginResultDB, Qt::QueuedConnection);
    QObject::connect(dbManager, &db::DBManager::GetUserHistoryResult, this, &Engine::OnGetUserHistoryResultDB, Qt::QueuedConnection);
    QObject::connect(dbManager, &db::DBManager::ValidateIdCodeResult, this, &Engine::OnValidateIdCodeResultDB, Qt::QueuedConnection);
    QObject::connect(dbManager, &db::DBManager::BlockStatusResult, this, &Engine::OnBlockStatusResultDB, Qt::QueuedConnection);

    timer->setInterval(10);
    reconnectTimer->setInterval(30000);
    initTimer->setInterval(initialization_timeout);
    // timeoutErrorTimer->setInterval(error_timeout);

    connect(timer, &QTimer::timeout, this, &Engine::tEvent);
    connect(delayTimer, &QTimer::timeout, this, &Engine::delayTimerSlot);
    connect(reconnectTimer, &QTimer::timeout, this, &Engine::reconnectTimerSlot);
    connect(initTimer, &QTimer::timeout, this, &Engine::initTimerSlot);
    // connect(timeoutErrorTimer, &QTimer::timeout, this, &Engine::timeoutErrorSlot);
    connect(this, &Engine::tryLogin, this, &Engine::OnTryLogin);
    connect(this, &Engine::tryRegister, this, &Engine::OnTryRegister);
    connect(this, &Engine::logout, this, &Engine::LogoutUser);
    connect(this, &Engine::successPay, this, &Engine::onSuccessPay);

    connect(heartBeat, &QTimer::timeout, this, &Engine::sendHeartbeat);
    heartBeat->start(1000);
}

Engine::~Engine()
{
    delete modbusController;
}

void Engine::onSuccessPay(int value)
{
    if (currentUser_.has_value()) {
        dbManager->AddToHistory(requestTracker_.nextId(), currentUser_->userId, value, idCode_);
    }

    newBalance = balance() + value;
    reset_balance = true;
    add_balance = true;
    emit showSession(0);
    showSessionMessage(false, QString::fromUtf8("Баланс пополнен."));
}

void Engine::networkLogout()
{
    LogoutUser();
    loadingHidden();
    showWaiting(true);
    showSessionMessage(true, QString::fromUtf8("Разорвано соединение. Совершен выход из аккаунта."));
}

void Engine::sendHeartbeat()
{
    // дистанционная блокировка поста/мойки: проверяем раз в ~15 секунд
    if (hasIdCode_ && ++blockCheckCounter_ >= 15) {
        blockCheckCounter_ = 0;
        auto requestId = requestTracker_.nextId();
        activeRequests_.insert(requestId);
        dbManager->CheckBlockStatus(requestId, idCode_);
    }

    if (lastBeat.secsTo(QTime::currentTime()) > 10) {
        networkLogout();
        lastBeat = QTime::currentTime();
        return;
    }

    if (currentUser_.has_value()) {
        auto requestId = requestTracker_.nextId();
        activeRequests_.insert(requestId);
        dbManager->Pulse(requestId, currentUser_->userId);
    } else {
        lastBeat = QTime::currentTime();
    }
}

void Engine::OnPulseResultDB(quint64 qId, db::QueryStatus result)
{
    if (activeRequests_.find(qId) != activeRequests_.end()) {
        activeRequests_.remove(qId);

        if (result == db::QueryStatus::Success) {
            lastBeat = QTime::currentTime();
        }
    }
}

void Engine::submitIdCode(const QString& code)
{
    QString trimmed = code.trimmed();
    if (trimmed.isEmpty()) {
        emit showSessionMessage(true, QString::fromUtf8("Введите ID код."));
        return;
    }

    pendingIdCode_ = trimmed;

    auto requestId = requestTracker_.nextId();
    activeRequests_.insert(requestId);
    WaitDBAnswer(requestId);
    dbManager->ValidateIdCode(requestId, trimmed);
}

void Engine::OnValidateIdCodeResultDB(quint64 qId, db::QueryStatus status, bool blocked)
{
    if (activeRequests_.find(qId) == activeRequests_.end())
        return;

    activeRequests_.remove(qId);

    if (waitId_.has_value() && *waitId_ == qId) {
        waitId_.reset();
        emit loadingHidden();
    }

    switch (status) {
    case db::QueryStatus::Success: {
        if (blocked) {
            emit showSessionMessage(true, QString::fromUtf8("Этот пост заблокирован. Обратитесь к администратору."));
            break;
        }

        idCode_ = pendingIdCode_;
        hasIdCode_ = true;
        SaveIdentity();
        emit idCodeChanged();
        emit showSessionMessage(false, QString::fromUtf8("ID код принят."));
        emit showWaiting(true);
        emit showSession(0);
        break;
    }
    case db::QueryStatus::NotFound: {
        emit showSessionMessage(true, QString::fromUtf8("Неизвестный ID код. Проверьте ввод."));
        break;
    }
    case db::QueryStatus::DbError: {
        emit showSessionMessage(true, QString::fromUtf8("Нет подключения к сети. Попробуйте позже."));
        break;
    }
    default:
        break;
    }
}

void Engine::OnBlockStatusResultDB(quint64 qId, bool blocked)
{
    if (activeRequests_.find(qId) != activeRequests_.end())
        activeRequests_.remove(qId);

    if (blocked == m_isBlocked)
        return;

    m_isBlocked = blocked;
    emit blockedChanged();

    if (blocked) {
        LogoutUser();
        emit showBlockedPage(true);
    } else {
        emit showBlockedPage(false);
        emit showWaiting(true);
        emit showSession(0);
    }
}

void Engine::initEvent()
{
    en::ConfigManager::s_modbus_config modbus_config;
    state = States::Initialization;
    emit showInitialization(0);

    QJsonObject ui_config;
    ui_config = en::ConfigManager::readUIConfig(appdir + FILE_PATH_UI_CONFIG, &error);
    if (error) {
        errorEvent();
        return;
    }

    slide_change_timeout = ui_config.value("SlideChangeTimeout").toInt();
    init_slide_change_mult = ui_config.value("InitSlideChangeMult").toInt();
    button_timeout = ui_config.value("ButtonTimeout").toInt();

    m_cleanerRate = ui_config.value("cleanerRate").toString();
    m_dryingRate = ui_config.value("dryingRate").toString();
    m_waterRate = ui_config.value("waterRate").toString();
    m_chemistryRate = ui_config.value("chemistryRate").toString();
    m_foamRate = ui_config.value("foamRate").toString();
    m_waxRate = ui_config.value("waxRate").toString();
    m_pauseRate = ui_config.value("pauseRate").toString();
    shop_id_str = ui_config.value("shopId").toString();
    bonus = ui_config.value("bonus").toInt();

    emit setUIConfig(ui_config);

    // пост не активирован ID кодом — показываем экран активации
    if (!hasIdCode_) {
        emit showIdSetup();
    }
    //=========================================

    // emit showSessionLocal();
    // return;

    //=========================================
    // Modbus device configuring
    modbus_config = en::ConfigManager::readModbusConfig(appdir + FILE_PATH_MODBUS_CONFIG, &error);
    if (error) {
        errorEvent();
        return;
    }

    // enable initialization timer
    if (!initTimer->isActive()) {
        initTimer->start();
    }

    error = modbusController->create();
    if (error) {
        timer->start();
        return;
    }

    error = modbusController->connect(modbus_config.PortName, modbus_config.Parity,
        modbus_config.BaudRate, modbus_config.DataBits,
        modbus_config.StopBits, modbus_config.ServerAddress,
        modbus_config.Timeout);

    timer->start();

    //=========================================
}

//==========================================
// Event States
void Engine::errorEvent()
{
    if (!initTimer->isActive()) {
        emit showError(error);
    }

    switch (error) {
    case Errors::MCTimeout:
        if (!reconnectTimer->isActive()) {
            reconnectTimer->start();
            error = modbusController->create();
            if (error)
                break;
            error = modbusController->connect();
        }
        break;
    case Errors::MCConnectionLost:
        error = modbusController->connect();
        break;
    case Errors::MCConnect:
        error = modbusController->create();
        if (error)
            break;

        error = modbusController->connect();
        break;
    case Errors::MCCreateDevice:
        error = modbusController->create();
        if (error)
            break;

        error = modbusController->connect();
        break;
    default:
        error = Errors::No;
        break;
    }
}

int Engine::waitingEvent()
{
    int error = Errors::No;
    ModbusController::s_session session;
    session = modbusController->readInSession();
    error = modbusController->getError();
    if (error)
        return error;

    setBalance(session.balance);
    setTime(QString::number(session.minute).rightJustified(2, '0') + ":" + QString::number(session.seconds).rightJustified(2, '0'));

    if (m_isBlocked)
        return modbusController->writeButtons(0x80); // пауза: пост заблокирован дистанционно

    error = modbusController->writeButtons(128 | BalanceRoutine());
    return error;
}

int Engine::sessionEvent()
{
    int error = Errors::No;
    ModbusController::s_session session;
    session = modbusController->readInSession();
    error = modbusController->getError();
    if (error)
        return error;

    setBalance(session.balance);
    setTime(QString::number(session.minute).rightJustified(2, '0') + ":" + QString::number(session.seconds).rightJustified(2, '0'));

    if (m_isBlocked)
        return modbusController->writeButtons(0x80); // пауза: пост заблокирован дистанционно

    if (pbuttons & 0x80)
        setPauseTime(QString::number(session.pause_minute).rightJustified(2, '0') + ":" + QString::number(session.pause_seconds).rightJustified(2, '0'));

    if (elapsedTimerSession->isValid()) {
        if (elapsedTimerSession->elapsed() < slide_change_timeout)
            return error;

        elapsedTimerSession->invalidate();
    }

    if (write_buttons) {
        elapsedTimer->start();
        write_buttons = false;
        error = modbusController->writeButtons(pbuttons | BalanceRoutine());
        if (error)
            return error;
    } else if ((pbuttons == 0) && (session.buttons != 0)) {
        emit setPressedButtons(session.buttons);
    } else if (pbuttons != session.buttons) {
        if (elapsedTimer->elapsed() > button_timeout) {
            elapsedTimer->invalidate();
            error = modbusController->writeButtons(session.buttons | BalanceRoutine());
            emit setPressedButtons(session.buttons);
        }
    } else if (pbuttons == session.buttons) {
        elapsedTimer->invalidate();
        emit setPressedButtons(session.buttons);
    }

    if (is_session_init <= 0) {
        setIsPauseFree(session.ispause_free);
    } else {
        is_session_init--;
    }

    elapsedTimerSession->start();

    return error;
}

// Transitions
int Engine::sessionTransition()
{
    int error = Errors::No;
    // todo optimize s_session
    ModbusController::s_session session;
    session = modbusController->readInSession();
    error = modbusController->getError();
    if (error)
        return error;

    setBalance(session.balance);
    setTime(QString::number(session.minute).rightJustified(2, '0') + ":" + QString::number(session.seconds).rightJustified(2, '0'));
    setPauseTime(QString::number(session.pause_minute).rightJustified(2, '0') + ":" + QString::number(session.pause_seconds).rightJustified(2, '0'));

    setIsPauseFree(true);
    emit setPressedButtons(0x80);
    is_session_init = init_slide_change_mult;
    elapsedTimerSession->start();

    return error;
}

void Engine::showSessionLocal()
{
    emit showSession(last_session_state);
}

void Engine::cppSetButtons(int buttons)
{
    write_buttons = true;
    pbuttons = buttons;
}

void Engine::cppClerButtonStateWallet()
{
    modbusController->clearButtonState(REG_CMD1_TPANEL, 0x600);
}

void Engine::tEvent()
{
    ModbusController::s_status status;
    static int last_status_raw = -1;

    if (!error || error == Errors::MCPLC || error == Errors::MCTimeout) {
        status = modbusController->readStatus();
        error = 0;
        if ((state == States::Initialization) && !status.pingerror) {
            if (!elapsedTimer->isValid()) {
                emit showInitialization(1);
                elapsedTimer->start();
            }

            if (elapsedTimer->elapsed() > 500) {
                initTimer->stop();
                elapsedTimer->invalidate();
                state = setState(status);
                stateTransition(state, status);
            } else if (elapsedTimer->elapsed() > 250)
                emit showInitialization(2);
        }

        last_error = error;
    }

    if (modbusController->isConnected() && !error && (state != States::Initialization)) {
        state = setState(status);
        if (status.raw != last_status_raw) {
            error = stateTransition(state, status);
        }

        if (!error)
            error = stateEvent(state);
    } else {
        errorEvent();
    }
    last_status_raw = status.raw;
}

int Engine::setState(ModbusController::s_status status)
{
    int state = States::Waiting;
    if (status.session) {
        state = States::Session;
    }

    return state;
}

int Engine::stateTransition(int state, ModbusController::s_status status)
{
    int error = Errors::No;
    switch (state) {
    case States::Waiting:
        emit showWaiting(true);
        emit showSession(0);
        break;
    case States::Session:
        error = sessionTransition();
        last_session_state = status.session;
        emit showWaiting(false);
        break;
    }

    return error;
}

int Engine::stateEvent(int state)
{
    int error = 0;

    switch (state) {
        case States::Session:
            error = sessionEvent();
            break;
        case States::Waiting:
            error = waitingEvent();
            break;
    }

    return error;
}

void Engine::delayTimerSlot()
{
    delayTimer->stop();
    timer->start();
}

void Engine::reconnectTimerSlot()
{
    reconnectTimer->stop();
}

void Engine::initTimerSlot()
{
    initTimer->stop();
}

void Engine::OnTryLogin(QString phone, QString passwd)
{
    auto requestId = requestTracker_.nextId();
    activeRequests_.insert(requestId);
    WaitDBAnswer(requestId);
    dbManager->TryLogin(requestId, phone, passwd);
}

void Engine::OnTryLoginResultDB(quint64 qId, db::QueryStatus status, std::optional<db::UserData> uData)
{
    if (activeRequests_.find(qId) != activeRequests_.end()) {
        activeRequests_.remove(qId);

        if (waitId_.has_value() && *waitId_ == qId) {
            waitId_.reset();
            emit loadingHidden();
        }

        switch (status) {
        case db::QueryStatus::DbError: {
            emit showLoginMessage(true, QString::fromUtf8("Отсутствует подключение к сети. Попробуйте позже."));
            break;
        }
        case db::QueryStatus::NotFound: {
            emit showLoginMessage(true, QString::fromUtf8("Неверный логин или пароль."));
            break;
        }
        case db::QueryStatus::Duplicate: {
            emit showLoginMessage(true, QString::fromUtf8("Пользователь уже активен на другом боксе."));
            break;
        }
        case db::QueryStatus::Success: {
            currentUser_ = uData;
            lastBeat = QTime::currentTime();

            newBalance = currentUser_->balance + balance();
            reset_balance = true;
            add_balance = true;

            emit showWaiting(newBalance == 0);
            emit showSession(0);
            emit currentUserChanged();
            break;
        }
        }
    }
}

void Engine::OnGetUserHistoryResultDB(quint64 qId, db::QueryStatus status, QVector<db::historyElem> history)
{
    if (activeRequests_.find(qId) != activeRequests_.end()) {
        activeRequests_.remove(qId);

        if (waitId_.has_value() && *waitId_ == qId) {
            waitId_.reset();
            emit loadingHidden();
        }

        switch (status) {
        case db::QueryStatus::DbError: {
            emit showSessionMessage(true, QString::fromUtf8("Отсутствует подключение к сети. Попробуйте позже."));
            break;
        }
        case db::QueryStatus::Success: {
            QVariantList list;
            for (const auto& elem : history) {
                QVariant var;
                var.setValue(elem);
                list.append(var);
            }

            emit showHistory(list);
            break;
        }
        }
    }
}

void Engine::OnTryRegister(QString phone, QString passwd)
{
    QDateTime now = QDateTime::currentDateTime();

    if (lastRegistrationTime_.isValid() && lastRegistrationTime_.secsTo(now) < registrationCooldownSec_) {
        emit showRegisterMessage(true, QString::fromUtf8("Регистрация недоступна. Попробуйте позже."));
        return;
    }

    auto requestId = requestTracker_.nextId();
    activeRequests_.insert(requestId);
    WaitDBAnswer(requestId);
    dbManager->AddUser(requestId, phone, db::DBManager::HashPassword(passwd), bonus);
}

void Engine::OnAddUserResultDB(quint64 qId, db::QueryStatus status)
{
    if (activeRequests_.find(qId) != activeRequests_.end()) {
        activeRequests_.remove(qId);

        if (waitId_.has_value() && *waitId_ == qId) {
            waitId_.reset();
            emit loadingHidden();
        }

        switch (status) {
        case db::QueryStatus::Success: {
            lastRegistrationTime_ = QDateTime::currentDateTime();
            emit showLogin();
            emit showLoginMessage(false, QString::fromUtf8("Успешная регистрация."));
            break;
        }
        case db::QueryStatus::DbError: {
            emit showRegisterMessage(true, QString::fromUtf8("Отсутствует подключение к сети. Попробуйте позже."));
            break;
        }
        case db::QueryStatus::Duplicate: {
            emit showRegisterMessage(true, QString::fromUtf8("Уже существует пользователь с таким номером телефона."));
            break;
        }
        }
    }
}

void Engine::LogoutUser()
{
    if (currentUser_.has_value()) {
        unsigned id = currentUser_->userId;
        currentUser_.reset();
        dbManager->TryLogout(requestTracker_.nextId(), id);
        emit currentUserChanged();
        reset_balance = true;
    }

    dbManager->CancelAllInSet(activeRequests_);
    activeRequests_.clear();
}

void Engine::WaitDBAnswer(quint64 qId)
{
    waitId_ = qId;
    emit loadingShown();
}

void Engine::StopWaitAnswer(quint64 qId)
{
    activeRequests_.remove(*waitId_);
    dbManager->CancelTask(qId);
}

quint16 Engine::BalanceRoutine()
{
    if (reset_balance) {
        if (error == Errors::No) {
            return (1 << 9);
        } else {
            errorEvent();
        }
    } else if (add_balance) {
        error = modbusController->writeNewBalance(newBalance);
        if (error == Errors::No) {
            return (1 << 8);
        } else {
            errorEvent();
        }
    }

    return 0;
}

//=========================================
// Properties
int Engine::balance() const
{
    return m_balance;
}

void Engine::setBalance(int balance)
{
    if (balance == 0) {
        reset_balance = false;
    }

    if (balance == newBalance && !reset_balance) {
        add_balance = false;
    }

    if (m_balance == balance)
        return;

    if (currentUser_.has_value()) {
        auto requestId = requestTracker_.nextId();
        activeRequests_.insert(requestId);
        dbManager->WriteNewBalance(requestId, currentUser_->userId, balance, idCode_);
    }

    m_balance = balance;
    emit balanceChanged(m_balance);
}

QString Engine::time() const
{
    return m_time;
}

void Engine::setTime(QString time)
{
    if (m_time == time)
        return;

    m_time = time;
    emit timeChanged(m_time);
}

QString Engine::pause_time() const
{
    return m_pause_time;
}

void Engine::setPauseTime(QString pause_time)
{
    if (m_pause_time == pause_time)
        return;

    m_pause_time = pause_time;
    emit pauseTimeChanged(m_pause_time);
}

int Engine::discountfix() const
{
    return m_discountfix;
}

void Engine::setDiscountfix(int discountfix)
{
    if (m_discountfix == discountfix)
        return;

    m_discountfix = discountfix;
    emit discountfixChanged(m_discountfix);
}

int Engine::discountacc() const
{
    return m_discountacc;
}

void Engine::setDiscountacc(int discountacc)
{
    if (m_discountacc == discountacc)
        return;

    m_discountacc = discountacc;
    emit discountaccChanged(m_discountacc);
}

int Engine::deposit() const
{
    return m_deposit;
}

void Engine::setDeposit(int deposit)
{
    if (m_deposit == deposit)
        return;

    m_deposit = deposit;
    emit depositChanged(m_deposit);
}

QString Engine::date() const
{
    return m_date;
}

void Engine::setDate(QString date)
{
    if (m_date == date)
        return;

    m_date = date;
    emit dateChanged(m_date);
}

QString Engine::cleanerRate() const
{
    return m_cleanerRate;
}
QString Engine::dryingRate() const
{
    return m_dryingRate;
}
QString Engine::waterRate() const
{
    return m_waterRate;
}
QString Engine::chemistryRate() const
{
    return m_chemistryRate;
}
QString Engine::foamRate() const
{
    return m_foamRate;
}
QString Engine::waxRate() const
{
    return m_waxRate;
}
QString Engine::pauseRate() const
{
    return m_pauseRate;
}

int Engine::colbalance() const
{
    return m_colbalance;
}

void Engine::setColbalance(int colbalance)
{
    if (m_colbalance == colbalance)
        return;

    m_colbalance = colbalance;
    emit colbalanceChanged(m_colbalance);
}

int Engine::colcash() const
{
    return m_colcash;
}

void Engine::setColcash(int colcash)
{
    if (m_colcash == colcash)
        return;

    m_colcash = colcash;
    emit colcashChanged(m_colcash);
}

bool Engine::ispause_free() const
{
    return m_ispause_free;
}

bool Engine::hasCurrentUser() const
{
    return currentUser_.has_value();
}

bool Engine::hasIdCode() const
{
    return hasIdCode_;
}

QString Engine::idCode() const
{
    return idCode_;
}

bool Engine::isBlocked() const
{
    return m_isBlocked;
}

QString Engine::appVersion() const
{
    return QString::fromLatin1(APP_VERSION);
}

void Engine::LoadIdentity()
{
    QFile file(appdir + FILE_PATH_ID_CONFIG);
    if (!file.open(QIODevice::ReadOnly)) {
        hasIdCode_ = false;
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();

    QString code = doc.object().value("id_code").toString().trimmed();
    if (!code.isEmpty()) {
        idCode_ = code;
        hasIdCode_ = true;
    } else {
        hasIdCode_ = false;
    }
}

void Engine::SaveIdentity()
{
    QJsonObject obj;
    obj.insert("id_code", idCode_);

    QFile file(appdir + FILE_PATH_ID_CONFIG);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "Failed to save id.json:" << file.errorString();
        return;
    }

    file.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
    file.close();
}


void Engine::setIsPauseFree(bool ispause_free)
{
    if (m_ispause_free == ispause_free)
        return;

    m_ispause_free = ispause_free;
    emit isPauseFreeChanged(m_ispause_free);
}
//=========================================
