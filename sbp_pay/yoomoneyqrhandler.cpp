#include "yoomoneyqrhandler.h"
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUuid>

extern QString shop_id_str;

YooMoneyQRHandler::YooMoneyQRHandler(QObject* parent)
    : QObject(parent)
    , m_curlProcess(new QProcess(this))
    , m_statusTimer(new QTimer(this))
    , m_isProcessRunning(false)
{
    connect(m_curlProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
        this, &YooMoneyQRHandler::onCurlFinished);
    connect(m_statusTimer, &QTimer::timeout, this, &YooMoneyQRHandler::onStatusCheckTimeout);
}

YooMoneyQRHandler::~YooMoneyQRHandler()
{
    m_statusTimer->stop();
}

QString YooMoneyQRHandler::errorString() const
{
    return m_errorString;
}

QString YooMoneyQRHandler::confirmationUrl() const
{
    return m_confirmationUrl;
}

QStringList YooMoneyQRHandler::getCurlArguments(const QString& url, const QString& method, const QString& data)
{
    QString auth = shop_id_str;
    QString idempotenceKey = QUuid::createUuid().toString(QUuid::WithoutBraces);

    QStringList args;
    args << "-X" << method
         << url
         << "-u" << auth
         << "-H" << QString("Idempotence-Key: %1").arg(idempotenceKey)
         << "-H" << "Content-Type: application/json";

    if (!data.isEmpty()) {
        args << "-d" << data;
    }

    return args;
}

void YooMoneyQRHandler::startNextRequest()
{
    if (m_isProcessRunning) {
        return;
    }

    QStringList args;

    if (!m_highPriorityQueue.isEmpty()) {
        args = m_highPriorityQueue.dequeue();
        qDebug() << "Выполняется высокоприоритетный curl с аргументами:" << args;
    } else if (!m_requestQueue.isEmpty()) {
        args = m_requestQueue.dequeue();
        qDebug() << "Выполняется обычный curl с аргументами:" << args;
    } else {
        return;
    }

    m_isProcessRunning = true;
    m_curlProcess->start("curl", args);
}

void YooMoneyQRHandler::createPayment(const QString& amount, const QString& description)
{
    bool ok;
    double amountValue = amount.toDouble(&ok);

    if (!ok || amountValue < 1.0 || amountValue > 700000.0) {
        m_errorString = "Сумма должна быть от 1 до 700,000 RUB";
        emit errorOccurred(m_errorString);
        return;
    }

    QUrl url("https://api.yookassa.ru/v3/payments");

    QJsonObject json;
    QJsonObject amountObj;
    amountObj["value"] = QString::number(amountValue, 'f', 2);
    amountObj["currency"] = "RUB";
    json["amount"] = amountObj;

    QJsonObject paymentMethodData;
    paymentMethodData["type"] = "sbp";
    json["payment_method_data"] = paymentMethodData;

    QJsonObject receiptObj;
    QJsonArray itemsArray;
    QJsonObject itemObj;
    itemObj["description"] = QString::fromUtf8("Автомойка");
    itemObj["quantity"] = 1;
    QJsonObject itemAmountObj;
    itemAmountObj["value"] = QString::number(amountValue, 'f', 2);
    itemAmountObj["currency"] = "RUB";
    itemObj["amount"] = itemAmountObj;
    itemObj["vat_code"] = 1;
    itemObj["payment_mode"] = "full_prepayment";
    itemObj["payment_subject"] = "commodity";
    itemsArray.append(itemObj);
    receiptObj["items"] = itemsArray;

    QJsonObject customerObj;
    customerObj["email"] = "kibirone54@yandex.ru";
    receiptObj["customer"] = customerObj;

    json["receipt"] = receiptObj;

    QJsonObject confirmationObj;
    confirmationObj["type"] = "redirect";
    confirmationObj["return_url"] = "https://yoomoney.ru";
    json["confirmation"] = confirmationObj;

    json["capture"] = true;

    QJsonDocument doc(json);
    QString data = QString(doc.toJson(QJsonDocument::Compact)).replace("'", "\\'");

    QStringList args = getCurlArguments(url.toString(), "POST", data);
    m_highPriorityQueue.enqueue(args);
    startNextRequest();

    if (!m_statusTimer->isActive()) {
        m_statusTimer->start(1000);
    }
}

void YooMoneyQRHandler::onStatusCheckTimeout()
{
    for (auto it = m_paymentStatuses.constBegin(); it != m_paymentStatuses.constEnd(); ++it) {
        if (it.value() == "pending") {
            checkPaymentStatus(it.key());
        }
    }
}

