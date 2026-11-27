import QtQuick 2.15
import QtQuick.Controls 2.5
import IPS4MCO 1.0

Item {
    property bool darkTheme: true
    Theme {
        id: themeItem
        dark: darkTheme
    }

    id: root
    width: Constants.width
    height: Constants.height

    FontLoader {
        id: myFont
        source: "qrc:/fonts/TerminatorGenisys.ttf"
    }

    // === Локальное состояние панели (применяется по кнопке СОХРАНИТЬ) ===
    property int currentTab: 0 // 0 тарифы, 1 дизайн, 2 программы, 3 платежи
    property string selDesign: "classic"
    property var rates: ({
        "cleaner": 15, "drying": 15, "water": 40, "chemistry": 50,
        "foam": 50, "wax": 50, "pause": 5
    })
    property bool progTurboV: true
    property bool progVacuumV: true
    property bool progChemistryV: true
    property bool progWaxV: true
    property bool progPinkV: true
    property bool progYellowV: true
    property bool progWhiteV: true
    property bool payCashV: true
    property bool paySbpV: true
    property bool payCardV: true

    function refreshFromBackend() {
        var r = {}
        r["cleaner"] = parseInt(backend.cleanerRate) || 0
        r["drying"] = parseInt(backend.dryingRate) || 0
        r["water"] = parseInt(backend.waterRate) || 0
        r["chemistry"] = parseInt(backend.chemistryRate) || 0
        r["foam"] = parseInt(backend.foamRate) || 0
        r["wax"] = parseInt(backend.waxRate) || 0
        r["pause"] = parseInt(backend.pauseRate) || 0
        rates = r

        selDesign = backend.designTheme

        progTurboV = backend.progTurbo
        progVacuumV = backend.progVacuum
        progChemistryV = backend.progChemistry
        progWaxV = backend.progWax
        progPinkV = backend.progFoamPink
        progYellowV = backend.progFoamYellow
        progWhiteV = backend.progFoamWhite

        payCashV = backend.payCash
        paySbpV = backend.paySbp
        payCardV = backend.payCard
    }

    function saveAll() {
        var m = {}
        m["rate_cleaner"] = String(rates["cleaner"])
        m["rate_drying"] = String(rates["drying"])
        m["rate_water"] = String(rates["water"])
        m["rate_chemistry"] = String(rates["chemistry"])
        m["rate_foam"] = String(rates["foam"])
        m["rate_wax"] = String(rates["wax"])
        m["rate_pause"] = String(rates["pause"])
        m["design"] = selDesign
        m["prog_turbo"] = progTurboV ? "1" : "0"
        m["prog_vacuum"] = progVacuumV ? "1" : "0"
        m["prog_chemistry"] = progChemistryV ? "1" : "0"
        m["prog_wax"] = progWaxV ? "1" : "0"
        m["prog_pink"] = progPinkV ? "1" : "0"
        m["prog_yellow"] = progYellowV ? "1" : "0"
        m["prog_white"] = progWhiteV ? "1" : "0"
        m["pay_cash"] = payCashV ? "1" : "0"
        m["pay_sbp"] = paySbpV ? "1" : "0"
        m["pay_card"] = payCardV ? "1" : "0"
        backend.adminSaveSettings(m)
    }

    Component.onCompleted: refreshFromBackend()

    Connections {
        target: backend
        function onAdminSettingsSaved(ok) {
            showErrorToast(!ok, ok ? "Настройки сохранены и применены."
                                   : "Ошибка сохранения. Проверьте сеть.")
        }
        function onShowAdmin() {
            root.refreshFromBackend()
        }
    }

    function showErrorToast(isErr, text) {
        if (hideTimer.running)
            hideTimer.stop()
        toastText.text = text
        errorToast.isErr = isErr
        errorToast.visible = true
        errorToast.opacity = 1
        hideTimer.start()
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: themeItem.appBackground

        // Кнопка выхода
        ProgramButton {
            id: admin_back_btn
            text: "ВЫЙТИ"
            centerText: true
            width: 300
            height: 100
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 20
            anchors.rightMargin: 20
            prog_name.font.pointSize: 34

            onButtonClicked: backend.showSession(0)
        }

        Text {
            id: title
            text: "АДМИН-ПАНЕЛЬ"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 30
            anchors.topMargin: 40
            color: themeItem.titleColor
            font.pointSize: 42
            font.bold: true
            font.family: myFont.name
        }

        // === Вкладки ===
        Row {
            id: tabs
            anchors.top: title.bottom
            anchors.topMargin: 24
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 30
            anchors.rightMargin: 30
            spacing: 14

            Repeater {
                model: ["ТАРИФЫ", "ДИЗАЙН", "ПРОГРАММЫ", "ПЛАТЕЖИ"]

                delegate: Rectangle {
                    width: (parent.width - 42) / 4
                    height: 90
                    radius: 14
                    color: root.currentTab === index
                           ? (themeItem.dark ? "#f8fafb" : "#ffd66b")
                           : themeItem.buttonTopBackground
                    border.color: root.currentTab === index
                                  ? themeItem.buttonBorderBottomColor
                                  : themeItem.buttonBorderTopColor
                    border.width: 3

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: root.currentTab === index
                               ? (themeItem.dark ? "#0a0a0a" : "#3a2c00")
                               : themeItem.buttonTextColor
                        font.pointSize: 26
                        font.bold: true
                        font.family: myFont.name
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.currentTab = index
                    }
                }
            }
        }

        // === Контент вкладок ===
        Item {
            id: content
            anchors.top: tabs.bottom
            anchors.topMargin: 24
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: saveBtn.top
            anchors.bottomMargin: 24
            anchors.leftMargin: 30
            anchors.rightMargin: 30

            // ---------- ТАРИФЫ ----------
            Column {
                visible: root.currentTab === 0
                width: parent.width
                spacing: 18

                Text {
                    text: "Тарифы (₽ за минуту или за запуск)"
                    color: themeItem.secondaryTextColor
                    font.pointSize: 24
                    font.family: myFont.name
                }

                Repeater {
                    model: ListModel {
                        id: ratesModel
                        ListElement { key: "cleaner"; label: "ПЫЛЕСОС" }
                        ListElement { key: "drying"; label: "ТУРБО СУШКА" }
                        ListElement { key: "water"; label: "ВОДА" }
                        ListElement { key: "chemistry"; label: "АКТИВНАЯ ХИМИЯ" }
                        ListElement { key: "foam"; label: "ПЕНА" }
                        ListElement { key: "wax"; label: "ВОСК" }
                        ListElement { key: "pause"; label: "ПАУЗА" }
                    }

                    delegate: Rectangle {
                        width: content.width
                        height: 120
                        radius: 14
                        color: themeItem.buttonTopBackground
                        border.color: themeItem.buttonBorderTopColor
                        border.width: 2

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 28
                            text: label
                            color: themeItem.buttonTextColor
                            font.pointSize: 28
                            font.family: myFont.name
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 24
                            spacing: 16

                            Rectangle {
                                width: 110
                                height: 90
                                radius: 12
                                color: themeItem.buttonBottomBackground
                                border.color: themeItem.buttonBorderBottomColor
                                border.width: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: "−"
                                    color: themeItem.buttonTextColor
                                    font.pointSize: 44
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        var v = root.rates[key]
                                        if (v > 0) {
                                            var r = Object.assign({}, root.rates)
                                            r[key] = v - 1
                                            root.rates = r
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: 190
                                height: 90
                                radius: 12
                                color: "transparent"
                                border.color: themeItem.buttonBorderTopColor
                                border.width: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: root.rates[key] + " ₽"
                                    color: themeItem.accentColor
                                    font.pointSize: 34
                                    font.bold: true
                                    font.family: myFont.name
                                }
                            }

                            Rectangle {
                                width: 110
                                height: 90
                                radius: 12
                                color: themeItem.buttonBottomBackground
                                border.color: themeItem.buttonBorderBottomColor
                                border.width: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: themeItem.buttonTextColor
                                    font.pointSize: 44
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        var v = root.rates[key]
                                        if (v < 999) {
                                            var r = Object.assign({}, root.rates)
                                            r[key] = v + 1
                                            root.rates = r
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------- ДИЗАЙН ----------
            Column {
                visible: root.currentTab === 1
                width: parent.width
                spacing: 24

                Text {
                    text: "Дизайн интерфейса"
                    color: themeItem.secondaryTextColor
                    font.pointSize: 24
                    font.family: myFont.name
                }

                Row {
                    width: parent.width
                    spacing: 24

                    // Классический
                    Rectangle {
                        width: (parent.width - 24) / 2
                        height: 420
                        radius: 20
                        color: "#101820"
                        border.color: root.selDesign === "classic" ? "#00e3f2" : themeItem.buttonBorderTopColor
                        border.width: root.selDesign === "classic" ? 8 : 3

                        Column {
                            anchors.centerIn: parent
                            spacing: 20

                            Rectangle {
                                width: 260
                                height: 70
                                radius: 10
                                color: "#222a30"
                                border.color: "#00e3f2"
                                Text {
                                    anchors.centerIn: parent
                                    text: "AБВ"
                                    color: "#d3dce2"
                                    font.pointSize: 24
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "КЛАССИЧЕСКИЙ"
                                color: "#ffffff"
                                font.pointSize: 28
                                font.bold: true
                                font.family: myFont.name
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.selDesign === "classic" ? "✓ ВЫБРАН" : "нажмите, чтобы выбрать"
                                color: root.selDesign === "classic" ? "#00e3f2" : "#8b97a1"
                                font.pointSize: 20
                                font.family: myFont.name
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selDesign = "classic"
                        }
                    }

                    // С уткой
                    Rectangle {
                        width: (parent.width - 24) / 2
                        height: 420
                        radius: 20
                        color: "#eef7ff"
                        border.color: root.selDesign === "duck" ? "#ffb340" : themeItem.buttonBorderTopColor
                        border.width: root.selDesign === "duck" ? 8 : 3

                        Column {
                            anchors.centerIn: parent
                            spacing: 20

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: "qrc:duckIcon"
                                width: 180
                                height: 180
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "С УТКОЙ"
                                color: "#1d3557"
                                font.pointSize: 28
                                font.bold: true
                                font.family: myFont.name
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.selDesign === "duck" ? "✓ ВЫБРАН" : "нажмите, чтобы выбрать"
                                color: root.selDesign === "duck" ? "#e8930f" : "#6b7d8a"
                                font.pointSize: 20
                                font.family: myFont.name
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selDesign = "duck"
                        }
                    }
                }
            }

            // ---------- ПРОГРАММЫ ----------
            Column {
                visible: root.currentTab === 2
                width: parent.width
                spacing: 18

                Text {
                    text: "Какие программы показывать на экране мойки"
                    color: themeItem.secondaryTextColor
                    font.pointSize: 24
                    font.family: myFont.name
                }

                Repeater {
                    model: ListModel {
                        id: progModel
                        ListElement { key: "turbo"; label: "ТУРБО СУШКА" }
                        ListElement { key: "vacuum"; label: "ПЫЛЕСОС" }
                        ListElement { key: "chemistry"; label: "АКТИВНАЯ ХИМИЯ" }
                        ListElement { key: "wax"; label: "ВОСК" }
                        ListElement { key: "pink"; label: "ПЕНА РОЗОВАЯ" }
                        ListElement { key: "yellow"; label: "ПЕНА ЖЕЛТАЯ" }
                        ListElement { key: "white"; label: "ПЕНА БЕЛАЯ" }
                    }

                    delegate: Rectangle {
                        width: content.width
                        height: 120
                        radius: 14
                        color: themeItem.buttonTopBackground
                        border.color: themeItem.buttonBorderTopColor
                        border.width: 2

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 28
                            text: label
                            color: themeItem.buttonTextColor
                            font.pointSize: 28
                            font.family: myFont.name
                        }

                        // Переключатель
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 28
                            width: 150
                            height: 80
                            radius: 40
                            color: getOn() ? "#3fce6a" : themeItem.buttonBottomBackground
                            border.color: themeItem.buttonBorderTopColor
                            border.width: 2

                            function getOn() {
                                if (key === "turbo") return root.progTurboV
                                if (key === "vacuum") return root.progVacuumV
                                if (key === "chemistry") return root.progChemistryV
                                if (key === "wax") return root.progWaxV
                                if (key === "pink") return root.progPinkV
                                if (key === "yellow") return root.progYellowV
                                return root.progWhiteV
                            }

                            Rectangle {
                                width: 64
                                height: 64
                                radius: 32
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.getOn() ? parent.right : parent.left
                                anchors.leftMargin: parent.getOn() ? -72 : 8
                                color: "#ffffff"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var nv = !parent.getOn()
                                    if (key === "turbo") root.progTurboV = nv
                                    else if (key === "vacuum") root.progVacuumV = nv
                                    else if (key === "chemistry") root.progChemistryV = nv
                                    else if (key === "wax") root.progWaxV = nv
                                    else if (key === "pink") root.progPinkV = nv
                                    else if (key === "yellow") root.progYellowV = nv
                                    else root.progWhiteV = nv
                                }
                            }
                        }
                    }
                }
            }

            // ---------- ПЛАТЕЖИ ----------
            Column {
                visible: root.currentTab === 3
                width: parent.width
                spacing: 18

                Text {
                    text: "Способы оплаты для клиентов"
                    color: themeItem.secondaryTextColor
                    font.pointSize: 24
                    font.family: myFont.name
                }

                Repeater {
                    model: ListModel {
                        id: payModel
                        ListElement { key: "cash"; label: "НАЛИЧНЫЕ" }
                        ListElement { key: "sbp"; label: "СБП (QR-КОД)" }
                        ListElement { key: "card"; label: "БАНКОВСКАЯ КАРТА" }
                    }

                    delegate: Rectangle {
                        width: content.width
                        height: 130
                        radius: 14
                        color: themeItem.buttonTopBackground
                        border.color: themeItem.buttonBorderTopColor
                        border.width: 2

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 28
                            text: label
                            color: themeItem.buttonTextColor
                            font.pointSize: 28
                            font.family: myFont.name
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 28
                            width: 150
                            height: 80
                            radius: 40
                            color: getOn() ? "#3fce6a" : themeItem.buttonBottomBackground
                            border.color: themeItem.buttonBorderTopColor
                            border.width: 2

                            function getOn() {
                                if (key === "cash") return root.payCashV
                                if (key === "sbp") return root.paySbpV
                                return root.payCardV
                            }

                            Rectangle {
                                width: 64
                                height: 64
                                radius: 32
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.getOn() ? parent.right : parent.left
                                anchors.leftMargin: parent.getOn() ? -72 : 8
                                color: "#ffffff"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var nv = !parent.getOn()
                                    if (key === "cash") root.payCashV = nv
                                    else if (key === "sbp") root.paySbpV = nv
                                    else root.payCardV = nv
                                }
                            }
                        }
                    }
                }
            }
        }

        // === СОХРАНИТЬ ===
        ProgramButton {
            id: saveBtn
            text: "СОХРАНИТЬ"
            centerText: true
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 30
            anchors.rightMargin: 30
            anchors.bottomMargin: 30
            height: 130
            prog_name.font.pointSize: 42

            onButtonClicked: root.saveAll()
        }
    }

    // === Toast ===
    Item {
        id: errorContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 160
        height: 80
        z: 999

        Rectangle {
            id: errorToast
            width: parent.width - (parent.width / 15) * 2
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            color: isErr ? Qt.rgba(1, 0, 0, 0.5) : Qt.rgba(0, 1, 0, 0.5)
            radius: 10
            opacity: 0
            visible: false
            property bool isErr: true

            Text {
                id: toastText
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 30
                font.bold: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            Timer {
                id: hideTimer
                interval: 3000
                running: false
                repeat: false
                onTriggered: {
                    errorToast.opacity = 0
                    hideTimer.running = false
                    errorToast.visible = false
                }
            }
        }
    }
}
