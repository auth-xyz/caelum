import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import ".."

ShellRoot {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font Propo"
    property string screenName: ""

    signal closeRequested()
    signal actionRequested(string action)

    function selectedScreen() {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === screenName) {
                return Quickshell.screens[i]
            }
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    FloatingWindow {
        id: powerMenu
        visible: true
        title: "qspower"
        color: "transparent"
        screen: root.selectedScreen()

        function positionWindow() {
            if (!screen || !screen.geometry) return
            var screenGeometry = screen.geometry
            x = screenGeometry.width - width - 8
            y = 43
        }

        Component.onCompleted: positionWindow()
        onVisibleChanged: if (visible) positionWindow()
        onScreenChanged: positionWindow()

        Rectangle {
            anchors.fill: parent
            color: Colors.colBg
            opacity: 0.98
            radius: 4
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Repeater {
                    model: [
                        { action: "lock", icon: "", label: "Lock", accent: Colors.colBlue },
                        { action: "logout", icon: "󰗼", label: "Logout", accent: Colors.colOrange },
                        { action: "suspend", icon: "", label: "Suspend", accent: Colors.colPurple },
                        { action: "reboot", icon: "", label: "Reboot", accent: Colors.colYellow },
                        { action: "poweroff", icon: "", label: "Poweroff", accent: Colors.colRed }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: powerActionMouse.containsMouse ? modelData.accent : "transparent"
                        radius: 5

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: modelData.icon
                                color: powerActionMouse.containsMouse ? Colors.colBg : modelData.accent
                                font.pixelSize: 24
                                font.family: root.fontFamily
                                Layout.alignment: Qt.AlignHCenter

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            Text {
                                text: modelData.label
                                color: powerActionMouse.containsMouse ? Colors.colBg : Colors.colFg
                                font.pixelSize: 14
                                font.family: root.fontFamily
                                font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignHCenter

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }

                        MouseArea {
                            id: powerActionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.actionRequested(modelData.action)
                        }
                    }
                }
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: powerMenu.visible

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.closeRequested()
                    event.accepted = true
                }
            }
        }
    }
}
