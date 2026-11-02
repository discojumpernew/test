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

    id: paymentSelection
    width: Constants.width
    height: Constants.height

    Rectangle {
        id: container
        anchors.fill: parent
        color: themeItem.appBackground

        // Кнопка Назад в правом верхнем углу
        ProgramButton {
            id: psection_back_btn
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

        Column {
            id: payCol
            anchors.centerIn: parent
            spacing: 30
            width: parent.width * 9 / 10

            // Заголовок
            Text {
                text: "Выберите способ оплаты"
                color: themeItem.textColor          // ← из темы
                font.pointSize: 32
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            // Верхний ряд: наличные + СБП
            Row {
                id: payRow
                spacing: 80
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter

                ProgramButton {
                    width: (parent.width - 80) / 2
                    height: 300
                    text: "Наличные"
                    prog_name.font.pointSize: 48

                    onButtonClicked: {
                        backend.showCash()
                    }
                }

                ProgramButton {
                    width: (parent.width - 80) / 2
                    height: 300
                    text: ""

                    onButtonClicked: {
                        backend.showSbp()
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 20
                        width: parent.width - 20
                        height: parent.height - 20

                        Image {
                            source: "qrc:sbpIn"
                            width: parent.width
                            height: parent.height
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }
            }

            // Нижняя кнопка: карта
            ProgramButton {
                width: (parent.width - 80) / 2
                height: 300
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Картой"
                prog_name.font.pointSize: 48

                onButtonClicked: {
                    backend.showCard()
                }
            }
        }
    }
}
