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

    function clearFields() {
        container.phoneRawData = ""
        passwordField.text = ""
        container.updatePhoneField()
        phoneField.focus = false
        passwordField.focus = false
    }

    function showErrorToast(isErr, text) {
        if (hideTimer.running) {
            hideTimer.stop()
            errorToast.opacity = 0
        }

        errorText.text = text
        errorToast.isErr = isErr
        errorToast.visible = true
        errorToast.opacity = 1
        hideTimer.start()
    }

    Rectangle {
        id: container
        width: Constants.width
        height: Constants.height
        color: themeItem.appBackground

        readonly property string mask_phone: "+7 (___) ___-__-__"
        property string phoneRawData: "" // только цифры без маски

        function applyMask(raw) {
            var result = ""
            var rawIndex = 0
            for (var i = 0; i < mask_phone.length; i++) {
                if (mask_phone[i] === '_') {
                    if (rawIndex < raw.length) {
                        result += raw[rawIndex]
                        rawIndex++
                    } else {
                        result += '_'
                    }
                } else {
                    result += mask_phone[i]
                }
            }
            return result
        }

        function updatePhoneField() {
            phoneField.text = applyMask(container.phoneRawData)
        }

        CustomKeyboard {
            id: keyboard
            anchors.top: register_back_btn.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Constants.res1920_1080 ? 200 : 20
            width: parent.width - 20
            height: 430
        }

        Connections {
            target: keyboard
            function onKeyPressed(key) {
                var activeInput = phoneField.activeFocus ? phoneField : passwordField.activeFocus ? passwordField : null

                if (!activeInput)
                    return

                if (key === "back") {
                    if (activeInput === phoneField
                            && container.phoneRawData.length > 0) {
                        // Удаляем последнюю цифру
                        container.phoneRawData = container.phoneRawData.slice(
                                    0, container.phoneRawData.length - 1)
                        container.updatePhoneField()
                        phoneField.cursorPosition = phoneField.text.lastIndexOf(
                                    '_')
                    } else if (activeInput !== phoneField
                               && activeInput.cursorPosition > 0) {
                        activeInput.remove(activeInput.cursorPosition - 1,
                                           activeInput.cursorPosition)
                    }
                } else if (activeInput === phoneField) {
                    if (/\d/.test(key) && container.phoneRawData.length < 10) {
                        // 11 цифр для номера
                        container.phoneRawData += key
                        container.updatePhoneField()
                        // Ставим курсор на первую '_'
                        phoneField.cursorPosition = phoneField.text.indexOf('_')
                        if (phoneField.cursorPosition === -1)
                            phoneField.cursorPosition = phoneField.text.length
                    }
                } else if (activeInput === passwordField) {
                    if (activeInput.text.length < 4) {
                        activeInput.insert(activeInput.cursorPosition, key)
                        activeInput.cursorPosition++
                    }
                } else {
                    // Для обычного TextField
                    activeInput.insert(activeInput.cursorPosition, key)
                    activeInput.cursorPosition++
                }
            }
        }

        Item {
            id: errorContainer
            anchors.top: register_back_btn.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 20
            height: 80
            z: 999

            Rectangle {
                id: errorToast
                width: parent.width - (parent.width / 15) * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height

                // Цвет зависит от isErr
                color: isErr ? Qt.rgba(1, 0, 0, 0.5) // красный
                             : Qt.rgba(0, 1, 0, 0.5) // зелёный

                radius: 10
                opacity: 0
                visible: false

                property bool isErr: true // по умолчанию ошибка (красный)

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

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
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

        // Кнопка Назад
        ProgramButton {
            id: register_back_btn
            text: "Назад"
            width: 240
            height: 100
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 20
            anchors.rightMargin: 20
            prog_name.font.pointSize: 38

            onButtonClicked: {
                keyboard.visible = false
                backend.showLogin() // вернуться на страницу входа
            }
        }

        Column {
            spacing: 30
            width: parent.width * 8 / 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: keyboard.bottom
            anchors.topMargin: Constants.res1920_1080 ? 150 : 10

            // Заголовок
            Text {
                text: "Регистрация"
                color: themeItem.textColor // ← из темы
                font.pointSize: 38
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            TextField {
                id: phoneField
                placeholderText: "+7 (___) ___-__-__"
                font.pointSize: 32
                width: parent.width
                text: container.applyMask(container.phoneRawData)
                readOnly: true
                inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhFormattedNumbersOnly
                color: themeItem.textColor // ← из темы
                placeholderTextColor: themeItem.secondaryTextColor
                onActiveFocusChanged: {
                    Qt.inputMethod.hide()
                    if (activeFocus) {
                        keyboard.visible = true
                    } else if (!passwordField.activeFocus) {
                        keyboard.visible = false
                    }
                }
            }

            TextField {
                id: passwordField
                placeholderText: "4-значный пароль"
                echoMode: TextInput.Password
                font.pointSize: 32
                readOnly: true
                width: parent.width
                color: themeItem.textColor // ← из темы
                placeholderTextColor: themeItem.secondaryTextColor
                onActiveFocusChanged: {
                    Qt.inputMethod.hide()
                    if (activeFocus) {
                        keyboard.visible = true
                    } else if (!phoneField.activeFocus) {
                        keyboard.visible = false
                    }
                }
            }

            // Кнопка "Зарегистрироваться"
            ProgramButton {
                text: "Зарегистрироваться"
                width: parent.width
                height: 100
                prog_name.font.pointSize: 38
                onButtonClicked: {
                    if (container.phoneRawData.length < 10) {
                        showErrorToast(true, "Введите полный номер телефона")
                        return
                    }

                    if (passwordField.text.length !== 4) {
                        showErrorToast(true, "Пароль должен быть 4-значным")
                        return
                    }

                    backend.tryRegister("+7" + container.phoneRawData,
                                        passwordField.text)
                }
            }
        }
    }
}
