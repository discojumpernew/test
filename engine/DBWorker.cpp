#include "DBWorker.h"

#include <QDebug>

static const QString LocalDBPath = "local.db";

void db::DBWorker::processLoop()
{
    remoteDB_ = QSqlDatabase::addDatabase("QMYSQL", "remote");
    localDB_ = QSqlDatabase::addDatabase("QSQLITE", "local");

    TryOpenLocal();
    TryOpenRemote();

    while (running) {
        Task task = queue.take();
        if (task.action)
            task.action();
    }

    this->deleteLater();
}

db::DBWorker::~DBWorker()
{
    qDebug() << "DBWorker finished";
    if (remoteDB_.isOpen()) {
        remoteDB_.close();
    }

    if (localDB_.isOpen()) {
        localDB_.close();
    }
}

bool db::DBWorker::TryOpenRemote()
{
    bool result = true;
    if (!remoteDB_.isOpen()) { // open remote connection
        remoteDB_.setHostName(db::host);
        remoteDB_.setDatabaseName(db::dbName);
        remoteDB_.setUserName(db::user);
        remoteDB_.setPassword(db::password);
        if (!remoteDB_.open()) {
            qWarning() << "Failed to open server MySQL DB:" << remoteDB_.lastError();
            result = false;
        }
    }

    return result;
}

bool db::DBWorker::TryOpenLocal()
{
    bool result = true;
    if (!localDB_.isOpen()) { // open local connection
        bool firstTime = !QFile::exists(LocalDBPath);
        localDB_.setDatabaseName(LocalDBPath);

        if (!localDB_.open()) {
            qWarning() << "Failed to open local SQLite DB:" << localDB_.lastError();
            result = false;
        }

        if (firstTime) {
            QSqlQuery query(localDB_);
            if (!query.exec(R"(
                           CREATE TABLE IF NOT EXISTS history (
                               id INTEGER PRIMARY KEY AUTOINCREMENT,
                               user_id INTEGER NOT NULL,
                               amount INTEGER NOT NULL,
                               created_at TEXT DEFAULT (DATETIME('now')),
                               is_committed INTEGER NOT NULL DEFAULT 1
                           )
                       )")) {
                qWarning() << "Failed to create history table:" << query.lastError();
                result = false;
            }
        }
    }

    return result;
}

void db::DBWorker::ReloadConnection()
{
    qWarning() << "RELOAD";
    remoteDB_.close();
    TryOpenRemote();
}

void db::DBWorker::WriteNewBalance(unsigned userId, unsigned newBalance)
{
    SendLocalHistory();

    if (TryOpenRemote() && TryOpenLocal()) {
        QSqlQuery localQuery(localDB_);
        localQuery.prepare("SELECT id, amount, created_at FROM history WHERE user_id = :uid AND is_committed = 1");
        localQuery.bindValue(":uid", userId);
        if (localQuery.exec()) {
            QList<QVariantList> committedRows;
            while (localQuery.next()) {
                QVariantList row;
                row << localQuery.value("id") // 0
                    << userId // 1
                    << localQuery.value("amount") // 2
                    << localQuery.value("created_at"); // 3
                committedRows.append(row);
            }

            QSqlQuery remoteQuery(remoteDB_);
            for (const QVariantList& row : committedRows) {
                remoteQuery.prepare("INSERT INTO history (user_id, amount, created_at, is_committed) "
                                    "VALUES (:uid, :am, :created, 1)");
                remoteQuery.bindValue(":uid", row[1]);
                remoteQuery.bindValue(":am", row[2]);
                remoteQuery.bindValue(":created", row[3]);

                if (!remoteQuery.exec()) {
                    ReloadConnection();
                    return;
                }
            }

            remoteQuery.prepare("Update users set balance = :bal WHERE id = :id");
            remoteQuery.bindValue(":bal", newBalance);
            remoteQuery.bindValue(":id", userId);

            if (!remoteQuery.exec()) {
                ReloadConnection();
                return;
            }

            if (!committedRows.isEmpty()) {
                QStringList ids;
                for (const auto& row : committedRows)
                    ids << row[0].toString();

                localQuery.prepare("DELETE FROM history WHERE id IN (" + ids.join(",") + ")");
                if (!localQuery.exec()) {
                    return;
                }
            }

            return;
        }
    }

    ReloadConnection();
    return;
}

void db::DBWorker::Pulse(quint64 requestId, unsigned userId)
{
    if (TryOpenRemote()) {
        QSqlQuery query(remoteDB_);
        query.prepare(R"(
            UPDATE users SET last_heartbeat = NOW()
            WHERE id = :userId AND (
                is_active = 1 AND TIMESTAMPDIFF(SECOND, last_heartbeat, NOW()) < 10
            )
        )");
        query.bindValue(":userId", userId);

        if (query.exec()) {
            emit PulseResult(requestId, db::QueryStatus::Success);
            return;
        } else {
            qWarning() << "Pulse query failed" << ":" << query.lastError();
        }
    }

    emit PulseResult(requestId, db::QueryStatus::DbError);
    ReloadConnection();
}

void db::DBWorker::TryLogout(unsigned userId)
{
    {
        QSqlQuery query(localDB_);
        query.prepare("UPDATE history SET is_committed = 0 WHERE user_id = :uid");
        query.bindValue(":uid", userId);
        if (!query.exec()) {
            qWarning() << "Failed to mark local topups uncommitted:" << query.lastError();
        }
    }

    if (TryOpenRemote()) {
        QSqlQuery query(remoteDB_);
        query.prepare(R"(
            UPDATE users SET is_active = 0
            WHERE id = :userId AND (
                is_active = 1 AND TIMESTAMPDIFF(SECOND, last_heartbeat, NOW()) < 10
            )
        )");
        query.bindValue(":userId", userId);

        if (!query.exec()) {
            qWarning() << "Logout query failed" << ":" << query.lastError();
        } else {
            return;
        }
    }

    ReloadConnection();
}

