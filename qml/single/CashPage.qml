import QtQuick 2.4
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.1
import IPS4MCO 1.0

Item {
    property bool darkTheme: true
    Theme {
        id: themeItem
        dark: darkTheme
    }

    id: root

    Rectangle {
        id: container
        width: Constants.width
        height: Constants.height
        color: themeItem.appBackground

        Item {
            id: errorContainer
            anchors.top: cash_back_btn.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 20 // отступ от верха родителя
            height: 60
            z: 999

            Rectangle {
                id: errorToast
                width: parent.width - (parent.width / 15) * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height

                // Цвет зависит от isErr
                color: isErr ? Qt.rgba(1, 0, 0, 0.5) // красный
                             : Qt.rgba(0, 1, 0, 0.5) // зелёный

                radius: 10
                opacity: 0
                visible: false

                property bool isErr: true // по умолчанию ошибка (красный)

                Text {
                    id: errorText
                    anchors.centerIn: parent
                    color: "white"
                    font.pixelSize: 22
                    font.bold: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }

                Timer {
                    id: hideTimer
                    interval: 3000 // 3 секунды
                    running: false
                    repeat: false
                    onTriggered: {
                        errorToast.opacity = 0
                        hideTimer.running = false
                        errorToast.visible = false
                    }
                }
            }
        }

        // Кнопка Назад в правом верхнем углу
        ProgramButton {
            id: cash_back_btn
            text: "Назад"
            width: 240
            height: 100
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 20
            anchors.rightMargin: 20
            prog_name.font.pointSize: 38

            onButtonClicked: {
                backend.showSession(0)
            }
        }

        // Заголовок
        Text {
            anchors.centerIn: parent
            width: parent.width * 8 / 10
            text: "Внесите необходимую сумму в купюроприемник — она автоматически поступит на счет."
            color: themeItem.textColor          // ← из темы
            font.pointSize: 32
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
