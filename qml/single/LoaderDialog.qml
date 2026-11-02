import QtQuick 2.4
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.1
import IPS4MCO 1.0

Rectangle {
    property bool darkTheme: true
    Theme {
        id: themeItem
        dark: darkTheme
    }

    id: root
    focus: true

    width: 600
    height: 400
    parent: Overlay.overlay
    anchors.centerIn: parent
    radius: 30
    color: themeItem.buttonTopColor          // ← из темы (фон диалога)
    border.color: themeItem.buttonBorderTopColor
    border.width: 2
    visible: false

    signal cancelClicked

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 50

        BusyIndicator {
            running: true
            Layout.alignment: Qt.AlignHCenter
            width: 250
            height: 250
            scale: 2.5
            palette.dark: themeItem.textColor   // ← из темы
        }

        Label {
            id: label
            text: "Ожидание ответа"
            font.pixelSize: 60
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            color: themeItem.textColor          // ← из темы
        }

        ProgramButton {
            text: "Отмена"
            prog_name.font.pointSize: 60
            height: 80
            onButtonClicked: {
                root.cancelClicked()
            }
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