void db::DBWorker::TryLogin(quint64 requestId, QString phone, QString passwd)
{
    if (TryOpenRemote()) {
        QSqlQuery query(remoteDB_);
        query.prepare("SELECT * FROM users WHERE phone = :phone AND password = :pass");
        query.bindValue(":phone", phone);
        query.bindValue(":pass", passwd);

        if (!query.exec()) {
            qWarning() << "TryLogin query failed" << ":" << query.lastError();
        } else {
            if (query.next()) {
                unsigned id = query.value("id").toUInt();
                QString phoneStr = query.value("phone").toString();
                QString passwdStr = query.value("password").toString();
                unsigned balance = query.value("balance").toUInt();
                db::UserData uData(id, phoneStr, passwdStr, balance);

                query.prepare(R"(
                    UPDATE users
                    SET is_active = 1, last_heartbeat = NOW()
                    WHERE id = :userId AND (
                        is_active = 0
                        OR TIMESTAMPDIFF(SECOND, last_heartbeat, NOW()) > 10
                    )
                )");
                query.bindValue(":userId", uData.userId);

                if (query.exec()) {
                    if (query.numRowsAffected() == 1) {
                        emit TryLoginResult(requestId, db::QueryStatus::Success, uData);
                    } else {
                        emit TryLoginResult(requestId, db::QueryStatus::Duplicate, std::nullopt);
                    }

                    return;
                } else {
                    qWarning() << "Login query failed" << ":" << query.lastError();
                }
            } else {
                emit TryLoginResult(requestId, QueryStatus::NotFound, std::nullopt);
                return;
            }
        }
    }

    emit TryLoginResult(requestId, db::QueryStatus::DbError, std::nullopt);
    ReloadConnection();
}

void db::DBWorker::AddUser(quint64 requestId, QString phone, QString passwd, unsigned initialBalance)
{
    if (TryOpenRemote()) {
        QSqlQuery query(remoteDB_);
        query.prepare("INSERT INTO users(phone, password, balance) VALUES (:phone, :passwd, :balance)");
        query.bindValue(":phone", phone);
        query.bindValue(":passwd", passwd);
        query.bindValue(":balance", initialBalance);

        if (query.exec()) {
            emit AddUserResult(requestId, QueryStatus::Success);
            return;
        } else {
            qWarning() << "AddUser query failed" << ":" << query.lastError();

            auto err = query.lastError();
            if (err.nativeErrorCode() == "1062") { // duplicate
                emit AddUserResult(requestId, QueryStatus::Duplicate);
                return;
            }
        }
    }

    emit AddUserResult(requestId, QueryStatus::DbError);
    ReloadConnection();
}

void db::DBWorker::GetUserHistory(quint64 requestId, unsigned userId)
{
    QVector<db::historyElem> result;

    if (TryOpenRemote()) {
        QSqlQuery query(remoteDB_);
        query.prepare("SELECT * FROM history WHERE user_id = :id AND is_committed = 1");
        query.bindValue(":id", userId);

        if (query.exec()) {
            while (query.next()) {
                db::historyElem elem;

                elem.id = query.value("id").toUInt();
                elem.userId = query.value("user_id").toUInt();
                elem.amount = query.value("amount").toInt();
                elem.createdAt = query.value("created_at").toDateTime();

                result.push_back(elem);
            }

            emit GetUserHistoryResult(requestId, QueryStatus::Success, result);
            return;
        } else {
            qWarning() << "GetUserHistory query failed" << ":" << query.lastError();
        }
    }

    emit GetUserHistoryResult(requestId, QueryStatus::DbError, result);
    ReloadConnection();
}

void db::DBWorker::AddToHistory(unsigned userId, int added)
{
    QSqlQuery query(localDB_);
    query.prepare("INSERT INTO history (user_id, amount, is_committed) VALUES (:user_id, :amount, 1)");
    query.bindValue(":user_id", userId);
    query.bindValue(":amount", added);
    if (!query.exec()) {
        qWarning() << "Failed to insert topup into local history:" << query.lastError();
    }
}

void db::DBWorker::SendLocalHistory()
{
    if (TryOpenRemote() && TryOpenLocal()) {
        QSqlQuery localQuery(localDB_);
        localQuery.prepare("SELECT user_id, amount, created_at FROM history WHERE is_committed = 0");
        if (localQuery.exec()) {
            QList<QVariantList> uncommittedRows;
            while (localQuery.next()) {
                QVariantList row;
                row << localQuery.value("user_id")
                    << localQuery.value("amount")
                    << localQuery.value("created_at");
                uncommittedRows.append(row);
            }

            QSqlQuery remoteQuery(remoteDB_);
            for (const QVariantList& row : uncommittedRows) {
                remoteQuery.prepare("INSERT INTO history (user_id, amount, created_at, is_committed) "
                                    "VALUES (:uid, :am, :created, 0)");
                remoteQuery.bindValue(":uid", row[0]);
                remoteQuery.bindValue(":am", row[1]);
                remoteQuery.bindValue(":created", row[2]);

                if (!remoteQuery.exec()) {
                    return;
                }
            }

            if (!uncommittedRows.isEmpty()) {
                QStringList ids;
                for (const auto& row : uncommittedRows) {
                    ids << row[0].toString();
                }

                localQuery.prepare("DELETE FROM history WHERE id IN (" + ids.join(",") + ")");
                if (!localQuery.exec()) {
                    return;
                }
            }
        }
    }
}
