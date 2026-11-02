import QtQuick 2.4
import IPS4MCO 1.0

Item {
    property bool darkTheme: true
    Theme {
        id: themeItem
        dark: darkTheme
    }

    id: root

    FontLoader {
        id: myFont
        source: "qrc:/fonts/TerminatorGenisys.ttf"
    }

    Connections {
        target: backend
        function onSetUIConfig(config) {
            price1.box_price.text = config["cleanerRate"] + "₽"
            price2.box_price.text = config["dryingRate"] + "₽"
            price3.box_price.text = config["waterRate"] + "₽"
            price4.box_price.text = config["chemistryRate"] + "₽"
            price5.box_price.text = config["foamRate"] + "₽"
            price6.box_price.text = config["waxRate"] + "₽"
            price7.box_price.text = config["pauseRate"] + "₽"
        }
    }

    Rectangle {
        id: container
        width: Constants.width
        height: Constants.height
        color: themeItem.appBackground

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

        Text {
            id: price_list_title
            anchors.top: price_list_back.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            text: "ПРАЙС-ЛИСТ"
            color: themeItem.textColor
            font.pointSize: 44
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            font.family: myFont.name
        }

        Column {
            anchors.top: price_list_title.bottom
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 10

            Row {
                width: parent.width / 20 * 19
                height: parent.height / 3 - 10
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                PriceBox {
                    id: price1
                    height: parent.height
                    width: (parent.width - 10) / 2
                    box_name.text: "ПЫЛЕСОС"
                    padding_from_name: 60
                    backgroundImage: "qrc:vacuum"
                }
                PriceBox {
                    id: price2
                    height: parent.height
                    width: (parent.width - 10) / 2
                    box_name.text: "ТУРБО СУШКА"
                    padding_from_name: 60
                    backgroundImage: "qrc:turbo"
                }
            }

            Row {
                width: parent.width / 20 * 19
                height: parent.height / 3 - 10
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                PriceBox {
                    id: price3
                    height: parent.height
                    width: (parent.width - 10) / 2
                    box_name.text: "ВОДА"
                    padding_from_name: 60
                    backgroundImage: "qrc:water"
                }
                PriceBox {
                    id: price4
                    height: parent.height
                    width: (parent.width - 10) / 2
                    box_name.text: "АКТИВНАЯ ХИМИЯ"
                    padding_from_name: 60
                    backgroundImage: "qrc:chemistry"
                }
            }

            Row {
                width: parent.width / 20 * 19
                height: parent.height / 3 - 10
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                PriceBox {
                    id: price5
                    height: parent.height
                    width: (parent.width - 10 * 2) / 3
                    box_name.text: "ПЕНА"
                    padding_from_name: 20
                    backgroundImage: "qrc:foam"
                }
                PriceBox {
                    id: price6
                    height: parent.height
                    width: (parent.width - 10 * 2) / 3
                    box_name.text: "ВОСК"
                    padding_from_name: 20
                    backgroundImage: "qrc:wax"
                }
                PriceBox {
                    id: price7
                    height: parent.height
                    width: (parent.width - 10 * 2) / 3
                    box_name.text: "ПАУЗА"
                    padding_from_name: 20
                    backgroundImage: "qrc:pause"
                }
            }
        }
    }
}
