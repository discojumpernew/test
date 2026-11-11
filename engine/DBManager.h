#ifndef DBMANAGER_H
#define DBMANAGER_H

#pragma once

#include "DBWorker.h"

namespace db {

class DBManager : public QObject {

    Q_OBJECT
public:
    static QString HashPassword(const QString& password);

    explicit DBManager(QObject* parent = nullptr);
    ~DBManager();

public:
    void TryLogin(quint64 requestId, QString phone, QString passwd);
    void TryLogout(quint64 requestId, unsigned userId);
    void AddToHistory(quint64 requestId, unsigned userId, int added, QString idCode);
    void AddUser(quint64 requestId, QString phone, QString passwd, unsigned bonus);
    void Pulse(quint64 requestId, unsigned userId);
    void GetUserHistory(quint64 requestId, unsigned userId);
    void WriteNewBalance(quint64 requestId, unsigned userId, unsigned newBalance, QString idCode);
    void ValidateIdCode(quint64 requestId, QString code);
    void CheckBlockStatus(quint64 requestId, QString code);

    void CancelTask(quint64 requestId);
    void CancelAllInSet(QSet<quint64> idSet);

signals:
    void TryLoginResult(quint64, QueryStatus, std::optional<UserData>);
    void AddUserResult(quint64, QueryStatus);
    void PulseResult(quint64, QueryStatus);
    void GetUserHistoryResult(quint64, QueryStatus, QVector<historyElem>);
    void ValidateIdCodeResult(quint64, QueryStatus, bool blocked);
    void BlockStatusResult(quint64, bool blocked);

private:
    QThread workerThread_;
    DBWorker* worker_;
};
}

Q_DECLARE_METATYPE(db::historyElem)
Q_DECLARE_METATYPE(QVector<db::historyElem>)
#endif // DBMANAGER_H
