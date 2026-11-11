#include "updater.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTextStream>
#include <QTimer>

#ifndef APP_VERSION
#define APP_VERSION "1.1.0"
#endif

Updater::Updater(QString appdir, QObject* parent)
    : QObject(parent)
    , appdir(std::move(appdir))
    , currentVersion(APP_VERSION)
{
    nam = new QNetworkAccessManager(this);

    // настройки читаем сами, чтобы не зависеть от Engine
    QFile cfgFile(this->appdir + "/config/ui.json");
    if (cfgFile.open(QIODevice::ReadOnly)) {
        QJsonObject cfg = QJsonDocument::fromJson(cfgFile.readAll()).object();
        cfgFile.close();

        updateUrl = cfg.value("updateUrl").toString();
        updateToken = cfg.value("updateToken").toString();
    }

    checkTimer = new QTimer(this);
    checkTimer->setInterval(6 * 60 * 60 * 1000); // 6 часов
    connect(checkTimer, &QTimer::timeout, this, &Updater::checkForUpdates);

    if (!updateUrl.isEmpty()) {
        QTimer::singleShot(45 * 1000, this, &Updater::checkForUpdates); // первый запуск через 45 c
        checkTimer->start();
    }
}

QString Updater::statusText() const
{
    return m_statusText;
}

void Updater::setStatusText(const QString& text)
{
    if (m_statusText == text)
        return;

    m_statusText = text;
    emit statusTextChanged();
}

int Updater::versionPart(const QString& v, int idx)
{
    QStringList parts = v.split('.');
    bool ok = false;
    int val = (idx < parts.size()) ? parts[idx].toInt(&ok) : 0;
    return ok ? val : 0;
}

bool Updater::isNewerVersion(const QString& remote, const QString& current) const
{
    QString r = remote;
    QString c = current;
    if (r.startsWith('v'))
        r.remove(0, 1);
    if (c.startsWith('v'))
        c.remove(0, 1);

    for (int i = 0; i < 4; ++i) {
        int rp = versionPart(r, i);
        int cp = versionPart(c, i);
        if (rp != cp)
            return rp > cp;
    }

    return false;
}

void Updater::checkForUpdates()
{
    if (busy || updateUrl.isEmpty())
        return;

    busy = true;

    QNetworkRequest req{ QUrl(updateUrl) };
    req.setRawHeader("User-Agent", "IPS4MCO-Updater");
    req.setRawHeader("Accept", "application/vnd.github+json");
    if (!updateToken.isEmpty())
        req.setRawHeader("Authorization", "Bearer " + updateToken.toUtf8());

    versionReply = nam->get(req);
    connect(versionReply, &QNetworkReply::finished, this, &Updater::onVersionCheckFinished);
}

void Updater::onVersionCheckFinished()
{
    if (!versionReply)
        return;

    QNetworkReply::NetworkError err = versionReply->error();
    QByteArray data = versionReply->readAll();
    versionReply->deleteLater();
    versionReply = nullptr;
    busy = false;

    if (err != QNetworkReply::NoError) {
        qWarning() << "Update check failed:" << err;
        setStatusText("");
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        setStatusText("");
        return;
    }

    QJsonObject obj = doc.object();
    QString tagName = obj.value("tag_name").toString();
    if (tagName.isEmpty() || !isNewerVersion(tagName, currentVersion))
        return;

    // ищем zip-ассет
    QJsonArray assets = obj.value("assets").toArray();
    for (const QJsonValue& v : assets) {
        QJsonObject a = v.toObject();
        QString name = a.value("name").toString();
        if (name.endsWith(".zip", Qt::CaseInsensitive)) {
            assetUrl = a.value("browser_download_url").toString();
            assetVersion = tagName;
            break;
        }
    }

    if (assetUrl.isEmpty())
        return;

    setStatusText(QString::fromUtf8("Доступно обновление %1. Скачивание...").arg(tagName));
    startDownload(assetUrl);
}

void Updater::startDownload(const QString& url)
{
    busy = true;

    QDir().mkpath(appdir + "/update");

    QString zipPath = appdir + "/update/update.zip";
    if (downloadFile.isOpen())
        downloadFile.close();
    downloadFile.setFileName(zipPath);
    if (!downloadFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        setStatusText(QString::fromUtf8("Ошибка обновления: не удалось создать файл."));
        busy = false;
        return;
    }

    QNetworkRequest req{ QUrl(url) };
    req.setRawHeader("User-Agent", "IPS4MCO-Updater");
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    if (!updateToken.isEmpty())
        req.setRawHeader("Authorization", "Bearer " + updateToken.toUtf8());

    downloadReply = nam->get(req);
    connect(downloadReply, &QNetworkReply::downloadProgress, this, &Updater::onDownloadProgress);
    connect(downloadReply, &QNetworkReply::finished, this, &Updater::onDownloadFinished);
}

