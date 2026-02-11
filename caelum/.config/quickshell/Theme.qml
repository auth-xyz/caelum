pragma Singleton 

import QtQuick

QtObject {
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


    // hey adding icons to the bar
    readonly property string windowActive: ""
    readonly property string windowEnabled: "󰔶" // couldn't think of another word
    readonly property string windowInactive: "󰔷"
    readonly property string multimediaIcon: "󰲸"
}
