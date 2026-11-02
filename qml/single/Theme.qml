import QtQuick 2.12
import IPS4MCO 1.0

QtObject {
    id: theme

    // false = светлая, true = тёмная
    property bool dark: true

    // === ФОН ПРИЛОЖЕНИЯ ===
    readonly property color appBackground: dark ? "#000000" // тёмная
                                                : "#e6ebf2" // светлая

    // === ФОН КНОПОК ===
    readonly property color buttonTopBackground: dark ? "#5d7281" : "#eff5f8"
    readonly property color buttonBottomBackground: dark ? "#0a141b" : "#9aafbe"

    readonly property color buttonTopColor: buttonTopBackground
    readonly property color buttonBottomColor: buttonBottomBackground

    // === РАМКА КНОПОК (градиент) ===
    readonly property color buttonBorderTopColor: dark ? "#738490" : "#e2e8ec"
    readonly property color buttonBorderBottomColor: dark ? "#00e3f2" : "#64eef9"

    // === ПОЛОСКИ ===
    readonly property color lineColor: dark ? "#7bdafa" : "#74ccf6"

    // === ТЕКСТ "Self Service" ===
    readonly property color titleColor: dark ? "#ffffff" : "#000000"

    // === ОБЫЧНЫЙ ТЕКСТ ===
    readonly property color textColor: dark ? "#acb6c0" : "#000000"

    // === ТЕКСТ НА КНОПКАХ ===
    readonly property color buttonTextColor: dark ? "#acb6c0" : "#000000"

    // === АКЦЕНТ (баланс, время) ===
    readonly property color accentColor: dark ? "#acb6c0" : "#000000"

    // === ВТОРИЧНЫЙ ТЕКСТ ===
    readonly property color secondaryTextColor: dark ? "#acb6c0" : "#555555"

    // === АКТИВНАЯ (нажатая) КНОПКА — цвета из ПРОТИВОПОЛОЖНОЙ темы ===
    // Тёмная тема: активная кнопка светлая
    // Светлая тема: активная кнопка тёмная
    readonly property color buttonActiveTop: dark ? "#eff5f8" // как buttonTopBackground светлой
                                                  : "#5d7281" // как buttonTopBackground тёмной
    readonly property color buttonActiveBottom: dark ? "#9aafbe" // как buttonBottomBackground светлой
                                                     : "#0a141b" // как buttonBottomBackground тёмной

    // Текст на активной кнопке — контрастный к её фону
    readonly property color buttonActiveTextColor: dark ? "#000000" // на светлой кнопке — чёрный
                                                        : "#acb6c0" // на тёмной кнопке — светлый

    // Рамка активной кнопки — тоже из противоположной темы
    readonly property color buttonActiveBorderTop: dark ? "#e2e8ec" // как в светлой теме
                                                        : "#738490" // как в тёмной теме
    readonly property color buttonActiveBorderBottom: dark ? "#64eef9" : "#00e3f2"

    // === РАЗДЕЛИТЕЛИ ===
    readonly property color separatorColor: lineColor

    // === ШРИФТ ===
    readonly property string fontFamily: "Arial Narrow"
    readonly property int fontWeight: Font.Normal

    readonly property int fontSize: Constants.res1920_1080 ? 32 : 20
    readonly property int fontSizeSmall: Constants.res1920_1080 ? 24 : 20
    readonly property int fontSizeLarge: Constants.res1920_1080 ? 74 : 60

    function toggle() {
        dark = !dark
    }
}
