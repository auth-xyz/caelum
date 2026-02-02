pragma Singleton 

import QtQuick

QtObject {
    readonly property color colBg: "#13151c"
    readonly property color colFg: "#a8b0c8"
    readonly property color colMuted: "#444b6a"
    readonly property color colCyan: "#0db9d7"
    readonly property color colPurple: "#ad8ee6"
    readonly property color colRed: "#f7768e"
    readonly property color colYellow: "#e0b87d"
    readonly property color colOrange: "#d4825c"
    readonly property color colBlue: "#7aa2f7"
    readonly property color colGreen: "#9ece6a"

    // Icons
    readonly property string cpuIcon: ""
    readonly property string memIcon: ""
    readonly property string diskIcon: ""

    readonly property string volMax: ""
    readonly property string volMin: ""
    readonly property string volMute: ""

    readonly property string batteryFull: ""
    readonly property string batteryHalf: ""
    readonly property string batteryCritical: ""

    // For bluetooth but :shrug:
    readonly property string btKeyboard: "󰌌"
    readonly property string btMouse: "󰍽"
    readonly property string btHeadset: ""
    readonly property string btController: "󰊴"
    readonly property string btGui: ""

}
