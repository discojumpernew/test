import QtQuick 2.4
import QtQuick.Controls 2.5
import IPS4MCO 1.0

Rectangle {
    id: container
    property bool darkTheme: true

    Theme {
        id: themeItem
        dark: darkTheme
    }

    width: Constants.width
    height: Constants.height
    color: themeItem.appBackground

    function clearFields() {
        codeInput.text = ""
    }

    function showErrorToast(isErr, text) {
        if (hideTimer.running) {
            hideTimer.stop()
            errorToast.opacity = 0
        }

        errorText.text = text
        errorToast.isErr = isErr
        errorToast.visible = true
        errorToast.opacity = 1
        hideTimer.start()
    }

    FontLoader {
        id: myFont
        source: "qrc:/fonts/TerminatorGenisys.ttf"
    }

    Item {
        id: errorContainer
        anchors.top: parent.top
        anchors.topMargin: 50
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        z: 999

        Rectangle {
            id: errorToast
            width: parent.width - (parent.width / 15) * 2
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height

            color: isErr ? Qt.rgba(1, 0, 0, 0.8) : Qt.rgba(0, 1, 0, 0.8)
            radius: 10
            opacity: 0
            visible: false
            property bool isErr: true

            Text {
                id: errorText
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 30
                font.bold: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Timer {
                id: hideTimer
                interval: 3000
                running: false
                repeat: false
            }
        }
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.topMargin: 160
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width / 10 * 8
        spacing: 40

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "АКТИВАЦИЯ ПОСТА"
            color: themeItem.titleColor
            font.pixelSize: 64
            font.bold: true
            font.family: myFont.name
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Введите ID код, выданный администратором.\nКод определяет автомойку и пост, на котором установлен терминал."
            color: themeItem.textColor
            font.pixelSize: 26
            font.family: themeItem.fontFamily
        }

        Rectangle {
            id: inputBox
            width: parent.width
            height: 120
            radius: 30

            gradient: Gradient {
                GradientStop { position: 0.0; color: themeItem.buttonBorderTopColor }
                GradientStop { position: 1.0; color: themeItem.buttonBorderBottomColor }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 26

                gradient: Gradient {
                    GradientStop { position: 0.0; color: themeItem.buttonTopColor }
                    GradientStop { position: 1.0; color: themeItem.buttonBottomColor }
                }
            }

            Text {
                id: codeInput
                anchors.centerIn: parent
                text: ""
                color: themeItem.accentColor
                font.pixelSize: 64
                font.bold: true
                font.letterSpacing: 6
                font.family: myFont.name
            }
        }

        Row {
            width: parent.width
            spacing: 30

            CustomKeyboard {
                id: keyboard
                width: (parent.width - 30) / 3 * 2
                height: 640
                darkTheme: container.darkTheme
                visible: true

                onKeyPressed: (key) => {
                    if (key === "back") {
                        codeInput.text = codeInput.text.slice(0, -1)
                    } else if (codeInput.text.length < 16) {
                        codeInput.text += key
                    }
                }
            }

            Column {
                width: (parent.width - 30) / 3
                height: 640
                spacing: 30

                ProgramButton {
                    id: submit_btn
                    darkTheme: container.darkTheme
                    width: parent.width
                    height: (parent.height - 30) / 2
                    text: "ПОДТВЕРДИТЬ"

                    onButtonClicked: {
                        backend.submitIdCode(codeInput.text)
                    }
                }

                ProgramButton {
                    id: clear_btn
                    darkTheme: container.darkTheme
                    width: parent.width
                    height: (parent.height - 30) / 2
                    text: "ОЧИСТИТЬ"

                    onButtonClicked: {
                        codeInput.text = ""
                    }
                }
            }
        }
    }
}