void YooMoneyQRHandler::checkPaymentStatus(const QString& paymentId)
{
    if (paymentId.isEmpty()) {
        m_errorString = "ID платежа не указан";
        emit errorOccurred(m_errorString);
        return;
    }

    for (const auto& args : m_requestQueue) {
        if (args.contains("https://api.yookassa.ru/v3/payments/" + paymentId)) {
            qDebug() << "Запрос для paymentId" << paymentId << "уже в очереди";
            return;
        }
    }
    for (const auto& args : m_highPriorityQueue) {
        if (args.contains("https://api.yookassa.ru/v3/payments/" + paymentId)) {
            qDebug() << "Запрос для paymentId" << paymentId << "уже в высокоприоритетной очереди";
            return;
        }
    }

    QUrl url("https://api.yookassa.ru/v3/payments/" + paymentId);
    QStringList args = getCurlArguments(url.toString(), "GET");
    m_requestQueue.enqueue(args);
    startNextRequest();
}

void YooMoneyQRHandler::onCurlFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    m_isProcessRunning = false;

    if (exitStatus != QProcess::NormalExit || exitCode != 0) {
        m_errorString = m_curlProcess->errorString();
        qDebug() << "Ошибка curl: " << m_errorString;
        emit errorOccurred(m_errorString);
    } else {
        QByteArray response = m_curlProcess->readAllStandardOutput();
        qDebug() << "Ответ curl: " << response;
        parsePaymentResponse(response);
    }

    startNextRequest();
}

void YooMoneyQRHandler::clearQueueForPayment(const QString& paymentId)
{
    QQueue<QStringList> newQueue;
    while (!m_requestQueue.isEmpty()) {
        QStringList args = m_requestQueue.dequeue();
        if (!args.contains("https://api.yookassa.ru/v3/payments/" + paymentId)) {
            newQueue.enqueue(args);
        }
    }
    m_requestQueue = newQueue;
}

void YooMoneyQRHandler::parsePaymentResponse(const QByteArray& response)
{
    QJsonDocument doc = QJsonDocument::fromJson(response);

    if (doc.isNull()) {
        m_errorString = QStringLiteral("Некорректный JSON-ответ");
        emit errorOccurred(m_errorString);
        return;
    }

    QJsonObject obj = doc.object();
    QString status = obj["status"].toString();
    QString currentPaymentId = obj["id"].toString();

    bool wasPending = m_paymentStatuses.contains(currentPaymentId) && m_paymentStatuses[currentPaymentId] == "pending";

    if (obj.contains("id")) {
        QString paymentId = obj["id"].toString();

        if (!m_paymentStatuses.contains(paymentId) && status != "succeeded" && status != "canceled") {
            m_paymentStatuses[paymentId] = status;

            if (obj.contains("confirmation")) {
                m_confirmationUrl = obj["confirmation"].toObject()["confirmation_url"].toString();

                if (!m_confirmationUrl.isEmpty()) {
                    qDebug() << "Получен URL подтверждения для paymentId" << paymentId << ":" << m_confirmationUrl;
                    emit confirmationUrlReceived(paymentId, m_confirmationUrl);
                } else {
                    m_errorString = QStringLiteral("В ответе отсутствует URL подтверждения");
                    emit errorOccurred(m_errorString);
                    return;
                }
            }
        }
    } else {
        m_errorString = QStringLiteral("В ответе отсутствует ID платежа");
        emit errorOccurred(m_errorString);
        return;
    }

    if (status == "succeeded" || status == "canceled") {
        if (wasPending) {
            if (status == "succeeded") {
                qDebug() << "Внесенная сумма: " << std::stoi(obj["amount"].toObject()["value"].toString().toStdString());
                emit successPayment(std::stoi(obj["amount"].toObject()["value"].toString().toStdString()));
            }
        }

        clearQueueForPayment(currentPaymentId);
        m_paymentStatuses.remove(currentPaymentId);
        qDebug() << "Платеж" << currentPaymentId << "завершен со статусом" << status;
    }

    bool hasPending = false;
    for (auto it = m_paymentStatuses.constBegin(); it != m_paymentStatuses.constEnd(); ++it) {
        if (it.value() == "pending") {
            hasPending = true;
            break;
        }
    }

    if (!hasPending) {
        m_statusTimer->stop();
        qDebug() << "Нет платежей в статусе pending, таймер остановлен";
    }
}
