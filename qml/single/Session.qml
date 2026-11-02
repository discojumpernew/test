import QtQuick 2.4
import QtQuick.Controls 2.5
import IPS4MCO 1.0

SessionForm {
    id: form
    readonly property int cbtn1_msk: 0x1
    readonly property int cbtn2_msk: 0x2
    readonly property int cbtn3_msk: 0x4
    readonly property int cbtn4_msk: 0x8
    readonly property int cbtn5_msk: 0xC
    readonly property int cbtn6_msk: 0x10
    readonly property int cbtn7_msk: 0x20
    readonly property int cbtn8_msk: 0x40
    readonly property int cbtn9_msk: 0x100
    readonly property int cbtn10_msk: 0x200
    readonly property int cbtn_pause_msk: 0x80
    signal resetButtons

    onResetButtons: {
        btn1.checked = false
        btn2.checked = false
        btn3.checked = false
        btn4.checked = false
        btn5.checked = false
        btn6.checked = false
        btn7.checked = false
        btn8.checked = false
        btn9.checked = false
        btn10.checked = false
        pause_btn.checked = true

        // Сброс подсветки на сервисных кнопках
        login_btn.checked = false
        price_btn.checked = false
        instruction_btn.checked = false
    }

    function clikedButton(current_button) {
        if (isWaiting) {
            pause_btn.checked = true
            return
        }

        var lpressedbuttons = current_button

        btn1.checked = current_button === cbtn1_msk
        btn2.checked = current_button === cbtn2_msk
        btn3.checked = current_button === cbtn3_msk
        btn4.checked = current_button === cbtn4_msk
        btn5.checked = current_button === cbtn5_msk
        btn6.checked = current_button === cbtn6_msk
        btn7.checked = current_button === cbtn7_msk
        btn8.checked = current_button === cbtn8_msk
        btn9.checked = current_button === cbtn9_msk
        btn10.checked = current_button === cbtn10_msk
        pause_btn.checked = current_button === cbtn_pause_msk

        // Сервисные кнопки гасим всегда, когда кликнули на другую
        login_btn.checked = false
        price_btn.checked = false
        instruction_btn.checked = false

        window.qmlSetButtons(lpressedbuttons)
    }

    btn1.onButtonClicked: {
        clikedButton(cbtn1_msk)
    }
    btn2.onButtonClicked: {
        clikedButton(cbtn2_msk)
    }
    btn3.onButtonClicked: {
        clikedButton(cbtn3_msk)
    }
    btn4.onButtonClicked: {
        clikedButton(cbtn4_msk)
    }
    btn5.onButtonClicked: {
        clikedButton(cbtn5_msk)
    }
    btn6.onButtonClicked: {
        clikedButton(cbtn6_msk)
    }
    btn7.onButtonClicked: {
        clikedButton(cbtn7_msk)
    }
    btn8.onButtonClicked: {
        clikedButton(cbtn8_msk)
    }
    btn9.onButtonClicked: {
        clikedButton(cbtn9_msk)
    }
    btn10.onButtonClicked: {
        clikedButton(cbtn10_msk)
    }

    pause_btn.onButtonClicked: {
        clikedButton(cbtn_pause_msk)
    }

    login_btn.onButtonClicked: {
        clikedButton(cbtn_pause_msk)
        login_btn.checked = true
        price_btn.checked = false
        instruction_btn.checked = false
        if (!backend.hasCurrentUser) {
            backend.showLogin()
        } else {
            backend.logout()
        }
    }

    instruction_btn.onButtonClicked: {
        clikedButton(cbtn_pause_msk)
        instruction_btn.checked = true
        login_btn.checked = false
        price_btn.checked = false
        backend.showInstruction()
    }

    price_btn.onButtonClicked: {
        price_btn.checked = true
        login_btn.checked = false
        instruction_btn.checked = false
        backend.showPriceList()
    }

    histroy_btn.onButtonClicked: {
        clikedButton(cbtn_pause_msk)
        backend.requestHistory()
    }

    hideTimer.onTriggered: {
        errorToast.opacity = 0
        hideTimer.running = false
        errorToast.visible = false
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 300
        }
    }

    balance.onButtonClicked: {
        clikedButton(cbtn_pause_msk)
        backend.showPSection()
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

    Connections {
        target: backend

        function onSetUIConfig(config) {
            // Ряд 2: турбо сушка, пылесос
            // btn1.text = config["ProgramName1"] // ТУРБО СУШКА
            // btn2.text = config["ProgramName2"] // ПЫЛЕСОС
            // // btn3/4/5 — давление (текст "140/170/210 БАР" задан хардкодом в layout)

            // // Ряд 1: пены (все три используют ProgramName7)
            // // btn6.text = config["ProgramName7"] // ПЕНА
            // // btn7.text = config["ProgramName7"] // ПЕНА
            // // btn8.text = config["ProgramName7"] // ПЕНА

            // // Ряд 2 (продолжение)
            // btn9.text = config["ProgramName6"] // АКТИВНАЯ ХИМИЯ
            // btn10.text = config["ProgramName8"] // ПОЛИРУЮЩИЙ ВОСК
        }

        function onCurrentUserChanged(isErr, message) {
            if (!backend.hasCurrentUser)
                showErrorToast(false, "Совершен выход из аккаунта.")
            else {
                showErrorToast(false, "Совершен вход в аккаунт.")
            }
        }

        function onSetPressedButtons(button) {
            btn1.checked = button === cbtn1_msk
            btn2.checked = button === cbtn2_msk
            btn3.checked = button === cbtn3_msk
            btn4.checked = button === cbtn4_msk
            btn5.checked = button === cbtn5_msk
            btn6.checked = button === cbtn6_msk
            btn7.checked = button === cbtn7_msk
            btn8.checked = button === cbtn8_msk
            btn9.checked = button === cbtn9_msk
            btn10.checked = button === cbtn10_msk
            pause_btn.checked = button === cbtn_pause_msk
        }

        function onShowSession(state) {
            clikedButton(cbtn_pause_msk)
            login_btn.checked = false
            price_btn.checked = false
            instruction_btn.checked = false
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/

