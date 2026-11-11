import QtQuick 2.4
import QtQuick.Controls 2.5
import QtQuick.Shapes 1.12
//import QtQuick.Dialogs 1.2
import QtQuick.Dialogs
import IPS4MCO 1.0
import "qml/single"

ApplicationWindow {
    id: window
    visible: true
    title: qsTr("IPS4MCO")
    flags: Qt.Window | Qt.WindowTitleHint | Qt.CustomizeWindowHint
           | Qt.WindowCloseButtonHint | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint

    width: Constants.width
    height: Constants.height

    property bool darkTheme: true

    signal qmlSetButtons(int buttons)
    signal qmlClerButtonStateWallet

    property bool isErrorColorCFG: false

    Rectangle {
        id: modalOverlay
        anchors.fill: parent
        color: "black"
        opacity: 0.4
        visible: loader.visible
        z: 999

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: {
                /* блокируем клики */
            }
        }
    }

    function changePage(page) {
        Qt.inputMethod.hide()
        var visible_page = [false, false, false, false, false, false, false, false, false, false, false, false, false, false]
        visible_page[page] = true

        p_initialization.visible = visible_page[0]
        p_error.visible = visible_page[1]
        p_session.visible = visible_page[2]
        p_login.visible = visible_page[3]
        p_register.visible = visible_page[4]
        p_psection.visible = visible_page[5]
        p_history.visible = visible_page[6]
        p_cash.visible = visible_page[7]
        p_price.visible = visible_page[8]
        p_sbp.visible = visible_page[9]
        p_instruction.visible = visible_page[10]
        p_card.visible = visible_page[11]
        p_idsetup.visible = visible_page[12]
        p_blocked.visible = visible_page[13]
    }

    Connections {
        target: backend
        function onShowLoginMessage(isErr, message) {
            p_login.showErrorToast(isErr, message)
        }
    }

    Connections {
        target: backend
        function onShowRegisterMessage(isErr, message) {
            p_register.showErrorToast(isErr, message)
        }
    }

    Connections {
        target: backend
        function onShowSessionMessage(isErr, message) {
            p_session.showErrorToast(isErr, message)
            p_idsetup.showErrorToast(isErr, message)
        }
    }

    Connections {
        target: backend
        function onSetUIConfig(config) {
            window.title = config["Title"]
        }

        function onShowInitialization() {
            changePage(Constants.initialization)
        }

        function onShowPSection() {
            changePage(Constants.psection)
        }

        function onShowPriceList() {
            changePage(Constants.priceList)
        }

        function onShowInstruction() {
            changePage(Constants.instruction)
        }

        function onShowHistory(data) {
            changePage(Constants.history)
            p_history.loadHistoryFromData(data)
        }

        function onShowError() {
            changePage(Constants.error)
        }

        function onShowLogin() {
            p_login.clearFields()
            changePage(Constants.login)
        }

        function onShowCash() {
            changePage(Constants.cash)
        }

        function onShowRegister() {
            p_register.clearFields()
            changePage(Constants.register)
        }

        function onShowWaiting(isWaiting) {
            p_session.isWaiting = isWaiting
            if (isWaiting) {
                p_session.resetButtons()
            }

            if (p_initialization.visible) {
                changePage(Constants.session)
            }
        }

        function onShowSession() {
            changePage(Constants.session)
        }

        function onShowSbp() {
            p_sbp.resetStackView()
            changePage(Constants.sbp)
        }

        function onShowCard() {
            changePage(Constants.card)
        }

        function onShowIdSetup() {
            changePage(Constants.idsetup)
        }

        function onShowBlockedPage(blocked) {
            if (blocked) {
                changePage(Constants.blocked)
            } else if (p_blocked.visible) {
                changePage(Constants.session)
            }
        }
    }

    Connections {
        target: updater
        function onStatusTextChanged() {
            if (updater.statusText !== "") {
                p_session.showErrorToast(false, updater.statusText)
            }
        }
    }

    LoaderDialog {
        id: loader
        darkTheme: window.darkTheme
        onCancelClicked: backend.cancelLoading()
    }

    Connections {
        target: backend
        function onLoadingShown() {
            loader.visible = true
        }

        function onLoadingHidden() {
            loader.visible = false
        }
    }

    Session {
        id: p_session
        anchors.fill: parent
        isWaiting: true
        visible: false
        darkTheme: window.darkTheme
        onThemeToggleRequested: window.darkTheme = !window.darkTheme
    }

    Error {
        id: p_error
        visible: false
        darkTheme: window.darkTheme
    }

    Initialization {
        id: p_initialization
        visible: false
        darkTheme: window.darkTheme
    }

    LoginPage {
        id: p_login
        visible: false
        darkTheme: window.darkTheme
    }

    RegisterPage {
        id: p_register
        visible: false
        darkTheme: window.darkTheme
    }

    PaymentSelection {
        id: p_psection
        visible: false
        darkTheme: window.darkTheme
    }

    HistoryPage {
        id: p_history
        visible: false
        darkTheme: window.darkTheme
    }

    CashPage {
        id: p_cash
        visible: false
        darkTheme: window.darkTheme
    }

    PriceList {
        id: p_price
        visible: false
        darkTheme: window.darkTheme
    }

    SbpPage {
        id: p_sbp
        visible: false
        darkTheme: window.darkTheme
    }

    InstructionPage {
        id: p_instruction
        visible: false
        darkTheme: window.darkTheme
    }

    CardPage {
        id: p_card
        visible: false
        darkTheme: window.darkTheme
    }

    IdSetupPage {
        id: p_idsetup
        visible: false
        darkTheme: window.darkTheme
    }

    BlockedPage {
        id: p_blocked
        visible: false
        darkTheme: window.darkTheme
    }
}
