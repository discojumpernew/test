import QtQuick 2.4
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

    FontLoader {
        id: myFont
        source: "qrc:/fonts/TerminatorGenisys.ttf"
    }

    Column {
        anchors.centerIn: parent
        spacing: 40
        width: parent.width / 10 * 8

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "🔒"
            font.pixelSize: 160
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: backend.isBlocked && backend.hasIdCode
                  ? "ПОСТ ЗАБЛОКИРОВАН"
                  : "ПОСТ ЗАБЛОКИРОВАН"
            color: themeItem.titleColor
            font.pixelSize: 60
            font.bold: true
            font.family: myFont.name
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Работа поста приостановлена администратором.\nID код: " + (backend.hasIdCode ? backend.idCode : "—") +
                  "\nДля разблокировки обратитесь к администратору автомойки."
            color: themeItem.textColor
            font.pixelSize: 28
            font.family: themeItem.fontFamily
        }
    }
}
