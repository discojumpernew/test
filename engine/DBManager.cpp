#include "DBManager.h"

QString db::host;
QString db::dbName;
QString db::user;
QString db::password;

QString db::DBManager::HashPassword(const QString& password)
{
    QByteArray hash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256);
    return hash.toHex();
}

db::DBManager::DBManager(QObject* parent)
    : QObject(parent)
{
    worker_ = new DBWorker;
    worker_->moveToThread(&workerThread_);

    connect(worker_, &DBWorker::TryLoginResult, this, &DBManager::TryLoginResult, Qt::QueuedConnection);
    connect(worker_, &DBWorker::AddUserResult, this, &DBManager::AddUserResult, Qt::QueuedConnection);
    connect(worker_, &DBWorker::PulseResult, this, &DBManager::PulseResult, Qt::QueuedConnection);
    connect(worker_, &DBWorker::GetUserHistoryResult, this, &DBManager::GetUserHistoryResult, Qt::QueuedConnection);

    connect(&workerThread_, &QThread::started, worker_, &DBWorker::processLoop);
    workerThread_.start();
}

db::DBManager::~DBManager()
{
    worker_->running.store(false);
    // пустую задачу, чтобы разбудить worker_
    worker_->queue.push(Task {});
    workerThread_.quit();
    workerThread_.wait();
}

void db::DBManager::TryLogin(quint64 requestId, QString phone, QString passwd)
{
    Task task;
    task.requestId = requestId;
    QString pass = std::move(DBManager::HashPassword(passwd));
    task.action = [this, requestId, phone, pass] {
        worker_->TryLogin(requestId, phone, pass);
    };

    worker_->queue.push(task);
}

void db::DBManager::TryLogout(quint64 requestId, unsigned userId)
{
    Task task;
    task.requestId = requestId;
    task.action = [this, userId] {
        worker_->TryLogout(userId);
    };

    worker_->queue.push(task);
}

void db::DBManager::AddToHistory(quint64 requestId, unsigned userId, int added)
{
    Task task;
    task.requestId = requestId;
    task.action = [this, userId, added] {
        worker_->AddToHistory(userId, added);
    };

    worker_->queue.push(task);
}

void db::DBManager::AddUser(quint64 requestId, QString phone, QString passwd, unsigned bonus)
{
    Task task;
    task.requestId = requestId;
    task.action = [this, requestId, phone, passwd, bonus] {
        worker_->AddUser(requestId, phone, passwd, bonus);
    };

    worker_->queue.push(task);
}

void db::DBManager::Pulse(quint64 requestId, unsigned userId)
{
    Task task;
    task.requestId = requestId;
    task.action = [this, requestId, userId] {
        worker_->Pulse(requestId, userId);
    };

    worker_->queue.push(task);
}

void db::DBManager::GetUserHistory(quint64 requestId, unsigned userId)
{
    Task task;
    task.requestId = requestId;
    task.action = [this, requestId, userId] {
        worker_->GetUserHistory(requestId, userId);
    };

    worker_->queue.push(task);
}

void db::DBManager::WriteNewBalance(quint64 requestId, unsigned userId, unsigned newBalance)
{
    Task task;
    task.requestId = requestId;
    task.action = [this, userId, newBalance] {
        worker_->WriteNewBalance(userId, newBalance);
    };

    worker_->queue.push(task);
}

void db::DBManager::CancelTask(quint64 requestId)
{
    worker_->queue.removeIf([=](const Task& t) { return t.requestId == requestId; });
}

void db::DBManager::CancelAllInSet(QSet<quint64> idSet)
{
    worker_->queue.removeIf([=](const Task& t) { return idSet.find(t.requestId) != idSet.end(); });
}
