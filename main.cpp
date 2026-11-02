#include <QGuiApplication>

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQuick/QQuickView>
#include <QtWebEngineQuick>

#include "engine/engine.h"
#include "sbp_pay/yoomoneyqrhandler.h"

int main(int argc, char* argv[])
{
    QCoreApplication::setAttribute(Qt::AA_UseSoftwareOpenGL);
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);

    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", "--disable-gpu-blacklist --enable-gpu-rasterization");
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    QtWebEngineQuick::initialize();
    QGuiApplication app(argc, argv);

    QString appdir = QGuiApplication::applicationDirPath();
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

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &engine_backend);
    engine.rootContext()->setContextProperty("applicationDirPath", appdir);
    engine.addImportPath(":/imports");

    // qApp->setOverrideCursor(QCursor(Qt::BlankCursor));
    app.setWindowIcon(QIcon(":/iconlogo"));

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app, [url](QObject* obj, const QUrl& objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.load(url);

    QObject* item = engine.rootObjects().at(0);
    QObject::connect(item, SIGNAL(qmlSetButtons(int)),
        &engine_backend, SLOT(cppSetButtons(int)));

    QObject::connect(item, SIGNAL(qmlClerButtonStateWallet()),
        &engine_backend, SLOT(cppClerButtonStateWallet()));

    engine_backend.initEvent();

    return app.exec();
}
