#ifndef UPDATER_H
#define UPDATER_H

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QProcess>
#include <QTimer>

// Обновление по воздуху (OTA):
// 1. Проверяет GitHub Releases последней версии (config/ui.json -> updateUrl/updateToken).
// 2. Скачивает zip-пакет обновления.
// 3. Распаковывает и перезапускает приложение через apply_update.bat.
class Updater : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)

public:
    explicit Updater(QString appdir, QObject* parent = nullptr);

    QString statusText() const;

    Q_INVOKABLE void checkForUpdates();

signals:
    void statusTextChanged();
    void restartRequested();

private slots:
    void onVersionCheckFinished();
    void onDownloadProgress(qint64 received, qint64 total);
    void onDownloadFinished();

private:
    void setStatusText(const QString& text);
    void startDownload(const QString& url);
    bool isNewerVersion(const QString& remote, const QString& current) const;
    void applyUpdate();
    static int versionPart(const QString& v, int idx);

    QString appdir;
    QString updateUrl;
    QString updateToken;
    QString currentVersion;
    QString m_statusText;

    QNetworkAccessManager* nam = nullptr;
    QNetworkReply* versionReply = nullptr;
    QNetworkReply* downloadReply = nullptr;
    QFile downloadFile;
    QString assetUrl;
    QString assetVersion;

    QTimer* checkTimer;
    bool busy = false;
};

#endif // UPDATER_H
