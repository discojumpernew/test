pragma Singleton

import QtQuick 2.4

QtObject {
    readonly property int header_height: 200
    readonly property int footer_height: 150
    readonly property int width: 1080
    readonly property bool res1920_1080: true
    readonly property int height: res1920_1080 ? 1920 : 1024
    readonly property string text_color: '#fff'

    readonly property int initialization: 0
    readonly property int error: 1
    readonly property int session: 2
    readonly property int login: 3
    readonly property int register: 4
    readonly property int psection: 5
    readonly property int history: 6
    readonly property int cash: 7
    readonly property int priceList: 8
    readonly property int sbp: 9
    readonly property int instruction: 10
    readonly property int card: 11
    readonly property int idsetup: 12
    readonly property int blocked: 13
}
