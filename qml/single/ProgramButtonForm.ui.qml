import QtQuick 2.12
import IPS4MCO 1.0

Item {
    property bool darkTheme: true

    Theme {
        id: themeItem
        dark: darkTheme
    }

    property int bordersOffset: 4
    property int textSidesOffset: 16
    property bool checked: false
    property bool isLeftAligment: true
    property bool enableBorder: true
    property alias prog_name: prog_name
    property alias prog_name2: prog_name_2
    property alias text: prog_name.text
    property int borderThickness: 4

    property string iconSource: ""
    property real iconSize: 0.6
    property int iconOffsetY: -10

    property color topColor: checked ? themeItem.buttonActiveTop : themeItem.buttonTopColor
    property color bottomColor: checked ? themeItem.buttonActiveBottom : themeItem.buttonBottomColor
    property color textColor: checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
    property color borderTopColor: checked ? themeItem.buttonActiveBorderTop : themeItem.buttonBorderTopColor
    property color borderBottomColor: checked ? themeItem.buttonActiveBorderBottom : themeItem.buttonBorderBottomColor

    id: btn
    width: 400
    height: 400

    Rectangle {
        id: borderRect
        anchors.fill: parent
        radius: 30
        visible: enableBorder

        gradient: Gradient {
            GradientStop { position: 0.0; color: borderTopColor }
            GradientStop { position: 1.0; color: borderBottomColor }
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: enableBorder ? borderThickness : 0
        radius: enableBorder ? (30 - borderThickness) : 30

        gradient: Gradient {
            GradientStop { position: 0.0; color: topColor }
            GradientStop { position: 1.0; color: bottomColor }
        }
    }

    Image {
        id: icon
        source: iconSource
        visible: iconSource !== ""
        width: parent.height * iconSize
        height: parent.height * iconSize
        fillMode: Image.PreserveAspectFit
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: iconOffsetY
        z: 10
    }

    Text {
        id: prog_name
        visible: enableBorder
        text: ""
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 8
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignBottom
        color: textColor
        font.pointSize: themeItem.fontSize
        minimumPointSize: themeItem.fontSizeSmall
        fontSizeMode: Text.Fit
        font.weight: themeItem.fontWeight
        wrapMode: Text.WordWrap
        font.family: themeItem.fontFamily
    }

    Text {
        id: prog_name_2
        visible: !enableBorder
        text: prog_name.text
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 8
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignBottom
        color: textColor
        font.pointSize: themeItem.fontSize
        minimumPointSize: themeItem.fontSizeSmall
        fontSizeMode: Text.Fit
        wrapMode: Text.WordWrap
        font.weight: themeItem.fontWeight
        font.family: themeItem.fontFamily
    }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:2}
}
##^##*/
