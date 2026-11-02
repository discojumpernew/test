#include "modbuscontroller.h"

ModbusController::ModbusController(QObject* parent)
    : QObject(parent)
{
    controlMsgTimer = new QTimer();
    error.controlmsg = Errors::MCTimeout;
    error.internal = Errors::No;
    QObject::connect(controlMsgTimer, &QTimer::timeout, this, &ModbusController::controlMsgTimerSlot);
}

ModbusController::~ModbusController()
{
    if (modbusDevice->state() == QModbusDevice::ConnectedState)
        modbusDevice->disconnect();

    if (modbusDevice)
        modbusDevice->disconnectDevice();

    delete modbusDevice;
}

int ModbusController::create()
{
    error.internal = Errors::No;
    if (modbusDevice) {
        modbusDevice->disconnect();
        delete modbusDevice;
        modbusDevice = nullptr;
    }
    modbusDevice = new QModbusRtuSerialSlave(this);

    if (modbusDevice) {
        QModbusDataUnitMap reg;
        reg.insert(QModbusDataUnit::HoldingRegisters, { QModbusDataUnit::HoldingRegisters, 0, 200 });

        modbusDevice->setMap(reg);
        QObject::connect(modbusDevice, &QModbusServer::dataWritten, this, &ModbusController::DebugDataWriten);
    } else {
        error.internal = Errors::MCCreateDevice;
    }

    return error.internal;
}

void ModbusController::DebugDataWriten(QModbusDataUnit::RegisterType table, int address, int size)
{
    QString sdata = "";
    quint16 data;
    for (int i {}; i < size; ++i) {
        modbusDevice->data(table, address + i, &data);
        sdata += QString::number(data) + ", ";
    }
    qDebug() << "DEBUG: Data writed on start addr: " << address << "; size: " << size << "; data: " + sdata;
}

int ModbusController::connect()
{
    error.internal = Errors::No;
    if (modbusDevice->state() == QModbusDevice::UnconnectedState && modbusDevice) {

        modbusDevice->setConnectionParameter(QModbusDevice::SerialPortNameParameter, config.PortName);
        modbusDevice->setConnectionParameter(QModbusDevice::SerialParityParameter, config.Parity);
        modbusDevice->setConnectionParameter(QModbusDevice::SerialBaudRateParameter, config.BaudRate);
        modbusDevice->setConnectionParameter(QModbusDevice::SerialDataBitsParameter, config.DataBits);
        modbusDevice->setConnectionParameter(QModbusDevice::SerialStopBitsParameter, config.StopBits);
        modbusDevice->setServerAddress(config.ServerAddress);

        if (!modbusDevice->connectDevice()) {
            error.qt = modbusDevice->error();
            error.internal = Errors::MCConnect;
        } else {
            controlMsgTimer->start();
        }
    } else {
        error.internal = Errors::MCAlreadyConnected;
    }

    return error.internal;
}

int ModbusController::connect(QString Port, int Parity, int BaudRate, int DataBits, int StopBits, int ServerAddress, int Timeout)
{
    config.PortName = Port;
    config.Parity = Parity;
    config.BaudRate = BaudRate;
    config.DataBits = DataBits;
    config.StopBits = StopBits;
    config.ServerAddress = ServerAddress;
    config.Timeout = Timeout;
    controlMsgTimer->setInterval(Timeout);
    return connect();
}

int ModbusController::disconnect()
{
    error.internal = Errors::No;
    controlMsgTimer->stop();

    if (modbusDevice->state() == QModbusDevice::ConnectedState) {
        if (!modbusDevice->disconnect()) {
            error.qt = modbusDevice->error();
            error.internal = Errors::MCDisconnect;
        }
    }

    return error.internal;
}

bool ModbusController::isConnected()
{
    return modbusDevice->state() == QModbusDevice::ConnectedState;
}

int ModbusController::getError()
{
    return error.internal;
}

int ModbusController::writeNewBalance(quint16 value)
{
    error.internal = Errors::No;
    if (modbusDevice->state() == QModbusDevice::ConnectedState) {
        modbusDevice->setData(QModbusDataUnit::HoldingRegisters, 101, value);
    } else {
        error.internal = Errors::MCConnectionLost;
    }

    return error.internal;
}

int ModbusController::writeButtons(quint16 buttons)
{
    error.internal = Errors::No;
    if (modbusDevice->state() == QModbusDevice::ConnectedState) {
        modbusDevice->setData(QModbusDataUnit::HoldingRegisters, REG_CMD_FPANEL, buttons);
    } else {
        error.internal = Errors::MCConnectionLost;
    }

    return error.internal;
}

