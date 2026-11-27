#ifndef ENGINE_H
#define ENGINE_H

#include <QDateTime>
#include <QDebug>
#include <QElapsedTimer>
#include <QObject>
#include <QTimer>

#include <optional>

#include "DBManager.h"
#include "controller/modbuscontroller.h"
#include "engine/configmanager.h"

#define FILE_PATH_MODBUS_CONFIG "/config/modbus.json"
#define FILE_PATH_UI_CONFIG "/config/ui.json"
#define FILE_PATH_ID_CONFIG "/config/id.json"
#define FILE_PATH_LOG "/log/"

class RequestTracker : public QObject {
    Q_OBJECT
public:
    quint64 nextId()
    {
        return ++counter_;
    }

private:
    quint64 counter_ = 0;
};

class Engine : public QObject {
    Q_OBJECT
public:
    Q_PROPERTY(int balance READ balance WRITE setBalance NOTIFY balanceChanged)
    Q_PROPERTY(QString time READ time WRITE setTime NOTIFY timeChanged)
    Q_PROPERTY(QString pause_time READ pause_time WRITE setPauseTime NOTIFY pauseTimeChanged)
    Q_PROPERTY(int discountfix READ discountfix WRITE setDiscountfix NOTIFY discountfixChanged)
    Q_PROPERTY(int discountacc READ discountacc WRITE setDiscountacc NOTIFY discountaccChanged)
    Q_PROPERTY(int deposit READ deposit WRITE setDeposit NOTIFY depositChanged)
    Q_PROPERTY(QString date READ date WRITE setDate NOTIFY dateChanged)
    Q_PROPERTY(int colbalance READ colbalance WRITE setColbalance NOTIFY colbalanceChanged)
    Q_PROPERTY(int colcash READ colcash WRITE setColcash NOTIFY colcashChanged)
    Q_PROPERTY(bool ispause_free READ ispause_free WRITE setIsPauseFree NOTIFY isPauseFreeChanged)
    Q_PROPERTY(bool hasCurrentUser READ hasCurrentUser NOTIFY currentUserChanged)
    Q_PROPERTY(bool hasIdCode READ hasIdCode NOTIFY idCodeChanged)
    Q_PROPERTY(QString idCode READ idCode NOTIFY idCodeChanged)
    Q_PROPERTY(bool isBlocked READ isBlocked NOTIFY blockedChanged)
    Q_PROPERTY(QString appVersion READ appVersion CONSTANT)
    // true, если контроллер мойки (ПЛК) не отвечает: терминал работает без оборудования,
    // оплата блокируется, в интерфейсе показывается предупреждение.
    Q_PROPERTY(bool plcOffline READ plcOffline NOTIFY plcOfflineChanged)
    // true, если контроллер симулируется (нет COM-порта): все экраны доступны,
    // но реальные списания денег отключены.
    Q_PROPERTY(bool demoMode READ demoMode NOTIFY demoModeChanged)

    Q_INVOKABLE void submitIdCode(const QString& code);

    // Демо-пополнение и запуск мойки (симуляция, без YooKassa/ПЛК)
    Q_INVOKABLE void demoPay(int value);
    Q_INVOKABLE void demoStartWash();

    // Оплата из заставки ожидания: без связи с контроллером не пускаем в оплату,
    // иначе клиент заплатит, а мойка не запустится.
    Q_INVOKABLE void requestPayment();

    Q_PROPERTY(QString cleanerRate READ cleanerRate WRITE setCleanerRate NOTIFY cleanerRateChanged)
    Q_PROPERTY(QString dryingRate READ dryingRate WRITE setDryingRate NOTIFY dryingRateChanged)
    Q_PROPERTY(QString waterRate READ waterRate WRITE setWaterRate NOTIFY waterRateChanged)
    Q_PROPERTY(QString chemistryRate READ chemistryRate WRITE setChemistryRate NOTIFY chemistryRateChanged)
    Q_PROPERTY(QString foamRate READ foamRate WRITE setFoamRate NOTIFY foamRateChanged)
    Q_PROPERTY(QString waxRate READ waxRate WRITE setWaxRate NOTIFY waxRateChanged)
    Q_PROPERTY(QString pauseRate READ pauseRate WRITE setPauseRate NOTIFY pauseRateChanged)

