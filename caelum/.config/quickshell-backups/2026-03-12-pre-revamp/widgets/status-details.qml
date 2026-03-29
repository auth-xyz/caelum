import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."

ShellRoot {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font Propo"
    property string screenName: ""
    property real anchorX: 8

    property string cpuTemp: "N/A"
    property string gpuTemp: "N/A"
    property string networkLabel: "Offline"
    property string localIp: "Unavailable"
    property string publicIp: "Unavailable"
    property string gateway: "Unavailable"

    signal closeRequested()

    function selectedScreen() {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === screenName) {
                return Quickshell.screens[i]
            }
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    function positionWindow() {
        if (!detailsWindow.screen || !detailsWindow.screen.geometry) return

        var screenGeometry = detailsWindow.screen.geometry
        var maxX = screenGeometry.width - detailsWindow.width - 8
        detailsWindow.x = Math.max(8, Math.min(anchorX, maxX))
        detailsWindow.y = 43
    }

    Process {
        id: cpuTempProc
        command: ["sh", "-c", "temp=$(sensors 2>/dev/null | awk '/Package id 0:|Tctl:|Tdie:|CPU Temp/ {for (i = 1; i <= NF; i++) if ($i ~ /\\+?[0-9.]+°C/) {gsub(/\\+|°C/, \"\", $i); print $i; exit}}'); echo \"${temp:-N/A}\""]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    cpuTemp = data.trim()
                }
            }
        }
    }

    Process {
        id: gpuTempProc
        command: ["sh", "-c", "if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1; else temp=$(sensors 2>/dev/null | awk 'tolower($0) ~ /amdgpu|radeon|nouveau/ {gpu=1; next} gpu && /edge:|junction:|temp1:/ {for (i = 1; i <= NF; i++) if ($i ~ /\\+?[0-9.]+°C/) {gsub(/\\+|°C/, \"\", $i); print $i; exit}} /^$/ {gpu=0}'); echo \"${temp:-N/A}\"; fi"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    gpuTemp = data.trim()
                }
            }
        }
    }

    Process {
        id: networkInfoProc
        command: ["sh", "-c", "info=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status | awk -F: '$3==\"connected\" {print $1\"|\"$2\"|\"$4; exit}'); if [ -z \"$info\" ]; then printf 'Offline\\nUnavailable\\nUnavailable\\n'; else IFS='|' read -r dev type conn <<EOF\n$info\nEOF\nip=$(nmcli -g IP4.ADDRESS device show \"$dev\" | head -1 | cut -d/ -f1)\ngw=$(nmcli -g IP4.GATEWAY device show \"$dev\" | head -1)\nlabel=\"$type\"\nif [ -n \"$conn\" ]; then label=\"$label - $conn\"; fi\nprintf '%s\\n%s\\n%s\\n' \"$label\" \"${ip:-Unavailable}\" \"${gw:-Unavailable}\"; fi"]
        stdout: SplitParser {
            id: networkInfoParser
            property var lines: []

            onRead: data => {
                if (!data) return
                lines.push(data.trim())
            }
        }
        onExited: () => {
            var lines = networkInfoParser.lines.filter(line => line !== "")
            networkLabel = lines.length > 0 ? lines[0] : "Offline"
            localIp = lines.length > 1 ? lines[1] : "Unavailable"
            gateway = lines.length > 2 ? lines[2] : "Unavailable"
            networkInfoParser.lines = []
        }
    }

    Process {
        id: publicIpProc
        command: ["sh", "-c", "curl -fsS --max-time 5 https://api.ipify.org || echo 'Unavailable'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    publicIp = data.trim()
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            cpuTempProc.running = true
            gpuTempProc.running = true
            networkInfoProc.running = true
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: publicIpProc.running = true
    }

    FloatingWindow {
        id: detailsWindow
        visible: true
        title: "qsstatusdetails"
        color: "transparent"
        screen: root.selectedScreen()

        implicitWidth: 360
        implicitHeight: 186

        Component.onCompleted: {
            positionWindow()
            openAnimation.start()
            cpuTempProc.running = true
            gpuTempProc.running = true
            networkInfoProc.running = true
            publicIpProc.running = true
        }

        onScreenChanged: positionWindow()

        ParallelAnimation {
            id: openAnimation

            NumberAnimation {
                target: detailsPanelContainer
                property: "opacity"
                from: 0
                to: 1
                duration: 180
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: detailsPanelContainer
                property: "y"
                from: -18
                to: 0
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: detailsPanelContainer
            anchors.fill: parent
            opacity: 0

            Rectangle {
                id: detailsPanel
                anchors.fill: parent
                color: Colors.colBg
                opacity: 0.98
                radius: 12
                border.width: 1
                border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.25)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            color: Qt.rgba(Colors.colYellow.r, Colors.colYellow.g, Colors.colYellow.b, 0.12)
                            radius: 10
                            border.width: 1
                            border.color: Qt.rgba(Colors.colYellow.r, Colors.colYellow.g, Colors.colYellow.b, 0.22)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                Text {
                                    text: "CPU Temp"
                                    color: Colors.colMuted
                                    font.pixelSize: 11
                                    font.family: root.fontFamily
                                }

                                Text {
                                    text: cpuTemp + (cpuTemp === "N/A" ? "" : "°C")
                                    color: Colors.colYellow
                                    font.pixelSize: 18
                                    font.family: root.fontFamily
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            color: Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.12)
                            radius: 10
                            border.width: 1
                            border.color: Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.22)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                Text {
                                    text: "GPU Temp"
                                    color: Colors.colMuted
                                    font.pixelSize: 11
                                    font.family: root.fontFamily
                                }

                                Text {
                                    text: gpuTemp + (gpuTemp === "N/A" ? "" : "°C")
                                    color: Colors.colOrange
                                    font.pixelSize: 18
                                    font.family: root.fontFamily
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.1)
                        radius: 10
                        border.width: 1
                        border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.22)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                text: "Network"
                                color: Colors.colBlue
                                font.pixelSize: 14
                                font.family: root.fontFamily
                                font.weight: Font.Bold
                            }

                            Text {
                                text: networkLabel
                                color: Colors.colFg
                                font.pixelSize: 13
                                font.family: root.fontFamily
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Local IP  " + localIp
                                color: Colors.colCyan
                                font.pixelSize: 12
                                font.family: root.fontFamily
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Public IP " + publicIp
                                color: Colors.colGreen
                                font.pixelSize: 12
                                font.family: root.fontFamily
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Gateway   " + gateway
                                color: Colors.colPurple
                                font.pixelSize: 12
                                font.family: root.fontFamily
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: detailsWindow.visible

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.closeRequested()
                    event.accepted = true
                }
            }
        }
    }
}
