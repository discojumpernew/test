#ifndef YOOMONEYQRHANDLER_H
#define YOOMONEYQRHANDLER_H

#include <QImage>
#include <QMap>
#include <QNetworkAccessManager>
#include <QObject>
#include <QProcess>
#include <QQueue>
#include <QTimer>

class YooMoneyQRHandler : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorOccurred)
    Q_PROPERTY(QString confirmationUrl READ confirmationUrl NOTIFY confirmationUrlReceived)

public:
    explicit YooMoneyQRHandler(QObject* parent = nullptr);
    ~YooMoneyQRHandler();

    QString errorString() const;
    QString confirmationUrl() const;

    Q_INVOKABLE void createPayment(const QString& amount, const QString& description);
    Q_INVOKABLE void checkPaymentStatus(const QString& paymentId);
    Q_INVOKABLE void stopStatusTimer() { m_statusTimer->stop(); }

signals:
    void errorOccurred(const QString& error);
    void confirmationUrlReceived(const QString& paymentId, const QString& url);
    void successPayment(int value);

private slots:
    void onCurlFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onStatusCheckTimeout();

private:
    QProcess* m_curlProcess;
    QTimer* m_statusTimer;
    QString m_errorString;
    QString m_confirmationUrl;
    QMap<QString, QString> m_paymentStatuses;
    bool m_isProcessRunning;
    QQueue<QStringList> m_requestQueue;
    QQueue<QStringList> m_highPriorityQueue;

    void parsePaymentResponse(const QByteArray& response);
    QStringList getCurlArguments(const QString& url, const QString& method, const QString& data = QString());
    void startNextRequest();
    void clearQueueForPayment(const QString& paymentId);
};

#endif // YOOMONEYQRHANDLER_H
