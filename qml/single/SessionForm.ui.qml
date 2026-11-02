import QtQuick 2.4
import IPS4MCO 1.0

Rectangle {
    id: container
    property bool darkTheme: true
    signal themeToggleRequested

    Theme {
        id: themeItem
        dark: darkTheme
    }

    width: Constants.width
    height: Constants.height
    color: themeItem.appBackground

    property alias balance: balance
    property alias btn10: btn10
    property alias btn9: btn9
    property alias btn8: btn8
    property alias btn7: btn7
    property alias btn6: btn6
    property alias btn5: btn5
    property alias btn4: btn4
    property alias btn3: btn3
    property alias btn2: btn2
    property alias btn1: btn1
    property alias pause_btn: pause_btn
    property alias login_btn: login_btn
    property alias price_btn: price_btn
    property alias hideTimer: hideTimer
    property alias errorToast: errorToast
    property alias errorText: errorText
    property alias histroy_btn: histroy_btn
    property alias instruction_btn: instruction_btn
    property bool isWaiting: false

    FontLoader {
        id: myFont
        source: "qrc:/fonts/TerminatorGenisys.ttf"
    }

    Item {
        id: errorContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 50
        height: 80
        z: 999

        Rectangle {
            id: errorToast
            width: parent.width - (parent.width / 15) * 2
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height

            color: isErr ? Qt.rgba(1, 0, 0, 0.8) : Qt.rgba(0, 1, 0, 0.8)
            radius: 10
            opacity: 0
            visible: false
            property bool isErr: true

            Text {
                id: errorText
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 30
                font.bold: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Timer {
                id: hideTimer
                interval: 3000
                running: false
                repeat: false
            }
        }
    }

    Rectangle {
        id: header
        width: parent.width
        height: parent.height / 20
        color: themeItem.appBackground
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        Row {
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Image {
                id: logo
                height: parent.height
                fillMode: Image.PreserveAspectFit
                source: "qrc:logoIm"
                width: 150
            }

            Rectangle {
                id: sep
                height: Constants.res1920_1080 ? (parent.height - 50) : (parent.height - 20)
                width: Constants.res1920_1080 ? 4 : 3
                anchors.verticalCenter: parent.verticalCenter
                color: themeItem.textColor
            }

            Text {
                id: title
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: Text.AlignVCenter
                font.pointSize: themeItem.fontSize
                minimumPointSize: themeItem.fontSizeSmall
                fontSizeMode: Text.Fit
                wrapMode: Text.WordWrap
                font.family: themeItem.fontFamily
                font.weight: themeItem.fontWeight
                color: themeItem.titleColor
                text: "Self Service"
            }
        }
    }

    ProgramButton {
        id: theme_toggle_btn
        darkTheme: container.darkTheme
        width: 80
        height: 80
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 10
        text: container.darkTheme ? "☀" : "🌙"
        prog_name.font.pointSize: 48
        enabled: true

        onButtonClicked: {
            container.themeToggleRequested()
        }
    }

    ProgramButton {
        id: balance
        darkTheme: container.darkTheme
        property alias textBalance: text_balance.text

        width: parent.width / 10 * 9
        height: parent.height / 7
        anchors.top: header.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        textBalance: (isWaiting ? "Нажмите сюда,\nчтобы пополнить" : (backend.balance + "₽"))
        text: ""
        enabled: true

        Image {
            id: balance_icon
            source: "qrc:balanceIcon"
            width: parent.height * 0.95
            height: parent.height * 0.95
            fillMode: Image.PreserveAspectFit
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            z: 10
        }

        Text {
            id: label_balance
            text: "БАЛАНС"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 15
            height: parent.height * 0.25
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            color: themeItem.secondaryTextColor
            font.bold: true
            font.pixelSize: themeItem.fontSizeLarge
            font.family: myFont.name
        }

        Text {
            id: text_balance
            text: "0"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: label_balance.bottom
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 15
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            color: themeItem.accentColor
            font.pixelSize: Constants.res1920_1080 ? (isWaiting ? 40 : 180) : (isWaiting ? 36 : 140)
            font.bold: true
        }
    }

    ProgramButton {
        id: histroy_btn
        darkTheme: container.darkTheme
        width: parent.width / 6 * 0.65
        height: width
        anchors.top: header.bottom
        anchors.left: balance.right
        anchors.leftMargin: 10
        text: ""
        visible: backend.hasCurrentUser

        Column {
            anchors.centerIn: parent
            spacing: 5
            width: parent.width - 5
            height: parent.height - 5

            Image {
                source: "qrc:historyIn"
                width: parent.width
                height: parent.height
                fillMode: Image.PreserveAspectFit
            }
        }
    }

    Item {
        id: time_div
        width: parent.width / 10 * 9
        height: parent.height / 9
        anchors.top: balance.bottom
        anchors.topMargin: Constants.res1920_1080 ? 30 : 20
        anchors.horizontalCenter: parent.horizontalCenter

        property alias textBalance: text_balance.text
        property alias textTime: text_time.text
        property alias text_balance: text_balance
        property alias text_time: text_time

        Rectangle {
            id: time_border
            anchors.fill: parent
            radius: 30

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: themeItem.buttonBorderTopColor
                }
                GradientStop {
                    position: 1.0
                    color: themeItem.buttonBorderBottomColor
                }
            }
        }

        Rectangle {
            id: time_bg
            anchors.fill: parent
            anchors.margins: 4
            radius: 26

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
        }

        Item {
            id: timer
            anchors.fill: parent

            Text {
                id: label_time
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height / 20
                height: parent.height * 0.15
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: themeItem.secondaryTextColor
                font.pixelSize: 50
                text: "ВРЕМЯ"
                font.family: myFont.name
            }

            Text {
                id: text_time
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: label_time.bottom
                anchors.bottom: parent.bottom
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: themeItem.accentColor
                font.pixelSize: Constants.res1920_1080 ? 100 : 70
                font.bold: true
                text: backend.time
            }
        }
    }

    Rectangle {
        id: header2
        width: time_div.width - 40
        height: parent.height / 25
        color: "transparent"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: time_div.bottom

        Row {
            id: headerRow
            anchors.fill: parent
            spacing: 15

            Rectangle {
                width: (headerRow.width - headerText.width - headerRow.spacing * 2) / 2
                height: 3
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 0.15
                        color: themeItem.lineColor
                    }
                    GradientStop {
                        position: 0.85
                        color: themeItem.lineColor
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }

            Text {
                id: headerText
                text: "ЧИСТАЯ ВОДА"
                color: themeItem.textColor
                font.pointSize: themeItem.fontSizeSmall
                minimumPointSize: themeItem.fontSizeSmall
                fontSizeMode: Text.Fit
                font.family: myFont.name
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: (headerRow.width - headerText.width - headerRow.spacing * 2) / 2
                height: 3
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 0.15
                        color: themeItem.lineColor
                    }
                    GradientStop {
                        position: 0.85
                        color: themeItem.lineColor
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }
        }
    }

    Rectangle {
        id: waterRect
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header2.bottom
        width: parent.width / 10 * 9
        height: parent.height / 6
        radius: 30
        border.color: themeItem.appBackground
        border.width: 0

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: themeItem.appBackground
            }
            GradientStop {
                position: 1.0
                color: themeItem.appBackground
            }
        }

        Row {
            id: waterRow
            anchors.fill: parent
            spacing: 20

            ProgramButton {
                id: btn5
                darkTheme: container.darkTheme
                width: (parent.width - 40) / 3
                height: parent.height
                enableBorder: true
                enabled: !container.isWaiting
                text: ""
                iconSource: "qrc:weakPressureIcon"
                iconSize: 0.7
                iconOffsetY: -30

                Text {
                    horizontalAlignment: Text.AlignHCenter
                    text: "СЛАБОЕ\nДАВЛЕНИЕ"
                    color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                    font.family: myFont.name
                    font.pointSize: themeItem.fontSize - 4
                    font.weight: themeItem.fontWeight
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.bottomMargin: 32
                    verticalAlignment: Text.AlignBottom
                }
            }

            ProgramButton {
                id: btn4
                darkTheme: container.darkTheme
                width: (parent.width - 40) / 3
                height: parent.height
                enableBorder: true
                enabled: !container.isWaiting
                text: ""
                iconSource: "qrc:averagePressureIcon"
                iconSize: 0.65
                iconOffsetY: -20

                Text {
                    horizontalAlignment: Text.AlignHCenter
                    text: "СРЕДНЕЕ\nДАВЛЕНИЕ"
                    color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                    font.family: myFont.name
                    font.pointSize: themeItem.fontSize - 4
                    font.weight: themeItem.fontWeight
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.bottomMargin: 32
                    verticalAlignment: Text.AlignBottom
                }
            }

            ProgramButton {
                id: btn3
                darkTheme: container.darkTheme
                width: (parent.width - 40) / 3
                height: parent.height
                enableBorder: true
                enabled: !container.isWaiting
                text: ""
                iconSource: "qrc:strongPressureIcon"
                iconSize: 0.65
                iconOffsetY: -20

                Text {
                    horizontalAlignment: Text.AlignHCenter
                    text: "ВЫСОКОЕ\nДАВЛЕНИЕ"
                    color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                    font.family: myFont.name
                    font.pointSize: themeItem.fontSize - 4
                    font.weight: themeItem.fontWeight
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.bottomMargin: 32
                    verticalAlignment: Text.AlignBottom
                }
            }
        }
    }

    Rectangle {
        id: header3
        width: time_div.width - 40
        height: parent.height / 25
        color: "transparent"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: waterRect.bottom

        Row {
            id: headerRowM
            anchors.fill: parent
            spacing: 15

            Rectangle {
                width: Math.max(
                           0,
                           (headerRowM.width - headerTextM.width - headerRowM.spacing * 2) / 2)
                height: 3
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 0.15
                        color: themeItem.lineColor
                    }
                    GradientStop {
                        position: 0.85
                        color: themeItem.lineColor
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }

            Text {
                id: headerTextM
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: themeItem.fontSizeSmall
                minimumPointSize: themeItem.fontSizeSmall
                fontSizeMode: Text.Fit
                wrapMode: Text.WordWrap
                font.family: myFont.name
                color: themeItem.textColor
                text: "ОСНОВНАЯ МОЙКА"
            }

            Rectangle {
                width: Math.max(
                           0,
                           (headerRowM.width - headerTextM.width - headerRowM.spacing * 2) / 2)
                height: 3
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 0.15
                        color: themeItem.lineColor
                    }
                    GradientStop {
                        position: 0.85
                        color: themeItem.lineColor
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }
        }
    }

    Row {
        id: mainCleaning1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header3.bottom
        width: parent.width / 10 * 9
        height: parent.height / 7
        spacing: 20

        ProgramButton {
            id: btn6
            darkTheme: container.darkTheme
            width: (parent.width -40) / 3
            height: parent.height
            iconSource: "qrc:foamPinkIcon"
            iconSize: 0.65
            text: ""
            iconOffsetY: -20
            enabled: !container.isWaiting

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "ПЕНА\nРОЗОВАЯ"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize - 4
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 24
                verticalAlignment: Text.AlignBottom
            }
        }

        ProgramButton {
            id: btn7
            darkTheme: container.darkTheme
            width: (parent.width -40) / 3
            height: parent.height
            text: ""
            iconSource: "qrc:foamYellowIcon"
            iconSize: 0.65
            iconOffsetY: -20
            enabled: !container.isWaiting

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "ПЕНА\nЖЕЛТАЯ"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize - 4
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 24
                verticalAlignment: Text.AlignBottom
            }
        }

        ProgramButton {
            id: btn8
            darkTheme: container.darkTheme
            width: (parent.width -40) / 3
            height: parent.height
            iconSource: "qrc:foamWhiteIcon"
            text: ""
            iconSize: 0.65
            iconOffsetY: -20
            enabled: !container.isWaiting

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "ПЕНА\nБЕЛАЯ"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize - 4
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 24
                verticalAlignment: Text.AlignBottom
            }
        }
    }

    Row {
        id: mainCleaning2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: mainCleaning1.bottom
        anchors.topMargin: 20
        width: parent.width / 10 * 9
        height: parent.height / 8
        spacing: 20

        ProgramButton {
            id: btn9
            darkTheme: container.darkTheme
            width: (parent.width - 60) / 4
            height: parent.height
            iconSource: "qrc:chemistryIcon"
            iconSize: 0.6
            iconOffsetY: -10
            text: ""
            enabled: !container.isWaiting

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "АКТИВНАЯ\nХИМИЯ"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize - 8
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 24
                verticalAlignment: Text.AlignBottom
            }
        }

        ProgramButton {
            id: btn10
            darkTheme: container.darkTheme
            width: (parent.width - 60) / 4
            height: parent.height
            iconSource: "qrc:waxIcon"
            iconSize: 0.6
            iconOffsetY: -10
            text: ""
            enabled: !container.isWaiting

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "ВОСК"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize - 4
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 32
                verticalAlignment: Text.AlignBottom
            }
        }

        ProgramButton {
            id: btn1
            darkTheme: container.darkTheme
            width: (parent.width - 60) / 4
            height: parent.height
            iconSource: "qrc:turboIcon"
            iconSize: 0.6
            iconOffsetY: -10
            text: ""
            enabled: !container.isWaiting

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "ТУРБО\nСУШКА"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize - 8
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 24
                verticalAlignment: Text.AlignBottom
            }
        }

        ProgramButton {
            id: btn2
            darkTheme: container.darkTheme
            width: (parent.width - 60) / 4
            height: parent.height
            iconSource: "qrc:vacuumIcon"
            iconSize: 0.6
            iconOffsetY: -10
            text: ""
            enabled: !container.isWaiting

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "ПЫЛЕСОС"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize - 4
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 32
                verticalAlignment: Text.AlignBottom
            }
        }
    }

    Row {
        id: mainCleaning3
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: mainCleaning2.bottom
        anchors.topMargin: 20
        width: parent.width / 10 * 9
        height: parent.height / 8
        spacing: 20

        ProgramButton {
            id: pause_btn
            darkTheme: container.darkTheme
            width: (parent.width - 60) / 4
            height: parent.height
            text: ""
            iconSource: "qrc:pauseIcon"
            iconSize: 0.4
            iconOffsetY: 36
            enabled: !container.isWaiting

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "ПАУЗА"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize + 2
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 34
                verticalAlignment: Text.AlignBottom
            }
        }

        ProgramButton {
            id: login_btn
            darkTheme: container.darkTheme
            width: (parent.width - 60) / 4
            height: parent.height
            text: ""
            iconSource: "qrc:loginIcon"
            iconSize: 0.46
            iconOffsetY: 20
            enabled: true

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: backend.hasCurrentUser ? "ВЫХОД ИЗ\nАККАУНТА" : "ВХОД В\nЛИЧНЫЙ\nКАБИНЕТ"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize - 12
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 14
                verticalAlignment: Text.AlignBottom
            }
        }

        ProgramButton {
            id: price_btn
            darkTheme: container.darkTheme
            width: (parent.width - 60) / 4
            height: parent.height
            text: ""
            iconSource: "qrc:priceIcon"
            iconSize: 0.46
            iconOffsetY: 36
            enabled: true

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "ПРАЙС"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize + 2
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 34
                verticalAlignment: Text.AlignBottom
            }
        }

        ProgramButton {
            id: instruction_btn
            darkTheme: container.darkTheme
            width: (parent.width - 60) / 4
            height: parent.height
            text: ""
            iconSource: "qrc:instructionIcon"
            iconSize: 0.46
            iconOffsetY: 36
            enabled: true

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: "ИНСТРУКЦИЯ"
                color: parent.checked ? themeItem.buttonActiveTextColor : themeItem.buttonTextColor
                font.family: myFont.name
                font.pointSize: themeItem.fontSize - 12
                font.weight: themeItem.fontWeight
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 34
                verticalAlignment: Text.AlignBottom
            }
        }
    }
}
