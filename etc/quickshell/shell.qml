import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font Propo"
    property int fontSize: 16

    // System info properties
    property string kernelVersion: "Linux"
    property int cpuUsage: 0
    property int memUsage: 0
    property int diskUsage: 0
    property int volumeLevel: 0
    property string activeWindow: "Window"
    property bool bluetoothVisible: false

    // Spotify properties
    property string spotifyTrack: "No track"
    property string spotifyArtist: ""
    property string spotifyStatus: "Paused"

    // CPU tracking
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property int connectedCount: 0 

    // Bluetooth 
    Loader {
        id: bluetoothLoader
        active: bluetoothVisible
        source: "widgets/bluetooth.qml"
    }

    // CPU usage
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var user = parseInt(parts[1]) || 0
                var nice = parseInt(parts[2]) || 0
                var system = parseInt(parts[3]) || 0
                var idle = parseInt(parts[4]) || 0
                var iowait = parseInt(parts[5]) || 0
                var irq = parseInt(parts[6]) || 0
                var softirq = parseInt(parts[7]) || 0

                var total = user + nice + system + idle + iowait + irq + softirq
                var idleTime = idle + iowait

                if (lastCpuTotal > 0) {
                    var totalDiff = total - lastCpuTotal
                    var idleDiff = idleTime - lastCpuIdle
                    if (totalDiff > 0) {
                        cpuUsage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                    }
                }
                lastCpuTotal = total
                lastCpuIdle = idleTime
            }
        }
        Component.onCompleted: running = true
    }

    // Memory usage
    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    // Disk usage
    Process {
        id: diskProc
        command: ["sh", "-c", "df / | tail -1"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var percentStr = parts[4] || "0%"
                diskUsage = parseInt(percentStr.replace('%', '')) || 0
            }
        }
        Component.onCompleted: running = true
    }

    // Volume level (wpctl for PipeWire)
    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var match = data.match(/Volume:\s*([\d.]+)/)
                if (match) {
                    volumeLevel = Math.round(parseFloat(match[1]) * 100)
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Active window title
    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    activeWindow = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Spotify metadata
    Process {
        id: spotifyProc
        command: ["sh", "-c", "playerctl -p spotify metadata --format '{{artist}}|{{title}}|{{status}}' 2>/dev/null || echo '||Paused'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split('|')
                if (parts.length >= 3) {
                    spotifyArtist = parts[0] || ""
                    spotifyTrack = parts[1] || "No track"
                    spotifyStatus = parts[2] || "Paused"
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Slow timer for system stats
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            diskProc.running = true
            volProc.running = true
        }
    }

    // Timer for Spotify updates
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            spotifyProc.running = true
        }
    }



    // Backup timer for window/layout (catches edge cases)
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            windowProc.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 40
            color: Theme.colBg

            margins {
                top: 0
                bottom: 0
                left: 0
                right: 0
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.colBg

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item { width: 8 }

                    // Workspaces
                    Repeater {
                        model: 5

                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: parent.height
                            color: "transparent"

                            property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
                            property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                            property bool hasWindows: workspace !== null

                            Text {
                                text: index + 1
                                color: parent.isActive ? Theme.colCyan : (parent.hasWindows ? Theme.colFg : Theme.colMuted)
                                font.pixelSize: root.fontSize
                                font.family: root.fontFamily
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            Rectangle {
                                width: 20
                                height: 3
                                color: parent.isActive ? Theme.colPurple : Theme.colBg
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Hyprland.dispatch("workspace " + (index + 1))
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: Theme.colMuted
                    }

                    Text {
                        text: activeWindow
                        color: Theme.colPurple
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    // Center: Date/Time
                    Text {
                        id: clockText
                        text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
                        color: Theme.colCyan
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
                        }
                    }

                    // Spotify widget
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Text.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: Theme.colMuted
                    }

                    Text {
                        text: (spotifyStatus === "Playing" ? " " : " ") + 
                              (spotifyArtist ? spotifyArtist + " - " : "") + spotifyTrack
                        color: spotifyStatus === "Playing" ? Theme.colGreen : Theme.colMuted
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                        Layout.maximumWidth: 300
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    // Skip to next track
                                    var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                    proc.command = ["playerctl", "-p", "spotify", "next"]
                                    proc.running = true
                                } else if (mouse.button === Qt.LeftButton) {
                                    // Play/Pause
                                    var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                    proc.command = ["playerctl", "-p", "spotify", "play-pause"]
                                    proc.running = true
                                } else if (mouse.button === Qt.MiddleButton) {
                                    // Previous track
                                    var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                    proc.command = ["playerctl", "-p", "spotify", "previous"]
                                    proc.running = true
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 0
                        Layout.rightMargin: 8
                        color: Theme.colMuted
                    }

                    // Bluetooth button
                    Rectangle {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: btLayout.width + 16
                        color: btMouseArea.containsMouse ? Theme.colMuted : "transparent"
                        opacity: btMouseArea.containsMouse ? 0.3 : 1.0
                        radius: 4

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        RowLayout {
                            id: btLayout
                            anchors.centerIn: parent
                            spacing: 0

                            Text {
                                text: Theme.btGui + ":" + root.connectedCount 
                                color: Theme.colBlue
                                font.pixelSize: root.fontSize
                                font.family: root.fontFamily
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: btMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: bluetoothVisible = !bluetoothVisible
                        }
                    }

                    Text {
                        text: " " + Theme.cpuIcon + ":" + cpuUsage + "%"
                        color: Theme.colYellow
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Text {
                        text: " " + Theme.memIcon + ":" + memUsage + "%"
                        color: Theme.colCyan
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Text {
                        text: " " + Theme.diskIcon + ":" + diskUsage + "%"
                        color: Theme.colOrange
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Text {
                        text: " " + Theme.volMax + ":" + volumeLevel + "%"
                        color: Theme.colPurple
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Item { width: 8 }
                }
            }
        }
    }
}