int ModbusController::clearButtonState(int reg, int btn_mask)
{
    error.internal = Errors::No;
    quint16 regdata;

    if (modbusDevice->state() == QModbusDevice::ConnectedState) {
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, reg, &regdata);
        modbusDevice->setData(QModbusDataUnit::HoldingRegisters, reg, regdata & !btn_mask);
    } else {
        error.internal = Errors::MCConnectionLost;
    }

    return error.internal;
}

ModbusController::s_session ModbusController::readInSession()
{
    error.internal = Errors::No;
    s_session session;
    quint16 raw_status1;
    quint16 raw_status2;
    quint16 time;
    quint16 pause_time;
    quint16 balance;

    if (modbusDevice->state() == QModbusDevice::ConnectedState) {
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_CMD1_TPANEL, &raw_status1);
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_CMD2_TPANEL, &raw_status2);
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_TIME, &time);
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_BALANCE, &balance);
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_PAUSE_TIME, &pause_time);

        session.buttons = (raw_status1 & 0x80FF);
        session.ispause_free = (raw_status2 & 0x4);

        session.balance = balance;
        session.minute = time >> 8;
        session.seconds = time & 0x00FF;

        session.pause_minute = pause_time >> 8;
        session.pause_seconds = pause_time & 0x00FF;
    } else {
        error.internal = Errors::MCConnectionLost;
    }

    return session;
}

void ModbusController::controlMsgTimerSlot()
{
    readControlMsg();
}

// read "Командное слово от ПЛК"(1), "Слово состояния системы от ПЛК"(2)
ModbusController::s_status ModbusController::readStatus()
{
    error.internal = Errors::No;
    quint16 raw_status1 = 0;
    quint16 raw_status2 = 0;
    quint16 balance = 0;
    quint16 time = 0;
    // quint16 pause_time = 0;
    quint16 err = 0;
    quint16 bank_dep = 0;
    s_status status;
    status.raw = 0;
    status.pingerror = error.controlmsg;
    status.bank = false;
    QModbusDevice::State ms = modbusDevice->state();

    if (ms == QModbusDevice::ConnectedState) {
        if (error.controlmsg) {
            controlMsgTimer->start();
            error.internal = 0;
            status.raw = status.raw | ((error.internal != 0) << 31);
            status.pingerror = (error.internal != 0);
            if (error.internal)
                return status;
        }

        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_CMD1_TPANEL, &raw_status1);
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_CMD2_TPANEL, &raw_status2);
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_BALANCE, &balance);
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_TIME, &time);
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_ERROR_CODE, &err);
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_BANK_DEPOSIT, &bank_dep);

        status.session = time != 0;
        status.empty = ((raw_status1 == 0) && (raw_status2 == 0) && (time == 0));
        status.raw = status.raw | (raw_status1 >> 8) | ((raw_status2 & (~(0x2))) << 8);
        status.raw = status.raw | ((time != 0) << 30);
        status.raw = status.raw | ((err != 0) << 29);
        status.raw = status.raw | ((bank_dep != 0) << 28);
        status.bank = bank_dep != 0;

        if (err) {
            error.internal = Errors::MCPLC + err;
        }

        if (!status.empty) {
            if ((raw_status1 & 0x100) || err)
                error.internal = Errors::MCPLC + err;

            // status.session = status.session | ((raw_status1 & 0x600) >> 8);
            status.pause_free = (raw_status2 & 0x4);
        }
    } else {
        error.internal = Errors::MCConnectionLost;
    }

    return status;
}

int ModbusController::readControlMsg()
{
    error.controlmsg = Errors::No;
    quint16 msg = 0;
    if (modbusDevice->state() == QModbusDevice::ConnectedState) {
        modbusDevice->data(QModbusDataUnit::HoldingRegisters, REG_PING, &msg);
        if (msg) {
            qDebug() << "readControlMsg: Ok";
            modbusDevice->setData(QModbusDataUnit::HoldingRegisters, REG_PING, 0);
        } else {
            qDebug() << "readControlMsg: MCTimeout";
            error.controlmsg = Errors::MCTimeout;
        }
    } else {
        qDebug() << "readControlMsg: MCConnectionLost";
        error.controlmsg = Errors::MCConnectionLost;
    }
    return error.controlmsg;
}
