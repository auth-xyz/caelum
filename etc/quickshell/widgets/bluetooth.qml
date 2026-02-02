import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

import ".."

ShellRoot {
    id: root

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"

    FloatingWindow {
        id: bluetoothPanel
        visible: true
        title: "qsbt"
       
        color: "transparent"
        screen: Quickshell.screens[0]
        
        // Center on screen
        Component.onCompleted: {
            if (screen) {
                var screenGeometry = screen.geometry
                x = (screenGeometry.width - width) / 2
                y = (screenGeometry.height - height) / 2
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.colBg
            opacity: 0.98
            radius: 12
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0

                // Scrollable device list
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Flickable {
                        id: flickable
                        anchors.fill: parent
                        anchors.rightMargin: 12
                        contentHeight: deviceColumn.height
                        boundsBehavior: Flickable.StopAtBounds
                        
                        ColumnLayout {
                            id: deviceColumn
                            width: parent.width
                            spacing: 10

                            // Connected devices section
                            Text {
                                text: "Connected Devices"
                                color: Theme.colCyan
                                font.pixelSize: 18
                                font.family: root.fontFamily
                                font.bold: true
                                visible: connectedRepeater.count > 0
                                Layout.topMargin: 5
                            }

                            Repeater {
                                id: connectedRepeater
                                model: Bluetooth.devices.values.filter(dev => dev.connected)

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    color: "transparent"
                                    radius: 5
                                    border.color: Theme.colGreen
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        spacing: 15

                                        // Device icon based on type
                                        Text {
                                            text: {
                                                if (modelData.icon === "audio-headset" || modelData.icon === "audio-headphones") return Theme.btHeadset
                                                if (modelData.icon === "input-gaming") return Theme.btController
                                                if (modelData.icon === "input-keyboard") return Theme.btKeyboard
                                                if (modelData.icon === "input-mouse") return Theme.btController
                                                if (modelData.icon === "phone" || modelData.icon === "phone-apple-iphone") return ""
                                                if (modelData.icon === "computer" || modelData.icon === "computer-laptop") return ""
                                                return ""
                                            }
                                            color: Theme.colGreen
                                            font.pixelSize: 32
                                            font.family: root.fontFamily
                                            Layout.preferredWidth: 40
                                        }

                                        // Device info
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 5

                                            // Name and battery on same line
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 10

                                                Text {
                                                    text: modelData.name || modelData.address
                                                    color: Theme.colFg
                                                    font.pixelSize: 16
                                                    font.family: root.fontFamily
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                // Battery indicator (if available)
                                                RowLayout {
                                                    spacing: 5
                                                    visible: modelData.batteryAvailable
                                                    
                                                    property real batteryPercent: modelData.battery * 100
                                                    
                                                    Text {
                                                        text: {
                                                            if (parent.batteryPercent >= 75) return Theme.batteryFull
                                                            if (parent.batteryPercent >= 25) return Theme.batteryHalf
                                                            return Theme.batteryCritical
                                                        }
                                                        color: {
                                                            if (parent.batteryPercent >= 75) return Theme.colGreen
                                                            if (parent.batteryPercent >= 25) return Theme.colYellow
                                                            return Theme.colRed
                                                        }
                                                        font.pixelSize: 16
                                                        font.family: root.fontFamily
                                                    }
                                                    
                                                    Text {
                                                        text: Math.round(parent.batteryPercent) + "%"
                                                        color: {
                                                            if (parent.batteryPercent >= 75) return Theme.colGreen
                                                            if (parent.batteryPercent >= 25) return Theme.colYellow
                                                            return Theme.colRed
                                                        }
                                                        font.pixelSize: 12
                                                        font.family: root.fontFamily
                                                        font.bold: true
                                                    }
                                                }
                                            }

                                            Text {
                                                text: modelData.address + " • " + (modelData.paired ? "Paired" : "Not paired")
                                                color: Theme.colMuted
                                                font.pixelSize: 12
                                                font.family: root.fontFamily
                                            }
                                        }

                                        // Disconnect button
                                        Rectangle {
                                            Layout.preferredWidth: 100
                                            Layout.preferredHeight: 35
                                            color: disconnectMouseArea.containsMouse ? Theme.colRed : "transparent"
                                            radius: 6
                                            border.color: Theme.colRed
                                            border.width: 1

                                            Text {
                                                text: "Disconnect"
                                                color: disconnectMouseArea.containsMouse ? Theme.colBg : Theme.colRed
                                                font.pixelSize: 12
                                                font.family: root.fontFamily
                                                font.bold: true
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                id: disconnectMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: modelData.connected = false
                                            }
                                        }
                                    }
                                }
                            }

                            // Available devices section
                            Text {
                                text: "Available Devices"
                                color: Theme.colCyan
                                font.pixelSize: 18
                                font.family: root.fontFamily
                                font.bold: true
                                visible: availableRepeater.count > 0
                                Layout.topMargin: connectedRepeater.count > 0 ? 15 : 5
                            }

                            Repeater {
                                id: availableRepeater
                                model: Bluetooth.devices.values.filter(dev => !dev.connected)

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    color: deviceMouseArea.containsMouse ? Theme.colMuted : "transparent"
                                    opacity: deviceMouseArea.containsMouse ? 0.5 : 0.3
                                    radius: 5
                                    border.color: modelData.paired ? Theme.colCyan : Theme.colMuted
                                    border.width: 1

                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        spacing: 15

                                        // Device icon based on type
                                        Text {
                                            text: {
                                                if (modelData.icon === "audio-headset" || modelData.icon === "audio-headphones") return Theme.btHeadset
                                                if (modelData.icon === "input-gaming") return Theme.btController
                                                if (modelData.icon === "input-keyboard") return Theme.btKeyboard
                                                if (modelData.icon === "input-mouse") return Theme.btController
                                                if (modelData.icon === "phone" || modelData.icon === "phone-apple-iphone") return ""
                                                if (modelData.icon === "computer" || modelData.icon === "computer-laptop") return ""
                                                return ""
                                            }
                                            color: Theme.colCyan
                                            font.pixelSize: 32
                                            font.family: root.fontFamily
                                            Layout.preferredWidth: 35
                                        }

                                        // Device info
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 5

                                            Text {
                                                text: modelData.name || modelData.address
                                                color: Theme.colFg
                                                font.pixelSize: 16
                                                font.family: root.fontFamily
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            RowLayout {
                                                spacing: 10

                                                Text {
                                                    text: modelData.address
                                                    color: Theme.colMuted
                                                    font.pixelSize: 12
                                                    font.family: root.fontFamily
                                                }

                                                Text {
                                                    text: modelData.paired ? "• Paired" : ""
                                                    color: Theme.colCyan
                                                    font.pixelSize: 12
                                                    font.family: root.fontFamily
                                                    visible: modelData.paired
                                                }
                                            }
                                        }

                                        // Connect/Pair button
                                        Rectangle {
                                            Layout.preferredWidth: 80
                                            Layout.preferredHeight: 35
                                            color: actionMouseArea.containsMouse ? Theme.colCyan : "transparent"
                                            radius: 6
                                            border.color: Theme.colCyan
                                            border.width: 1

                                            Text {
                                                text: modelData.paired ? "Connect" : "Pair"
                                                color: actionMouseArea.containsMouse ? Theme.colBg : Theme.colCyan
                                                font.pixelSize: 12
                                                font.family: root.fontFamily
                                                font.bold: true
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                id: actionMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    if (modelData.paired) {
                                                        modelData.connected = true
                                                    } else {
                                                        modelData.paired = true
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: deviceMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        z: -1
                                    }
                                }
                            }

                            // Empty state
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: Bluetooth.devices.values.length === 0

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 15

                                    Text {
                                        text: ""
                                        color: Theme.colMuted
                                        font.pixelSize: 64
                                        font.family: root.fontFamily
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: Bluetooth.enabled ? 
                                              "No devices found" :
                                              "Bluetooth is disabled"
                                        color: Theme.colMuted
                                        font.pixelSize: 18
                                        font.family: root.fontFamily
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: Bluetooth.enabled ?
                                              "Click the  icon to scan for devices" :
                                              "Click ON to enable Bluetooth"
                                        color: Theme.colMuted
                                        font.pixelSize: 14
                                        font.family: root.fontFamily
                                        font.italic: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }
                    }

                    // Custom scrollbar
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 8
                        color: Theme.colMuted
                        opacity: 0.3
                        radius: 4
                        visible: flickable.contentHeight > flickable.height

                        Rectangle {
                            id: scrollThumb
                            width: parent.width
                            height: Math.max(30, (flickable.height / flickable.contentHeight) * parent.height)
                            y: (flickable.contentY / flickable.contentHeight) * parent.height
                            color: Theme.colCyan
                            radius: 4
                            opacity: scrollMouseArea.containsMouse || scrollMouseArea.pressed ? 0.8 : 0.5

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }

                            MouseArea {
                                id: scrollMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                
                                property real pressY: 0
                                property real pressContentY: 0
                                
                                onPressed: mouse => {
                                    pressY = mouse.y
                                    pressContentY = flickable.contentY
                                }
                                
                                onPositionChanged: mouse => {
                                    if (pressed) {
                                        var delta = mouse.y - pressY
                                        var contentDelta = delta * (flickable.contentHeight / flickable.height)
                                        flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, pressContentY + contentDelta))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
