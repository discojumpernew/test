import QtQuick 2.12
import IPS4MCO 1.0

QtObject {
    id: theme

    // false = светлая, true = тёмная
    property bool dark: true

    // === ФОН ПРИЛОЖЕНИЯ ===
    readonly property color appBackground: dark ? "#060a0d" // тёмная
                                                : "#e8edf1" // светлая

    // === ФОН КНОПОК ===
    readonly property color buttonTopBackground: dark ? "#222a30" : "#f8fafb"
    readonly property color buttonBottomBackground: dark ? "#0c1115" : "#d9e1e7"

    readonly property color buttonTopColor: buttonTopBackground
    readonly property color buttonBottomColor: buttonBottomBackground

    // === РАМКА КНОПОК (градиент) ===
    readonly property color buttonBorderTopColor: dark ? "#39434b" : "#f0f4f6"
    readonly property color buttonBorderBottomColor: dark ? "#00e3f2" : "#64eef9"

    // === ПОЛОСКИ ===
    readonly property color lineColor: dark ? "#7bdafa" : "#74ccf6"

    // === ТЕКСТ "Self Service" ===
    readonly property color titleColor: dark ? "#ffffff" : "#0a0a0a"

    // === ОБЫЧНЫЙ ТЕКСТ ===
    readonly property color textColor: dark ? "#c3ccd4" : "#16181a"

    // === ТЕКСТ НА КНОПКАХ ===
    readonly property color buttonTextColor: dark ? "#d3dce2" : "#16181a"

    // === АКЦЕНТ (баланс, время) ===
    readonly property color accentColor: dark ? "#ffffff" : "#0a0a0a"

    // === ВТОРИЧНЫЙ ТЕКСТ ===
    readonly property color secondaryTextColor: dark ? "#8b97a1" : "#555555"

    // === АКТИВНАЯ (нажатая) КНОПКА — цвета из ПРОТИВОПОЛОЖНОЙ темы ===
    // Тёмная тема: активная кнопка светлая
    // Светлая тема: активная кнопка тёмная
    readonly property color buttonActiveTop: dark ? "#f8fafb" // как buttonTopBackground светлой
                                                  : "#222a30" // как buttonTopBackground тёмной
    readonly property color buttonActiveBottom: dark ? "#d9e1e7" // как buttonBottomBackground светлой
                                                     : "#0c1115" // как buttonBottomBackground тёмной

    // Текст на активной кнопке — контрастный к её фону
    readonly property color buttonActiveTextColor: dark ? "#0a0a0a" // на светлой кнопке — чёрный
                                                        : "#d3dce2" // на тёмной кнопке — светлый

    // Рамка активной кнопки — тоже из противоположной темы
    readonly property color buttonActiveBorderTop: dark ? "#f0f4f6" // как в светлой теме
                                                        : "#39434b" // как в тёмной теме
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
