import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import IPS4MCO 1.0

Item {
    property bool darkTheme: true
    Theme {
        id: themeItem
        dark: darkTheme
    }

    id: root

    function loadHistoryFromData(data) {
        historyModel.clear()
        for (var i = 0; i < data.length; ++i) {
            historyModel.append(data[i])
        }
    }

    Rectangle {
        id: container
        width: Constants.width
        height: Constants.height
        color: themeItem.appBackground

        ProgramButton {
            id: history_back_btn
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
            id: historyCol
            anchors.top: history_back_btn.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 100
            width: parent.width * 0.9

            Text {
                text: "История пополнений"
                color: themeItem.textColor          // ← из темы
                font.pointSize: 36
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ListModel {
                id: historyModel
            }

            ScrollView {
                width: parent.width
                height: parent.height - history_back_btn.height - 10 - 60 - 50 - 30

                ListView {
                    width: parent.width
                    spacing: 10
                    model: historyModel

                    delegate: Rectangle {
                        width: ListView.view.width * 0.95
                        anchors.horizontalCenter: ListView.view.horizontalCenter
                        height: 100
                        radius: 12
                        border.color: themeItem.buttonBorderTopColor
                        border.width: 2

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: themeItem.buttonTopColor
                            }
                            GradientStop {
                                position: 1.0
                                color: themeItem.buttonBottomColor
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 20

                            ColumnLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Дата: " + model.createdAt.toLocaleString()
                                    color: themeItem.buttonTextColor   // ← из темы
                                    font.pixelSize: 20
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "ID операции: " + model.id
                                    color: themeItem.buttonTextColor   // ← из темы
                                    font.pixelSize: 16
                                }
                            }

                            Text {
                                text: model.amount + " ₽"
                                color: model.amount > 0 ? "#388E3C" : "#FF4444"
                                font.pixelSize: 24
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
