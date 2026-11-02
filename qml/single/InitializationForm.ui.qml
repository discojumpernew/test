import QtQuick 2.4
import QtQuick.Controls 2.5
import IPS4MCO 1.0

Item {
    property bool darkTheme: true
    Theme {
        id: themeItem
        dark: darkTheme
    }

    id: content
    width: Constants.width
    height: Constants.height
    property alias label: label

    Rectangle {
        color: themeItem.appBackground
        anchors.fill: parent
    }

    BusyIndicator {
        id: busyIndicator
        width: 450
        height: 450
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -label.height
        anchors.horizontalCenterOffset: 0
        palette.dark: themeItem.textColor // ← из темы
    }

    Label {
        id: label
        anchors.centerIn: parent
        font.weight: Font.ExtraBold
        text: qsTr("ИНИЦИАЛИЗАЦИЯ")
        font.pixelSize: 80
        font.bold: false
        color: themeItem.textColor // ← из темы

        anchors.verticalCenterOffset: label.height + 200
        anchors.horizontalCenterOffset: 0
    }
}
