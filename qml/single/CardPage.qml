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

        // Логотип VENDOTEK
        Image {
            id: vendotekImage
            source: "qrc:/vendotek"

            width: 600
            height: 600

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 250

            fillMode: Image.PreserveAspectFit
        }

        // Надпись + стрелка
        Row {
            id: instructionRow

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: vendotekImage.bottom
            anchors.topMargin: 40

            spacing: 30

            Image {
                id: leftArrowImage
                source: "qrc:/left_arrow"

                width: 120
                height: 120

                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: "Воспользуйтесь\nтерминалом слева"

                color: themeItem.textColor // ← из темы
                font.pointSize: 32
                font.bold: true

                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter

                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Кнопка Назад
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
