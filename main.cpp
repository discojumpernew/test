#include <QSharedMemory>

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QMutex>
#include <QTextStream>

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QtQuick/QQuickView>
#include <QtWebEngineQuick>

#include <cstdio>

#include "engine/engine.h"
#include "sbp_pay/yoomoneyqrhandler.h"
#include "engine/updater.h"

#ifdef Q_OS_WIN
#include <windows.h>
#endif

static QString logFilePath;

// Пишем всё, что приложение сообщает (включая ошибки QML), в startup.log рядом с exe.
// Без этого на терминале диагностировать "не запускается" невозможно.
static void fileMessageHandler(QtMsgType type, const QMessageLogContext& ctx, const QString& msg)
{
    static QMutex mutex;
    QMutexLocker locker(&mutex);

    const char* level = "D";
    switch (type) {
    case QtInfoMsg: level = "I"; break;
    case QtWarningMsg: level = "W"; break;
    case QtCriticalMsg: level = "C"; break;
    case QtFatalMsg: level = "F"; break;
    default: break;
    }

    QString line = QString("%1 [%2] %3")
                       .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz"))
                       .arg(level)
                       .arg(msg);
    if (ctx.file)
        line += QString(" (%1:%2)").arg(ctx.file).arg(ctx.line);

    if (!logFilePath.isEmpty()) {
        QFile f(logFilePath);
        if (f.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
            QTextStream ts(&f);
            ts << line << "\n";
            ts.flush();
            f.flush();
        }
    }
#ifdef Q_OS_WIN
    OutputDebugStringW(reinterpret_cast<const wchar_t*>(line.utf16()));
#endif
    fprintf(stderr, "%s\n", line.toLocal8Bit().constData());
}

int main(int argc, char* argv[])
{
    QCoreApplication::setAttribute(Qt::AA_UseSoftwareOpenGL);
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);

    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", "--disable-gpu-blacklist --enable-gpu-rasterization");
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    QtWebEngineQuick::initialize();
    QGuiApplication app(argc, argv);

    // Лог старта: пишем в startup.log рядом с exe (обрезаем при каждом запуске)
    logFilePath = QGuiApplication::applicationDirPath() + "/startup.log";
    {
        QFile f(logFilePath);
        if (f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
            QTextStream ts(&f);
            ts << "=== IPS4MCO start " << QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss")
               << " | Qt " << QT_VERSION_STR << " ===\n";
            ts.flush();
        }
    }
    qInstallMessageHandler(fileMessageHandler);
    qInfo() << "appdir:" << QGuiApplication::applicationDirPath();
    qInfo() << "qt:" << QT_VERSION_STR << "build:" << __DATE__ << __TIME__;

    // Запрещаем запуск второго экземпляра приложения
    QSharedMemory singleInstance("IPS4MCO_Terminal_SingleInstance");
    if (!singleInstance.create(1)) {
        qWarning() << "IPS4MCO is already running. Exiting second instance.";
        return 0;
    }

    QString appdir = QGuiApplication::applicationDirPath();

    // MySQL 8 по умолчанию использует caching_sha2_password. В MariaDB Connector/C
    // это отдельный плагин (caching_sha2_password.dll), а не встроенный алгоритм,
    // поэтому явно указываем коннектору папку с плагинами рядом с exe.
    {
        const QString pluginDir = appdir + "/mariadb-plugin";
        qputenv("MARIADB_PLUGIN_DIR", QDir::toNativeSeparators(pluginDir).toLocal8Bit());
        qInfo() << "MARIADB_PLUGIN_DIR:" << pluginDir
                << "exists:" << QDir(pluginDir).exists();
    }

    {
        int error = Errors::No;
        QJsonObject db_config = en::ConfigManager::readDBConfig(appdir + "/config/db.json", &error);
        if (!error) {
            db::host = db_config.value("hostname").toString();
            db::dbName = db_config.value("db_name").toString();
            db::user = db_config.value("user").toString();
            db::password = db_config.value("passwd").toString();
        }
    }

    Engine engine_backend(appdir);
    qmlRegisterType<YooMoneyQRHandler>("YooMoney", 1, 0, "YooMoneyQRHandler");

    Updater updater(appdir);
    QObject::connect(&updater, &Updater::restartRequested, &app, &QCoreApplication::quit);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &engine_backend);
    engine.rootContext()->setContextProperty("updater", &updater);
    engine.rootContext()->setContextProperty("applicationDirPath", appdir);
    engine.addImportPath(":/imports");

    // qApp->setOverrideCursor(QCursor(Qt::BlankCursor));
    app.setWindowIcon(QIcon(":/iconlogo"));

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app, [url](QObject* obj, const QUrl& objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "QML root object was not created:" << objUrl.toString();
            QCoreApplication::exit(-1);
        } }, Qt::QueuedConnection);

    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &app,
        [](const QList<QQmlError>& warnings) {
            for (const QQmlError& w : warnings)
                qWarning() << "QML:" << w.toString();
        });

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load qrc:/main.qml — see messages above. Exiting.";
        return -1;
    }

    QObject* item = engine.rootObjects().first();
    QObject::connect(item, SIGNAL(qmlSetButtons(int)),
        &engine_backend, SLOT(cppSetButtons(int)));

    QObject::connect(item, SIGNAL(qmlClerButtonStateWallet()),
        &engine_backend, SLOT(cppClerButtonStateWallet()));

    engine_backend.initEvent();

    return app.exec();
}
