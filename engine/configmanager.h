#ifndef CONFIGMANAGER_H
#define CONFIGMANAGER_H

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QObject>
#include <QTextStream>

#include "errors.h"

namespace en {
class ConfigManager : public QObject {
    Q_OBJECT
public:
    explicit ConfigManager(QObject* parent = nullptr);

    struct s_modbus_config {
        QString PortName;
        int BaudRate;
        int DataBits;
        int Parity;
        int StopBits;
        int ServerAddress;
        int Timeout; // seconds
    };

    static s_modbus_config readModbusConfig(QString file_path, int* error);
    static QJsonObject readUIConfig(QString file_path, int* error);
    static QJsonObject readDBConfig(QString file_path, int* error);

    static int checkModbusConfig(QJsonObject config);
    static int checkUIConfig(QJsonObject config);
    static int checkDBConfig(QJsonObject config);

private:
};
}

#endif // CONFIGMANAGER_H
