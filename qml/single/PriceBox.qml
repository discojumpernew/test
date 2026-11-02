import QtQuick 2.4
import IPS4MCO 1.0

Rectangle {
    property bool darkTheme: true
    Theme {
        id: themeItem
        dark: darkTheme
    }

    property alias box_name: box_name
    property alias box_price: box_price
    property alias backgroundImage: backgroundImage.source
    property int padding_from_name

    id: container
    anchors.margins: 5
    border.color: themeItem.buttonBorderTopColor
    border.width: 2
    radius: 8

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: themeItem.buttonTopColor
        }
        GradientStop {
            position: 0.6
            color: themeItem.buttonBottomColor
        }
    }

    Image {
        id: backgroundImage
        width: 300
        height: 300

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 20

        fillMode: Image.PreserveAspectFit
        opacity: 0.1
    }

    Row {
        anchors.fill: parent
        anchors.margins: 5
        spacing: padding_from_name

        Text {
            id: box_name
            width: parent.width * 0.60
            anchors.verticalCenter: parent.verticalCenter
            color: themeItem.buttonTextColor          // ← из темы
            font.pointSize: 32
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
        }

        Column {
            width: parent.width * 0.25
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                id: box_price
                color: themeItem.buttonTextColor          // ← из темы
                font.pointSize: 40
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                id: separator
                width: 100
                height: 1
                color: themeItem.buttonTextColor          // ← из темы
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "мин"
                color: themeItem.buttonTextColor          // ← из темы
                font.pointSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