    // === Админ-панель: дизайн и конфигурация программ/платежей ===
    // Дизайн интерфейса: "classic" (старый) | "duck" (новый, с уткой)
    Q_PROPERTY(QString designTheme READ designTheme WRITE setDesignTheme NOTIFY designThemeChanged)
    // Видимость программ на экране сессии
    Q_PROPERTY(bool progTurbo READ progTurbo WRITE setProgTurbo NOTIFY progTurboChanged)
    Q_PROPERTY(bool progVacuum READ progVacuum WRITE setProgVacuum NOTIFY progVacuumChanged)
    Q_PROPERTY(bool progChemistry READ progChemistry WRITE setProgChemistry NOTIFY progChemistryChanged)
    Q_PROPERTY(bool progWax READ progWax WRITE setProgWax NOTIFY progWaxChanged)
    Q_PROPERTY(bool progFoamPink READ progFoamPink WRITE setProgFoamPink NOTIFY progFoamPinkChanged)
    Q_PROPERTY(bool progFoamYellow READ progFoamYellow WRITE setProgFoamYellow NOTIFY progFoamYellowChanged)
    Q_PROPERTY(bool progFoamWhite READ progFoamWhite WRITE setProgFoamWhite NOTIFY progFoamWhiteChanged)
    // Способы оплаты
    Q_PROPERTY(bool payCash READ payCash WRITE setPayCash NOTIFY payCashChanged)
    Q_PROPERTY(bool paySbp READ paySbp WRITE setPaySbp NOTIFY paySbpChanged)
    Q_PROPERTY(bool payCard READ payCard WRITE setPayCard NOTIFY payCardChanged)

    // Админ-панель: сохранить настройки в БД (применяются сразу и сохраняются)
    Q_INVOKABLE void adminSaveSettings(const QVariantMap& settings);
    // Перезагрузить настройки из БД (например, при открытии панели)
    Q_INVOKABLE void adminReloadSettings();

    Q_INVOKABLE void cancelLoading()
    {
        if (waitId_.has_value()) {
            StopWaitAnswer(*waitId_);
            waitId_.reset();
        }

        loadingHidden();
    }

    Q_INVOKABLE void requestHistory()
    {
        if (currentUser_.has_value()) {
            auto requestId = requestTracker_.nextId();
            activeRequests_.insert(requestId);
            WaitDBAnswer(requestId);
            dbManager->GetUserHistory(requestId, currentUser_->userId);
        }
    }

    // Ворота: бит 13 регистра 0 (ChTreid). ПЛК открывает ворота по переднему
    // фронту бита (DO8, импульс 1 с). Панель держит бит ~1.5 с и снимает.
    Q_INVOKABLE void openGates()
    {
        if (offlineMode_) {
            emit showSessionMessage(true, QString::fromUtf8("Нет связи с оборудованием мойки."));
            return;
        }
        if (demoMode_) {
            emit showSessionMessage(false, QString::fromUtf8("ДЕМО: ворота открыты (симуляция)."));
            return;
        }
        gateHold = true;
        gateTimer.start();
    }

    explicit Engine(QString appdir, QObject* parent = nullptr);
    ~Engine();

    void initEvent();

    // Properties
    int balance() const;
    QString time() const;
    QString pause_time() const;
    int discountfix() const;
    int discountacc() const;
    int deposit() const;
    QString date() const;
    int colbalance() const;
    int colcash() const;
    bool ispause_free() const;
    bool hasCurrentUser() const;
    bool hasIdCode() const;
    QString idCode() const;
    bool isBlocked() const;
    bool plcOffline() const;
    bool demoMode() const;
    QString appVersion() const;
    QString cleanerRate() const;
    QString dryingRate() const;
    QString waterRate() const;
    QString chemistryRate() const;
    QString foamRate() const;
    QString waxRate() const;
    QString pauseRate() const;

