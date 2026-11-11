#ifndef DBWORKER_H
#define DBWORKER_H

#include <QDateTime>
#include <QObject>
#include <QtCore>
#include <QtSql>

#include <optional>

#include "MPMCBlockingQueue.h"

namespace db {

extern QString host;
extern QString dbName;
extern QString user;
extern QString password;

enum class QueryStatus {
    Success,
    NotFound,
    Duplicate,
    DbError
};

struct UserData {
    UserData() = default;
    UserData(unsigned id, QString phone_, QString password_, unsigned balance_)
        : userId(id)
        , phone(std::move(phone_))
        , password(std::move(password_))
        , balance(balance_)
    {
    }

    unsigned userId;
    QString phone;
    QString password;
    unsigned balance;
};

struct historyElem {
    Q_GADGET

    Q_PROPERTY(unsigned id MEMBER id)
    Q_PROPERTY(unsigned userId MEMBER userId)
    Q_PROPERTY(int amount MEMBER amount)
    Q_PROPERTY(QDateTime createdAt MEMBER createdAt)

public:
    unsigned id;
    unsigned userId;
    int amount;
    QDateTime createdAt;
};

struct Task {
    quint64 requestId;
    std::function<void()> action;
};

class DBWorker : public QObject {
    Q_OBJECT
public slots:
    void processLoop();

public:
    ~DBWorker();

    MPMCBlockingQueue<Task> queue;
    std::atomic_bool running { true };

    void TryLogin(quint64 requestId, QString phone, QString passwd);
    void TryLogout(unsigned userId);
    void AddToHistory(unsigned userId, int added, QString idCode);
    void AddUser(quint64 requestId, QString phone, QString passwd, unsigned initialBalance);
    void Pulse(quint64 requestId, unsigned userId);
    void GetUserHistory(quint64 requestId, unsigned userId);
    void WriteNewBalance(unsigned userId, unsigned newBalance, QString idCode);

    void ValidateIdCode(quint64 requestId, QString code);
    void CheckBlockStatus(quint64 requestId, QString code);
    void EnsureRemoteSchema();

signals:
    void TryLoginResult(quint64, QueryStatus, std::optional<UserData>);
    void AddUserResult(quint64, QueryStatus);
    void PulseResult(quint64, QueryStatus);
    void GetUserHistoryResult(quint64, QueryStatus, QVector<historyElem>);
    void ValidateIdCodeResult(quint64, QueryStatus, bool blocked);
    void BlockStatusResult(quint64, bool blocked);

private:
    bool TryOpenRemote();
    bool TryOpenLocal();

    void SendLocalHistory();
    void ReloadConnection();
    bool QueryBlockedState(const QString& code, bool* blocked, db::QueryStatus* status);

    QSqlDatabase remoteDB_;
    QSqlDatabase localDB_;
};
}

#endif // DBWORKER_H