void Updater::onDownloadProgress(qint64 received, qint64 total)
{
    if (total > 0) {
        int percent = static_cast<int>(received * 100 / total);
        setStatusText(QString::fromUtf8("Обновление: %1%").arg(percent));
    }
}

void Updater::onDownloadFinished()
{
    if (!downloadReply)
        return;

    bool ok = (downloadReply->error() == QNetworkReply::NoError);
    QByteArray tail = downloadReply->readAll();
    downloadFile.write(tail);
    downloadFile.close();

    downloadReply->deleteLater();
    downloadReply = nullptr;
    busy = false;

    if (!ok) {
        setStatusText(QString::fromUtf8("Ошибка скачивания обновления."));
        downloadFile.remove();
        return;
    }

    setStatusText(QString::fromUtf8("Обновление скачано. Установка..."));
    applyUpdate();
}

void Updater::applyUpdate()
{
#ifdef Q_OS_WIN
    const QString zipPath = appdir + "/update/update.zip";
    const QString extractDir = appdir + "/update/app";
    QDir().mkpath(extractDir);

    // распаковка через PowerShell (встроен в Windows 10/11)
    QProcess ps;
    ps.setProcessChannelMode(QProcess::MergedChannels);
    ps.start("powershell.exe",
        { "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
            QString("Expand-Archive -Force -LiteralPath '%1' -DestinationPath '%2'")
                .arg(QDir::toNativeSeparators(zipPath),
                     QDir::toNativeSeparators(extractDir)) });

    if (!ps.waitForFinished(180000) || ps.exitCode() != 0) {
        setStatusText(QString::fromUtf8("Ошибка распаковки обновления."));
        qWarning() << "Expand-Archive failed:" << ps.readAll();
        return;
    }

    // если архив содержит вложенный zip (артефакт CI) — распаковываем и его
    QDir extracted(extractDir);
    QStringList innerZips = extracted.entryList({ "*.zip" }, QDir::Files);
    for (const QString& z : innerZips) {
        QProcess ps2;
        ps2.setProcessChannelMode(QProcess::MergedChannels);
        ps2.start("powershell.exe",
            { "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
                QString("Expand-Archive -Force -LiteralPath '%1' -DestinationPath '%2'")
                    .arg(QDir::toNativeSeparators(extractDir + "/" + z),
                         QDir::toNativeSeparators(extractDir)) });
        ps2.waitForFinished(180000);
        QFile(extractDir + "/" + z).remove();
    }

    // пакет должен содержать IPS4MCO.exe (в корне или в подпапке)
    QString appRoot = extractDir;
    if (!QFile::exists(appRoot + "/IPS4MCO.exe")) {
        for (const QFileInfo& dir : extracted.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            if (QFile::exists(dir.absoluteFilePath() + "/IPS4MCO.exe")) {
                appRoot = dir.absoluteFilePath();
                break;
            }
        }
    }

    if (!QFile::exists(appRoot + "/IPS4MCO.exe")) {
        setStatusText(QString::fromUtf8("Ошибка обновления: IPS4MCO.exe не найден в пакете."));
        return;
    }

    // bat-скрипт, который подменит exe после закрытия приложения
    const QString batPath = appdir + "/apply_update.bat";
    QFile bat(batPath);
    if (!bat.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        setStatusText(QString::fromUtf8("Ошибка обновления: не удалось создать скрипт."));
        return;
    }

    const QString batContent = QString(
        "@echo off\r\n"
        "timeout /t 3 /nobreak >nul\r\n"
        "if exist \"%1\" del /F /Q \"%1\"\r\n"
        "move /Y \"%2\" \"%3\"\r\n"
        "xcopy /E /Y /I \"%4\" \"%5\"\r\n"
        "rmdir /S /Q \"%6\"\r\n"
        "start \"\" \"%7\"\r\n")
        .arg(QDir::toNativeSeparators(appdir + "/IPS4MCO.exe.bak"),
             QDir::toNativeSeparators(appdir + "/IPS4MCO.exe"),
             QDir::toNativeSeparators(appdir + "/IPS4MCO.exe.bak"),
             QDir::toNativeSeparators(appRoot + "\\*"),
             QDir::toNativeSeparators(appdir),
             QDir::toNativeSeparators(appdir + "/update"),
             QDir::toNativeSeparators(appdir + "/IPS4MCO.exe"));

    bat.write(batContent.toLocal8Bit());
    bat.close();

    setStatusText(QString::fromUtf8("Перезапуск после обновления..."));

    QProcess::startDetached("cmd.exe", { "/c", batPath }, appdir);
    emit restartRequested();
#else
    setStatusText("");
#endif
}