    QString designTheme() const;
    bool progTurbo() const;
    bool progVacuum() const;
    bool progChemistry() const;
    bool progWax() const;
    bool progFoamPink() const;
    bool progFoamYellow() const;
    bool progFoamWhite() const;
    bool payCash() const;
    bool paySbp() const;
    bool payCard() const;

signals:
    void loadingShown();
    void loadingHidden();

    void showInitialization(int state, QString text = "");
    void showError(int error, QString text = "");
    void showLoginMessage(bool isError, QString text);
    void showRegisterMessage(bool isError, QString text);
    void showSessionMessage(bool isError, QString text);
    void showWaiting(bool isWaiting);
    void showSession(int state);
    void showLogin();
    void showRegister();
    void showPSection();
    void plcOfflineChanged();
    void demoModeChanged();
    void tryLogin(QString phone, QString passwd);
    void tryRegister(QString phone, QString passwd);

    void currentUserChanged();
    void idCodeChanged();
    void blockedChanged();
    void showIdSetup();
    void showBlockedPage(bool blocked);
    void cleanerRateChanged();
    void dryingRateChanged();
    void waterRateChanged();
    void chemistryRateChanged();
    void foamRateChanged();
    void waxRateChanged();
    void pauseRateChanged();

    void designThemeChanged();
    void progTurboChanged();
    void progVacuumChanged();
    void progChemistryChanged();
    void progWaxChanged();
    void progFoamPinkChanged();
    void progFoamYellowChanged();
    void progFoamWhiteChanged();
    void payCashChanged();
    void paySbpChanged();
    void payCardChanged();
    void adminSettingsSaved(bool ok);
    void showAdmin();

    void successPay(int value);
    void logout();
    void showHistory(QVariantList);
    void showCash();
    void showPriceList();
    void showSbp();
    void showInstruction();
    void showCard();

    void setPressedButtons(int buttons);
    void setUIConfig(QJsonObject config);

    // Properties
    void balanceChanged(int balance);
    void timeChanged(QString time);
    void pauseTimeChanged(QString pause_time);
    void discountfixChanged(int discountfix);
    void discountaccChanged(int discountacc);
    void depositChanged(int deposit);
    void dateChanged(QString date);
    void colbalanceChanged(int colbalance);
    void colcashChanged(int colcash);
    void isPauseFreeChanged(bool ispause_free);
public slots:
    void cppSetButtons(int buttons);
    void cppClerButtonStateWallet();

    // Properties
    void setBalance(int balance);
    void setTime(QString time);
    void setPauseTime(QString pause_time);
    void setDiscountfix(int dicountfix);
    void setDiscountacc(int dicountacc);
    void setDeposit(int deposit);
    void setDate(QString date);
    void setColbalance(int colbalance);
    void setColcash(int colcash);
    void setIsPauseFree(bool ispause_free);
    void onSuccessPay(int value);
    void sendHeartbeat();
    void networkLogout();

public slots:
    void OnTryLoginResultDB(quint64, db::QueryStatus, std::optional<db::UserData>);
    void OnAddUserResultDB(quint64, db::QueryStatus);
    void OnPulseResultDB(quint64, db::QueryStatus);
    void OnGetUserHistoryResultDB(quint64, db::QueryStatus, QVector<db::historyElem>);
    void OnValidateIdCodeResultDB(quint64, db::QueryStatus, bool blocked);
    void OnBlockStatusResultDB(quint64, bool blocked);
    void OnTerminalSettingsResultDB(quint64, QVariantMap);
    void OnTerminalSettingsSavedDB(quint64, bool ok);

