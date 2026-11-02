import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import QtQuick.Controls.Material 2.15
import QtWebView 1.15
import IPS4MCO 1.0
import YooMoney 1.0
import QtQuick.VirtualKeyboard 2.4
import QtWebEngine 1.10

Item {
    property bool darkTheme: true
    Theme {
        id: themeItem
        dark: darkTheme
    }

    id: root
    width: Constants.width
    height: Constants.height

    function resetStackView() {
        stackView.clear(StackView.Immediate)
        stackView.push(mainPage)
    }

    InputPanel {
        id: keyboard
        z: 1000
        visible: Qt.inputMethod.visible
        width: Constants.width
        height: Constants.height
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: themeItem.appBackground

        YooMoneyQRHandler {
            id: handler
        }

        StackView {
            id: stackView
            anchors.fill: parent
            initialItem: mainPage
        }

        Component {
            id: mainPage
            Rectangle {
                color: themeItem.appBackground

                property real currentAmount: 50

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        ProgramButton {
                            id: spb_back_btn
                            text: "Назад"
                            width: 240
                            height: 100
                            prog_name.font.pointSize: 38
                            onButtonClicked: backend.showPSection()
                        }
                    }

                    Label {
                        text: "Выберите сумму пополнения"
                        color: themeItem.textColor // ← из темы
                        font.pointSize: 38
                        Layout.alignment: Qt.AlignHCenter
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 20

                        // Фиксированные суммы
                        Repeater {
                            model: [50, 100, 200, 300]
                            ProgramButton {
                                text: modelData + " ₽"
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                prog_name.font.pointSize: 36
                                onButtonClicked: currentAmount = modelData
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 40

                        ProgramButton {
                            text: "-10"
                            width: 200
                            height: 100
                            prog_name.font.pointSize: 36
                            onButtonClicked: {
                                currentAmount = Math.max(0, currentAmount - 10)
                            }
                        }

                        Label {
                            id: currentAmountLabel
                            text: "Текущая сумма: " + currentAmount.toFixed(
                                      2) + " ₽"
                            color: themeItem.textColor // ← из темы
                            font.pointSize: 32
                            Layout.alignment: Qt.AlignHCenter
                        }

                        ProgramButton {
                            text: "+10"
                            width: 200
                            height: 100
                            prog_name.font.pointSize: 36
                            onButtonClicked: currentAmount += 10
                        }
                    }

                    ProgramButton {
                        text: "Оплатить"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 400
                        Layout.preferredHeight: 100
                        prog_name.font.pointSize: 36
                        onButtonClicked: handler.createPayment(
                                             currentAmount.toFixed(2),
                                             "Платёж на " + currentAmount.toFixed(
                                                 0))
                    }
                }
            }
        }

        Component {
            id: paymentPage
            Rectangle {
                color: themeItem.appBackground

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    WebEngineView {
                        id: webView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        url: handler.confirmationUrl
                        onLoadingChanged: function (loadRequest) {
                            console.log("WebEngineView loading:",
                                        loadRequest.url, "status:",
                                        loadRequest.status)
                            if (loadRequest.status === WebEngineView.LoadFailed) {
                                errorDialog.text = "Ошибка загрузки страницы: "
                                        + loadRequest.errorString
                                errorDialog.open()
                                stackView.pop()
                            }
                        }
                        onJavaScriptConsoleMessage: {
                            console.log("JS Message:", message, "Source:",
                                        sourceID, "Line:", lineNumber)
                        }
                    }

                    ProgramButton {
                        text: "Вернуться"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90
                        prog_name.font.pointSize: 32
                        onButtonClicked: backend.showPSection()
                    }
                }
            }
        }

        Dialog {
            id: errorDialog
            title: "Ошибка"
            anchors.centerIn: parent
            modal: true

            Label {
                id: errorText
                text: ""
                color: themeItem.textColor
            }

            standardButtons: Dialog.Ok
            onAccepted: close()
        }

        Connections {
            target: handler
            function onErrorOccurred(error) {
                errorDialog.text = "Ошибка: " + error
                errorDialog.open()
            }
            function onConfirmationUrlReceived(paymentId, url) {
                stackView.push(paymentPage)
            }
            function onSuccessPayment(value) {
                backend.successPay(value)
            }
        }
    }
}
