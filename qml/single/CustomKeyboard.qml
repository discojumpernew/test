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

    id: keyboard
    width: 400
    height: 500
    visible: false // по умолчанию скрыта
    signal keyPressed(string key)

    GridLayout {
        id: grid
        anchors.fill: parent
        anchors.margins: 10
        rowSpacing: 10
        columnSpacing: 10
        columns: 3

        // 1–9
        Repeater {
            model: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 30
                border.color: themeItem.buttonBorderTopColor
                border.width: 2

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: mouseArea.pressed ? themeItem.buttonActiveTop : themeItem.buttonTopColor
                    }
                    GradientStop {
                        position: 1.0
                        color: mouseArea.pressed ? themeItem.buttonActiveBottom : themeItem.buttonBottomColor
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.family: themeItem.fontFamily
                    font.weight: themeItem.fontWeight
                    font.pixelSize: 36
                    color: mouseArea.pressed ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    onClicked: keyboard.keyPressed(modelData)
                }
            }
        }

        // пустая ячейка (слева от 0)
        Item {}

        // кнопка 0
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 30
            border.color: themeItem.buttonBorderTopColor
            border.width: 2

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: mouseArea0.pressed ? themeItem.buttonActiveTop : themeItem.buttonTopColor
                }
                GradientStop {
                    position: 1.0
                    color: mouseArea0.pressed ? themeItem.buttonActiveBottom : themeItem.buttonBottomColor
                }
            }

            Text {
                anchors.centerIn: parent
                text: "0"
                font.family: themeItem.fontFamily
                font.weight: themeItem.fontWeight
                font.pixelSize: 36
                color: mouseArea0.pressed ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
            }

            MouseArea {
                id: mouseArea0
                anchors.fill: parent
                onClicked: keyboard.keyPressed("0")
            }
        }

        // кнопка стереть
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 30
            border.color: themeItem.buttonBorderTopColor
            border.width: 2

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: mouseAreaDel.pressed ? themeItem.buttonActiveTop : themeItem.buttonTopColor
                }
                GradientStop {
                    position: 1.0
                    color: mouseAreaDel.pressed ? themeItem.buttonActiveBottom : themeItem.buttonBottomColor
                }
            }

            Text {
                anchors.centerIn: parent
                text: "⌫"
                font.family: themeItem.fontFamily
                font.weight: themeItem.fontWeight
                font.pixelSize: 36
                color: mouseAreaDel.pressed ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
            }

            MouseArea {
                id: mouseAreaDel
                anchors.fill: parent
                onClicked: keyboard.keyPressed("back")
            }
        }
    }
}
