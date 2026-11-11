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

    Q_INVOKABLE void submitIdCode(const QString& code);

    Q_PROPERTY(QString cleanerRate READ cleanerRate NOTIFY cleanerRateChanged)
    Q_PROPERTY(QString dryingRate READ dryingRate NOTIFY dryingRateChanged)
    Q_PROPERTY(QString waterRate READ waterRate NOTIFY waterRateChanged)
    Q_PROPERTY(QString chemistryRate READ chemistryRate NOTIFY chemistryRateChanged)
    Q_PROPERTY(QString foamRate READ foamRate NOTIFY foamRateChanged)
    Q_PROPERTY(QString waxRate READ waxRate NOTIFY waxRateChanged)
    Q_PROPERTY(QString pauseRate READ pauseRate NOTIFY pauseRateChanged)

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
    QString appVersion() const;
    QString cleanerRate() const;
    QString dryingRate() const;
    QString waterRate() const;
    QString chemistryRate() const;
    QString foamRate() const;
    QString waxRate() const;
    QString pauseRate() const;

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
    int blockCheckCounter_ = 0;

    QString appdir;

    ModbusController* modbusController;
    QTimer* timer;
    QTimer* delayTimer;
    QTimer* reconnectTimer;
    QTimer* initTimer;
    QElapsedTimer* elapsedTimer;
    QElapsedTimer* elapsedTimerSession;
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

    void errorEvent();
    int sessionEvent();
    int waitingEvent();

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
