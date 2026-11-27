import QtQuick 2.15
import IPS4MCO 1.0

QtObject {
    id: theme

    // false = светлая, true = тёмная
    property bool dark: true

    // Дизайн интерфейса: "classic" (старый) | "duck" (новый, с уткой).
    // Приходит из админ-панели (backend.designTheme), применяется на лету.
    readonly property string design: (typeof backend !== "undefined" && backend.designTheme !== undefined) ? backend.designTheme : "classic"
    readonly property bool isDuck: design === "duck"

    // === ФОН ПРИЛОЖЕНИЯ ===
    readonly property color appBackground: dark ? "#060a0d" // тёмная
                                                : (isDuck ? "#eef7ff" : "#e8edf1")

    // === ФОН КНОПОК ===
    readonly property color buttonTopBackground: dark ? "#222a30"
                                                      : (isDuck ? "#fffdf5" : "#f8fafb")
    readonly property color buttonBottomBackground: dark ? "#0c1115"
                                                         : (isDuck ? "#f6ecd2" : "#d9e1e7")

    readonly property color buttonTopColor: buttonTopBackground
    readonly property color buttonBottomColor: buttonBottomBackground

    // === РАМКА КНОПОК (градиент) ===
    readonly property color buttonBorderTopColor: dark ? "#39434b"
                                                       : (isDuck ? "#ffe9a8" : "#f0f4f6")
    readonly property color buttonBorderBottomColor: dark ? "#00e3f2"
                                                          : (isDuck ? "#ffb340" : "#64eef9")

    // === ПОЛОСКИ ===
    readonly property color lineColor: dark ? "#7bdafa"
                                            : (isDuck ? "#ffb340" : "#74ccf6")

    // === ТЕКСТ "Self Service" ===
    readonly property color titleColor: dark ? "#ffffff"
                                             : (isDuck ? "#1d3557" : "#0a0a0a")

    // === ОБЫЧНЫЙ ТЕКСТ ===
    readonly property color textColor: dark ? "#c3ccd4"
                                            : (isDuck ? "#243b4a" : "#16181a")

    // === ТЕКСТ НА КНОПКАХ ===
    readonly property color buttonTextColor: dark ? "#d3dce2"
                                                  : (isDuck ? "#243b4a" : "#16181a")

    // === АКЦЕНТ (баланс, время) ===
    readonly property color accentColor: dark ? "#ffffff"
                                              : (isDuck ? "#1d3557" : "#0a0a0a")

    // === ВТОРИЧНЫЙ ТЕКСТ ===
    readonly property color secondaryTextColor: dark ? "#8b97a1"
                                                     : (isDuck ? "#6b7d8a" : "#555555")

    // === АКТИВНАЯ (нажатая) КНОПКА ===
    // classic светлая — активная кнопка тёмная (как в тёмной теме);
    // тёмная и duck — активная кнопка светлая (в duck — жёлтый акцент).
    readonly property color buttonActiveTop: (!dark && !isDuck) ? "#222a30"
                                              : (isDuck ? "#ffd66b" : "#f8fafb")
    readonly property color buttonActiveBottom: (!dark && !isDuck) ? "#0c1115"
                                                 : (isDuck ? "#ffb340" : "#d9e1e7")

    // Текст на активной кнопке — контрастный к её фону
    readonly property color buttonActiveTextColor: (!dark && !isDuck) ? "#d3dce2"
                                                   : (isDuck ? "#3a2c00" : "#0a0a0a")

    // Рамка активной кнопки
    readonly property color buttonActiveBorderTop: (!dark && !isDuck) ? "#39434b"
                                                   : (isDuck ? "#ffe9a8" : "#f0f4f6")
    readonly property color buttonActiveBorderBottom: (!dark && !isDuck) ? "#00e3f2"
                                                      : (isDuck ? "#e8930f" : "#64eef9")

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
