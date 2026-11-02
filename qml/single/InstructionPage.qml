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
        // Если "инструкция" — картинка на весь экран, можно оставить appBackground,
        // либо использовать Theme, если фон под картинкой не важен

        Image {
            id: backgroundImage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: price_list_back.bottom
            anchors.topMargin: 20
            anchors.bottom: parent.bottom
            source: "qrc:/instruction"
            fillMode: Image.PreserveAspectFit
        }

        ProgramButton {
            id: price_list_back
            text: "Назад"
            width: 370
            height: 100
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 20
            anchors.rightMargin: 20
            prog_name.font.pointSize: 38

            onButtonClicked: {
                Qt.inputMethod.hide()
                backend.showSession(0)
            }
        }
    }
}
