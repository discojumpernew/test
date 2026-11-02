QT += qml quick serialport serialbus multimedia multimediawidgets sql virtualkeyboard core webview webenginequick

CONFIG += c++17

RC_ICONS = icon.ico

INCLUDEPATH += config_manager

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    controller/modbuscontroller.cpp \
    engine/DBManager.cpp \
    engine/DBWorker.cpp \
    engine/configmanager.cpp \
    engine/engine.cpp \
    main.cpp \
    sbp_pay/yoomoneyqrhandler.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH = $$PWD/imports

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    controller/modbuscontroller.h \
    engine/DBManager.h \
    engine/DBWorker.h \
    engine/MPMCBlockingQueue.h \
    engine/configmanager.h \
    engine/engine.h \
    errors.h \
    sbp_pay/yoomoneyqrhandler.h

DISTFILES += \
    imports/IPS4MCO/Constants.qml \
    imports/IPS4MCO/qmldir \
    main.qml \
    qml/BackgroundCust.qml \
    qml/BackgroundCustForm.ui.qml \
    qml/CashlessPayment.qml \
    qml/CashlessPaymentButtons.qml \
    qml/CashlessPaymentButtonsForm.ui.qml \
    qml/CashlessPaymentForm.ui.qml \
    qml/CashlessPaymentStatus.qml \
    qml/CashlessPaymentStatusForm.ui.qml \
    qml/Collection.qml \
    qml/CollectionForm.ui.qml \
    qml/Error.qml \
    qml/ErrorForm.ui.qml \
    qml/ErrorStatic.qml \
    qml/ErrorStaticForm.ui.qml \
    qml/Footer.qml \
    qml/FooterForm.ui.qml \
    qml/Header.qml \
    qml/HeaderForm.ui.qml \
    qml/Initialization.qml \
    qml/InitializationForm.ui.qml \
    qml/PauseButton.qml \
    qml/PauseButtonForm.ui.qml \
    qml/ProgButton.qml \
    qml/ProgButtonForm.ui.qml \
    qml/QR.qml \
    qml/QRForm.ui.qml \
    qml/QRGenerating.ui.qml \
    qml/Session.qml \
    qml/SessionForm.ui.qml \
    qml/Waiting.qml \
    qml/WaitingForm.ui.qml \
    qml/single/CardPage.qml \
    qml/single/CashPage.qml \
    qml/single/CustomKeyboard.qml \
    qml/single/Error.qml \
    qml/single/ErrorForm.ui.qml \
    qml/single/HistoryPage.qml \
    qml/single/Initialization.qml \
    qml/single/InitializationForm.ui.qml \
    qml/single/InstructionPage.qml \
    qml/single/LoaderDialog.qml \
    qml/single/LoginPage.qml \
    qml/single/PaymentSelection.qml \
    qml/single/PriceBox.qml \
    qml/single/PriceList.qml \
    qml/single/ProgramButton.qml \
    qml/single/ProgramButtonForm.ui.qml \
    qml/single/RegisterPage.qml \
    qml/single/SbpPage.qml \
    qml/single/Session.qml \
    qml/single/SessionForm.ui.qml \
    qml/single/Theme.qml

