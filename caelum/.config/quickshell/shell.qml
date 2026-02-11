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
    property int fontSize: 15

    // System info properties
    property string kernelVersion: "Linux"
    property int cpuUsage: 0
    property int memUsage: 0
    property int diskUsage: 0
    property int volumeLevel: 0
    property string activeWindow: "Window"
    property string networkStatus: "Disconnected"
    property string networkType: "none"
    property bool bluetoothVisible: false
    property bool spotifyVisible: false

    // Spotify properties
    property string spotifyTrack: "No track"
    property string spotifyArtist: ""
    property string spotifyStatus: "Paused"

    // CPU tracking
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property int connectedCount: 0 

    // Stats expansion state
    property bool statsExpanded: false

    // Bluetooth 
    Loader {
        id: bluetoothLoader
        active: bluetoothVisible
        source: "widgets/bluetooth.qml"
    }

    // Spotify
    Loader {
        id: spotifyLoader
        active: spotifyVisible
        source: "widgets/spotify.qml"
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

    // Network status (WiFi/Ethernet)
    Process {
        id: networkProc
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE device | grep -E '^(wifi|ethernet):connected' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.trim()) {
                    networkStatus = "Disconnected"
                    networkType = "none"
                    return
                }
                var parts = data.trim().split(':')
                if (parts.length >= 2) {
                    networkType = parts[0] // "wifi" or "ethernet"
                    networkStatus = parts[1] // "connected"
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
            networkProc.running = true
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

            implicitHeight: 35
            color: "transparent"

            margins {
                top: 0
                bottom: 0
                left: 8
                right: 8
            }

            Rectangle {
                id: mainPanel
                anchors.fill: parent
                color: Colors.colBg
                radius: 8
                
                // Subtle shadow effect
                layer.enabled: true
                layer.effect: ShaderEffect {
                    property color shadowColor: Qt.rgba(0, 0, 0, 0.25)
                }

                // LEFT MODULE
                Rectangle {
                    id: leftModule
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        margins: 4
                    }
                    width: leftLayout.implicitWidth + 16
                    color: Colors.colBg
                    radius: 8

                    RowLayout {
                        id: leftLayout
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 5

                        // Workspaces
                        Item {
                            Layout.preferredWidth: 5 * 28 + 4 * 4 + 28  // base width + spacing + extra for expansion
                            Layout.preferredHeight: 27

                            Repeater {
                                model: 5

                                Rectangle {
                                    id: workspaceRect
                                    
                                    property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
                                    property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                                    property bool hasWindows: workspace !== null
                                    
                                    width: isActive ? 56 : 28
                                    height: isActive ? 27 : 24
                                    y: isActive ? 0 : 1.5
                                    
                                    // Calculate x position based on active workspace
                                    x: {
                                        var activeIndex = -1
                                        
                                        // Find which workspace is active
                                        for (var i = 0; i < 5; i++) {
                                            if (Hyprland.focusedWorkspace?.id === (i + 1)) {
                                                activeIndex = i
                                                break
                                            }
                                        }
                                        
                                        // If no active workspace, use normal positioning
                                        if (activeIndex === -1) {
                                            return index * (28 + 4)
                                        }
                                        
                                        // Calculate position based on whether we're before, at, or after active
                                        var pos = 0
                                        for (var j = 0; j < index; j++) {
                                            if (j === activeIndex) {
                                                pos += 56 + 4  // active workspace is wider
                                            } else {
                                                pos += 28 + 4  // normal workspace
                                            }
                                        }
                                        
                                        return pos
                                    }
                                    
                                    color: isActive ? Colors.colBlue : (workspaceMouseArea.containsMouse ? Colors.colMuted : "transparent")
                                    radius: 6

                                    Behavior on color {
                                        ColorAnimation { duration: 200 }
                                    }

                                    Behavior on width {
                                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                    }
                                    
                                    Behavior on height {
                                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                    }
                                    
                                    Behavior on x {
                                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                    }
                                    
                                    Behavior on y {
                                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                    }

                                    Text {
                                        text: {
                                            if (workspaceRect.isActive) return Theme.windowActive
                                            if (workspaceRect.hasWindows) return Theme.windowEnabled
                                            if (!workspaceRect.isActive && !workspaceRect.hasWindows) return Theme.windowInactive
                                            return ""
                                        }
                                        color: workspaceRect.isActive ? Colors.colBg : (workspaceRect.hasWindows ? Colors.colFg : Colors.colMuted)
                                        font.pixelSize: workspaceRect.isActive ? 13 : 10
                                        font.family: root.fontFamily
                                        font.weight: workspaceRect.isActive ? Font.Bold : Font.Normal
                                        anchors.centerIn: parent
                                        
                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }
                                        
                                        Behavior on font.pixelSize {
                                            NumberAnimation { duration: 150 }
                                        }
                                    }

                                    MouseArea {
                                        id: workspaceMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 19
                            color: Colors.colMuted
                            opacity: 0.5
                        }

                        // Active Window Title
                        Text {
                            text: activeWindow
                            color: Colors.colPurple
                            font.pixelSize: root.fontSize
                            font.family: root.fontFamily
                            font.weight: Font.DemiBold
                            Layout.maximumWidth: 300
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            Layout.alignment: Qt.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                // CENTER MODULE - ABSOLUTELY CENTERED
                Rectangle {
                    id: centerModule
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        bottom: parent.bottom
                        margins: 4
                    }
                    width: centerLayout.implicitWidth + 16
                    color: Colors.colBg
                    radius: 8

                    RowLayout {
                        id: centerLayout
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 8

                        // Date/Time
                        Text {
                            id: clockText
                            text: Qt.formatDateTime(new Date(), "HH:mm  ddd, dd/MM")
                            color: Colors.colOrange
                            font.pixelSize: root.fontSize
                            font.family: root.fontFamily
                            font.weight: Font.Bold

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm  ddd, dd/MM")
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 16
                            color: Colors.colMuted
                            opacity: 0.5
                        }

                        // Spotify widget
                        Rectangle {
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: spotifyLayout.implicitWidth + 12
                            radius: 4
                            color: spotifyStatus === "Playing" ? Colors.colGreen : Colors.colBg
                            
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }

                            RowLayout {
                                id: spotifyLayout
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: (spotifyArtist ? spotifyArtist + " - " : "") + spotifyTrack
                                    color: spotifyStatus === "Playing" ? Colors.colBg : Colors.colMuted
                                    font.pixelSize: root.fontSize
                                    font.family: root.fontFamily
                                    font.weight: spotifyStatus === "Playing" ? Font.Bold : Font.DemiBold
                                    Layout.maximumWidth: 300
                                    elide: Text.ElideRight
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                    
                                    Behavior on font.weight {
                                        NumberAnimation { duration: 300 }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                        proc.command = ["playerctl", "-p", "spotify", "next"]
                                        proc.running = true
                                    } else if (mouse.button === Qt.LeftButton) {
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                        proc.command = ["playerctl", "-p", "spotify", "play-pause"]
                                        proc.running = true
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                        proc.command = ["playerctl", "-p", "spotify", "previous"]
                                        proc.running = true
                                    }
                                }
                            }
                        }

                        // Spotify widget toggle button
                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.fillHeight: true
                            color: spotifyWidgetMouseArea.containsMouse ? Colors.colGreen : "transparent"
                            radius: 6
                            border.width: spotifyVisible ? 1 : 0
                            border.color: Qt.rgba(0.3, 1.0, 0.5, 0.5)
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            
                            Behavior on border.width {
                                NumberAnimation { duration: 200 }
                            }

                            Text {
                                text: Theme.multimediaIcon
                                color: spotifyWidgetMouseArea.containsMouse ? Colors.colBg : (spotifyStatus === "Playing" ? Colors.colGreen : Colors.colMuted)
                                font.pixelSize: root.fontSize
                                font.family: root.fontFamily
                                font.weight: Font.DemiBold
                                anchors.centerIn: parent
                                
                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            MouseArea {
                                id: spotifyWidgetMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: spotifyVisible = !spotifyVisible
                            }
                        }
                    }
                }

                // RIGHT MODULE
                Rectangle {
                    id: rightModule
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        margins: 4
                    }
                    width: rightLayout.implicitWidth + 16
                    color: Colors.colBg
                    radius: 8

                    RowLayout {
                        id: rightLayout
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 5

                        // System stats (expandable)
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: statsLayout.implicitWidth + 12
                            color: statsMouseArea.containsMouse ? Qt.rgba(0.2, 0.4, 0.8, 0.15) : "transparent"
                            radius: 6
                            border.width: statsExpanded ? 1 : 0
                            border.color: Qt.rgba(0.3, 0.5, 1.0, 0.3)
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            
                            Behavior on border.width {
                                NumberAnimation { duration: 200 }
                            }
                            
                            Behavior on Layout.preferredWidth {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }

                            RowLayout {
                                id: statsLayout
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: Theme.cpuIcon + " " + cpuUsage + "%"
                                    color: Colors.colYellow
                                    font.pixelSize: root.fontSize
                                    font.family: root.fontFamily
                                    font.weight: Font.DemiBold
                                    visible: statsExpanded || !statsExpanded
                                }

                                Text {
                                    text: Theme.memIcon + " " + memUsage + "%"
                                    color: Colors.colCyan
                                    font.pixelSize: root.fontSize
                                    font.family: root.fontFamily
                                    font.weight: Font.DemiBold
                                    visible: statsExpanded
                                    opacity: statsExpanded ? 1 : 0
                                    
                                    Behavior on opacity {
                                        NumberAnimation { duration: 200 }
                                    }
                                }

                                Text {
                                    text: Theme.diskIcon + " " + diskUsage + "%"
                                    color: Colors.colOrange
                                    font.pixelSize: root.fontSize
                                    font.family: root.fontFamily
                                    font.weight: Font.DemiBold
                                    visible: statsExpanded
                                    opacity: statsExpanded ? 1 : 0
                                    
                                    Behavior on opacity {
                                        NumberAnimation { duration: 200 }
                                    }
                                }

                                Text {
                                    text: Theme.volMax + " " + volumeLevel + "%"
                                    color: Colors.colPurple
                                    font.pixelSize: root.fontSize
                                    font.family: root.fontFamily
                                    font.weight: Font.DemiBold
                                    visible: statsExpanded
                                    opacity: statsExpanded ? 1 : 0
                                    
                                    Behavior on opacity {
                                        NumberAnimation { duration: 200 }
                                    }
                                }

                                Text {
                                    text: (networkType === "wifi" ? "󰖩" : networkType === "ethernet" ? "󰈀" : "󰖪") + " " + (networkStatus === "connected" ? "On" : "Off")
                                    color: networkStatus === "connected" ? Colors.colGreen : Colors.colRed
                                    font.pixelSize: root.fontSize
                                    font.family: root.fontFamily
                                    font.weight: Font.DemiBold
                                    visible: statsExpanded
                                    opacity: statsExpanded ? 1 : 0
                                    
                                    Behavior on opacity {
                                        NumberAnimation { duration: 200 }
                                    }
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 200 }
                                    }
                                }
                            }

                            MouseArea {
                                id: statsMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: statsExpanded = !statsExpanded
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 16
                            color: Colors.colMuted
                            opacity: 0.5
                        }

                        // Bluetooth button
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: btLayout.implicitWidth + 12
                            color: btMouseArea.containsMouse ? Colors.colMuted : "transparent"
                            radius: 6
                            border.width: root.connectedCount > 0 ? 1 : 0
                            border.color: Qt.rgba(0.2, 0.6, 1.0, 0.5)
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            
                            Behavior on border.width {
                                NumberAnimation { duration: 200 }
                            }

                            RowLayout {
                                id: btLayout
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: Theme.btGui
                                    color: Colors.colBlue
                                    font.pixelSize: root.fontSize
                                    font.family: root.fontFamily
                                    font.weight: Font.DemiBold
                                }
                                
                                Text {
                                    text: root.connectedCount > 0 ? root.connectedCount : ""
                                    color: Colors.colBlue
                                    font.pixelSize: root.fontSize - 2
                                    font.family: root.fontFamily
                                    font.weight: Font.DemiBold
                                    visible: root.connectedCount > 0
                                }
                            }

                            MouseArea {
                                id: btMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: bluetoothVisible = !bluetoothVisible
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 16
                            color: Colors.colMuted
                            opacity: 0.5
                        }

                        // Power button
                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.fillHeight: true
                            color: powerMouseArea.containsMouse ? Colors.colRed : "transparent"
                            radius: 6
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            Text {
                                text: "⏻"
                                color: powerMouseArea.containsMouse ? Colors.colBg : Colors.colFg
                                font.pixelSize: root.fontSize
                                font.family: root.fontFamily
                                anchors.centerIn: parent
                                
                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            MouseArea {
                                id: powerMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                // Add power menu action here
                            }
                        }
                    }
                }
            }
        }
    }
}