    // === Setters для свойств админ-настроек ===
    void setCleanerRate(QString v);
    void setDryingRate(QString v);
    void setWaterRate(QString v);
    void setChemistryRate(QString v);
    void setFoamRate(QString v);
    void setWaxRate(QString v);
    void setPauseRate(QString v);
    void setDesignTheme(QString v);
    void setProgTurbo(bool v);
    void setProgVacuum(bool v);
    void setProgChemistry(bool v);
    void setProgWax(bool v);
    void setProgFoamPink(bool v);
    void setProgFoamYellow(bool v);
    void setProgFoamWhite(bool v);
    void setPayCash(bool v);
    void setPaySbp(bool v);
    void setPayCard(bool v);

private:
    void OnTryLogin(QString phone, QString passwd);
    void OnTryRegister(QString phone, QString passwd);
    void LogoutUser();
    quint16 BalanceRoutine();
    void WaitDBAnswer(quint64 qId);
    void StopWaitAnswer(quint64 qId);
    void LoadIdentity();
    void SaveIdentity();

    enum States {
        Initialization = 0,
        Error,
        Waiting,
        Session
    };

    QDateTime lastRegistrationTime_;
    const int registrationCooldownSec_ = 10 * 60; // 10 минут в секундах

    db::DBManager* dbManager;

    RequestTracker requestTracker_;
    QSet<quint64> activeRequests_;
    std::optional<db::UserData> currentUser_;
    std::optional<quint64> waitId_;

    QString idCode_;
    QString pendingIdCode_;
    bool hasIdCode_ = false;
    bool m_isBlocked = false;
    // ПЛК недоступен: заставка инициализации не должна висеть вечно.
    bool offlineMode_ = false;
    // Симуляция ПЛК для тестирования интерфейса без оборудования.
    bool demoMode_ = false;
    // Экран ошибки показываем один раз, а не каждые 10 мс.
    bool errorPageShown_ = false;
    int blockCheckCounter_ = 0;

    QString appdir;

    ModbusController* modbusController;
    QTimer* timer;
    QTimer* delayTimer;
    QTimer* reconnectTimer;
    QTimer* initTimer;
    QElapsedTimer* elapsedTimer;
    QElapsedTimer* elapsedTimerSession;
    QElapsedTimer gateTimer;
    bool gateHold = false;
    QTimer* heartBeat;

    int state;
    int initialization_timeout = 30000;
    int error_timeout = 5000;
    int is_session_init;
    QTime lastBeat;

    int slide_change_timeout = 1000;
    int init_slide_change_mult = 3;
    int button_timeout = 5000;

    bool write_buttons = false;
    unsigned int pbuttons = 0;

    int error = Errors::No;
    int last_error = Errors::No;
    int last_session_state = 0;

    // Properties
    int m_balance { 0 };
    QString m_time { "" };
    QString m_pause_time { "" };
    int m_discountfix { 0 };
    int m_discountacc { 0 };
    int m_deposit { 0 };
    QString m_date { "" };
    int m_colbalance { 0 };
    int m_colcash { 0 };
    bool m_ispause_free { false };

    bool reset_balance = false;
    bool add_balance = false;
    quint16 newBalance = 0;

    QString m_cleanerRate { "" };
    QString m_dryingRate { "" };
    QString m_waterRate { "" };
    QString m_chemistryRate { "" };
    QString m_foamRate { "" };
    QString m_waxRate { "" };
    QString m_pauseRate { "" };

    // Админ-настройки (грузятся из terminal_settings, дефолты — classic/всё включено)
    QString m_designTheme { "classic" };
    bool m_progTurbo { true };
    bool m_progVacuum { true };
    bool m_progChemistry { true };
    bool m_progWax { true };
    bool m_progFoamPink { true };
    bool m_progFoamYellow { true };
    bool m_progFoamWhite { true };
    bool m_payCash { true };
    bool m_paySbp { true };
    bool m_payCard { true };

    void errorEvent();
    int sessionEvent();
    int waitingEvent();

    // Если ПЛК не подключился за несколько секунд — уходим в режим без контроллера,
    // чтобы терминал не висел на заставке «ИНИЦИАЛИЗАЦИЯ».
    void scheduleOfflineFallback();
    void enterOfflineMode();

    int sessionTransition();

    int setState(ModbusController::s_status status);
    int stateTransition(int state, ModbusController::s_status status);
    int stateEvent(int state);

private slots:
    void tEvent();
    void delayTimerSlot();
    void reconnectTimerSlot();
    void initTimerSlot();

    void showSessionLocal();
};

#endif // ENGINE_H
