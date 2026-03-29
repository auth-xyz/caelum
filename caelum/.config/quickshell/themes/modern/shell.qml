import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "widgets" as Widgets

ShellRoot {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font Propo"
    property int fontSize: 14
    property int panelHeight: 42
    property int dropdownAreaHeight: 308

    property string dropdownName: ""
    property string dropdownScreenName: ""
    property real dropdownAnchorX: 0
    property int dropdownWidth: 320
    property int dropdownHeight: 180

    property int cpuUsage: 0
    property int memUsage: 0
    property int diskUsage: 0
    property int volumeLevel: 0
    property string activeWindow: "Window"
    property string networkStatus: "offline"
    property string networkType: "none"
    property string networkName: "Offline"
    property string networkDevice: ""
    property string localIp: "Unavailable"
    property string publicIp: "Unavailable"
    property string gatewayIp: "Unavailable"
    property string cpuTemp: "N/A"
    property string gpuTemp: "N/A"
    property var audioOutputs: []
    property var audioInputs: []
    property var audioStreams: []
    property var activeVpns: []
    property bool micInUse: false
    property string micApps: "Idle"
    property bool screenShareActive: false
    property string screenShareApps: "Idle"

    property string spotifyTrack: "No track"
    property string spotifyArtist: ""
    property string spotifyStatus: "Paused"
    property string spotifyCoverArt: ""

    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property int catTick: 0

    function closeDropdown() {
        dropdownName = ""
        dropdownScreenName = ""
    }

    function toggleDropdown(name, screenName, anchorX, width, height) {
        if (dropdownName === name && dropdownScreenName === screenName) {
            closeDropdown()
            return
        }

        dropdownName = name
        dropdownScreenName = screenName
        dropdownAnchorX = anchorX
        dropdownWidth = width
        dropdownHeight = height
    }

    function launchCommand(command) {
        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
        proc.command = command
        proc.running = true
    }

    function setVolume(percent) {
        var clamped = Math.max(0, Math.min(100, percent))
        launchCommand(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (clamped / 100).toFixed(2)])
        volumeLevel = clamped
    }

    function adjustVolume(delta) {
        setVolume(volumeLevel + delta)
    }

    function refreshAudioGraph() {
        wpctlStatusProc.running = true
    }

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyImagesSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true
        }
    }

    function runPowerAction(action) {
        closeDropdown()

        switch (action) {
        case "lock":
            launchCommand(["hyprlock"])
            break
        case "logout":
            launchCommand(["hyprctl", "dispatch", "exit"])
            break
        case "suspend":
            launchCommand(["systemctl", "suspend"])
            break
        case "reboot":
            launchCommand(["systemctl", "reboot"])
            break
        case "poweroff":
            launchCommand(["systemctl", "poweroff"])
            break
        }
    }

    function networkIcon() {
        if (networkType === "wifi" && networkStatus === "online") return "󰖩"
        if (networkType === "ethernet" && networkStatus === "online") return "󰈀"
        return "󰖪"
    }

    function networkAccent() {
        return networkStatus === "online" ? Colors.colGreen : Colors.colRed
    }

    function volumeIcon() {
        if (volumeLevel === 0) return "󰝟"
        if (volumeLevel < 40) return "󰕿"
        return "󰕾"
    }

    function resolveIconSource(iconName, fallbackName) {
        if (!iconName || iconName === "") {
            iconName = fallbackName
        }

        if (iconName && iconName.startsWith("/")) {
            return "file://" + iconName
        }

        var resolved = Quickshell.iconPath(iconName, true)
        if (resolved && resolved !== "") {
            return resolved.startsWith("/") ? "file://" + resolved : resolved
        }

        var fallback = Quickshell.iconPath(fallbackName, true)
        if (fallback && fallback !== "") {
            return fallback.startsWith("/") ? "file://" + fallback : fallback
        }

        return ""
    }

    function resolveTrayIconSource(iconName, fallbackName) {
        var name = iconName && iconName !== "" ? iconName : fallbackName
        if (!name || name === "") {
            return ""
        }

        if (name.startsWith("/")) {
            return "file://" + name
        }

        var resolved = Quickshell.iconPath(name, true)
        if (resolved && resolved !== "" && resolved.startsWith("/")) {
            return "file://" + resolved
        }

        return "image://icon/" + encodeURIComponent(name)
    }

    function catMood() {
        if (cpuUsage < 15) return "( =.= ) zZ"
        if (cpuUsage < 35) return catTick % 2 === 0 ? "( o.o )" : "( o.o )~"
        if (cpuUsage < 60) return catTick % 2 === 0 ? "\\( o.o )" : "/( o.o )"
        if (cpuUsage < 80) return ["\\( o.o )/", "/( o.o )\\", "( o.o )~~"][catTick % 3]
        return ["\\( O.O )/ !!", "/( O.O )\\ !!", "<( O.O )> !!"][catTick % 3]
    }

    function catAccent() {
        if (cpuUsage < 15) return Colors.colBlue
        if (cpuUsage < 35) return Colors.colCyan
        if (cpuUsage < 60) return Colors.colYellow
        if (cpuUsage < 80) return Colors.colOrange
        return Colors.colRed
    }

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
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | awk '/Mem:/ {print $2\"|\"$3}'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split("|")
                var total = parseInt(parts[0]) || 1
                var used = parseInt(parts[1]) || 0
                memUsage = Math.round(100 * used / total)
            }
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df / | tail -1 | awk '{print $5}'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                diskUsage = parseInt(data.trim().replace("%", "")) || 0
            }
        }
    }

    Process {
        id: volumeProc
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
    }

    Process {
        id: wpctlStatusProc
        command: ["sh", "/home/auth/.repos/caelum/caelum/.config/quickshell/scripts/wpctl-audio-status.sh"]
        stdout: SplitParser {
            property var rows: []

            onRead: data => {
                if (!data) return
                rows.push(data)
            }
        }

        onExited: () => {
            var outputs = []
            var inputs = []
            var streams = []
            var lines = wpctlStatusProc.stdout.rows

            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].trim().split("|")
                if (parts.length < 5) continue
                var entry = {
                    isDefault: parts[1] === "1",
                    id: parts[2],
                    name: parts[3],
                    volume: parseInt(parts[4]) || 0
                }

                if (parts[0] === "sink") outputs.push(entry)
                else if (parts[0] === "source") inputs.push(entry)
                else if (parts[0] === "stream") streams.push(entry)
            }

            audioOutputs = outputs
            audioInputs = inputs
            audioStreams = streams
            wpctlStatusProc.stdout.rows = []
        }
    }

    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    activeWindow = data.trim()
                } else {
                    activeWindow = "Desktop"
                }
            }
        }
    }

    Process {
        id: networkProc
        command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status | awk -F: '$3==\"connected\" {print $1\"|\"$2\"|\"$3\"|\"$4; exit}'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.trim()) {
                    networkDevice = ""
                    networkType = "none"
                    networkStatus = "offline"
                    networkName = "Offline"
                    return
                }

                var parts = data.trim().split("|")
                networkDevice = parts[0] || ""
                networkType = parts[1] || "none"
                networkStatus = parts[2] === "connected" ? "online" : "offline"
                networkName = parts[3] || (networkType === "wifi" ? "Wi-Fi" : "Wired")
            }
        }
    }

    Process {
        id: localIpProc
        command: ["sh", "-c", "if [ -n '" + root.networkDevice + "' ]; then ip=$(nmcli -g IP4.ADDRESS device show '" + root.networkDevice + "' | head -1 | cut -d/ -f1); gw=$(nmcli -g IP4.GATEWAY device show '" + root.networkDevice + "' | head -1); printf '%s|%s\\n' \"${ip:-Unavailable}\" \"${gw:-Unavailable}\"; else printf 'Unavailable|Unavailable\\n'; fi"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split("|")
                localIp = parts[0] || "Unavailable"
                gatewayIp = parts[1] || "Unavailable"
            }
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

    Process {
        id: vpnProc
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE,DEVICE connection show --active | awk -F: '$2 ~ /vpn|wireguard|tun/ {print $1\"|\"$2\"|\"$3}'"]
        stdout: SplitParser {
            property var rows: []

            onRead: data => {
                if (!data) return
                rows.push(data.trim())
            }
        }

        onExited: () => {
            var parsed = []
            for (var i = 0; i < vpnProc.stdout.rows.length; i++) {
                var line = vpnProc.stdout.rows[i]
                if (!line) continue
                var parts = line.split("|")
                parsed.push({
                    name: parts[0] || "VPN",
                    type: parts[1] || "vpn",
                    device: parts[2] || ""
                })
            }
            activeVpns = parsed
            vpnProc.stdout.rows = []
        }
    }

    Process {
        id: privacyProc
        command: ["sh", "/home/auth/.repos/caelum/caelum/.config/quickshell/scripts/privacy-status.sh"]
        stdout: SplitParser {
            property var rows: []

            onRead: data => {
                if (!data) return
                rows.push(data.trim())
            }
        }

        onExited: () => {
            var micActive = false
            var micNames = "Idle"
            var shareActive = false
            var shareNames = "Idle"

            for (var i = 0; i < privacyProc.stdout.rows.length; i++) {
                var line = privacyProc.stdout.rows[i]
                if (!line) continue

                var parts = line.split("|")
                if (parts.length < 3) continue

                var details = parts.slice(2).join("|") || "Idle"
                if (parts[0] === "mic") {
                    micActive = parts[1] === "1"
                    micNames = details
                } else if (parts[0] === "share") {
                    shareActive = parts[1] === "1"
                    shareNames = details
                }
            }

            micInUse = micActive
            micApps = micNames
            screenShareActive = shareActive
            screenShareApps = shareNames
            privacyProc.stdout.rows = []
        }
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
        id: spotifyProc
        command: ["sh", "-c", "playerctl -p spotify metadata --format '{{artist}}|{{title}}|{{status}}|{{mpris:artUrl}}' 2>/dev/null || echo '||Paused|'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split("|")
                spotifyArtist = parts[0] || ""
                spotifyTrack = parts[1] || "No track"
                spotifyStatus = parts[2] || "Paused"
                spotifyCoverArt = parts[3] || ""
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            diskProc.running = true
            volumeProc.running = true
            networkProc.running = true
            windowProc.running = true
            wpctlStatusProc.running = true
            vpnProc.running = true
            privacyProc.running = true
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            cpuTempProc.running = true
            gpuTempProc.running = true
            if (networkDevice !== "") {
                localIpProc.running = true
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: publicIpProc.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: spotifyProc.running = true
    }

    Timer {
        interval: 320
        running: true
        repeat: true
        onTriggered: catTick = (catTick + 1) % 12
    }

    Component {
        id: statusDropdown

        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        color: Qt.rgba(Colors.colYellow.r, Colors.colYellow.g, Colors.colYellow.b, 0.12)
                        radius: 14
                        border.width: 1
                        border.color: Qt.rgba(Colors.colYellow.r, Colors.colYellow.g, Colors.colYellow.b, 0.25)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Text { text: "CPU"; color: Colors.colMuted; font.family: root.fontFamily; font.pixelSize: 11 }
                            Text { text: cpuUsage + "%  /  " + cpuTemp + (cpuTemp === "N/A" ? "" : "C"); color: Colors.colYellow; font.family: root.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        color: Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.12)
                        radius: 14
                        border.width: 1
                        border.color: Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.25)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Text { text: "GPU"; color: Colors.colMuted; font.family: root.fontFamily; font.pixelSize: 11 }
                            Text { text: gpuTemp + (gpuTemp === "N/A" ? "" : "C"); color: Colors.colOrange; font.family: root.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        color: Qt.rgba(Colors.colCyan.r, Colors.colCyan.g, Colors.colCyan.b, 0.12)
                        radius: 14
                        border.width: 1
                        border.color: Qt.rgba(Colors.colCyan.r, Colors.colCyan.g, Colors.colCyan.b, 0.25)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Text { text: "Memory"; color: Colors.colMuted; font.family: root.fontFamily; font.pixelSize: 11 }
                            Text { text: memUsage + "%"; color: Colors.colCyan; font.family: root.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        color: Qt.rgba(Colors.colPurple.r, Colors.colPurple.g, Colors.colPurple.b, 0.12)
                        radius: 14
                        border.width: 1
                        border.color: Qt.rgba(Colors.colPurple.r, Colors.colPurple.g, Colors.colPurple.b, 0.25)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Text { text: "Disk / Audio"; color: Colors.colMuted; font.family: root.fontFamily; font.pixelSize: 11 }
                            Text { text: diskUsage + "%  /  " + volumeLevel + "%"; color: Colors.colPurple; font.family: root.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.10)
                    radius: 14
                    border.width: 1
                    border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.24)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text { text: "Network"; color: Colors.colBlue; font.family: root.fontFamily; font.pixelSize: 14; font.weight: Font.Bold }
                        Text { text: networkIcon() + "  " + networkName; color: Colors.colFg; font.family: root.fontFamily; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: "Local IP   " + localIp; color: Colors.colCyan; font.family: root.fontFamily; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: "Public IP  " + publicIp; color: Colors.colGreen; font.family: root.fontFamily; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: "Gateway    " + gatewayIp; color: Colors.colPurple; font.family: root.fontFamily; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                }
            }
        }
    }

    Component {
        id: trayDropdown

        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Notifications"
                        color: Colors.colFg
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: notificationServer.trackedNotifications.count + " alerts"
                        color: Colors.colMuted
                        font.family: root.fontFamily
                        font.pixelSize: 11
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: notificationsColumn.height
                    clip: true

                    Column {
                        id: notificationsColumn
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: notificationServer.trackedNotifications

                            Rectangle {
                                width: notificationsColumn.width
                                height: 70
                                radius: 12
                                color: notificationMouse.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.14) : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.08)
                                border.width: modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                                border.color: Qt.rgba(Colors.colRed.r, Colors.colRed.g, Colors.colRed.b, 0.28)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Rectangle {
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30
                                        radius: 10
                                        color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.14)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰍡"
                                            color: Colors.colBlue
                                            font.family: root.fontFamily
                                            font.pixelSize: 14
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.appName || "Notification"
                                            color: Colors.colMuted
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.summary || "No title"
                                            color: Colors.colFg
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.body || ""
                                            color: Colors.colMuted
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 26
                                        Layout.preferredHeight: 26
                                        radius: 9
                                        color: dismissMouse.containsMouse ? Qt.rgba(Colors.colRed.r, Colors.colRed.g, Colors.colRed.b, 0.16) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            color: Colors.colRed
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                        }

                                        MouseArea {
                                            id: dismissMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: modelData.dismiss()
                                        }
                                    }
                                }

                                MouseArea {
                                    id: notificationMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }
                            }
                        }

                        Text {
                            width: notificationsColumn.width
                            text: notificationServer.trackedNotifications.count === 0 ? "No tracked notifications." : ""
                            color: Colors.colMuted
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            visible: notificationServer.trackedNotifications.count === 0
                        }
                    }
                }
            }
        }
    }

    Component {
        id: privacyDropdown

        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    radius: 14
                    color: Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.10)
                    border.width: 1
                    border.color: Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.24)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: ""
                                color: Colors.colOrange
                                font.family: root.fontFamily
                                font.pixelSize: 14
                            }

                            Text {
                                text: "Microphone"
                                color: Colors.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            text: micInUse ? micApps : "Not in use"
                            color: micInUse ? Colors.colFg : Colors.colMuted
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    radius: 14
                    color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.10)
                    border.width: 1
                    border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.24)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "󰍹"
                                color: Colors.colBlue
                                font.family: root.fontFamily
                                font.pixelSize: 14
                            }

                            Text {
                                text: "Screen Share"
                                color: Colors.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            text: screenShareActive ? screenShareApps : "Not in use"
                            color: screenShareActive ? Colors.colFg : Colors.colMuted
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }

    Component {
        id: wifiDropdown

        Item {
            id: wifiRoot
            property var networks: []

            Process {
                id: wifiScanProc
                command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list | head -n 10"]
                stdout: SplitParser {
                    property var rows: []

                    onRead: data => {
                        if (!data) return
                        rows.push(data.trim())
                    }
                }

                onExited: () => {
                    var parsed = []
                    for (var i = 0; i < wifiScanProc.stdout.rows.length; i++) {
                        var line = wifiScanProc.stdout.rows[i]
                        if (!line) continue
                        var parts = line.split(":")
                        parsed.push({
                            active: parts[0] || "",
                            ssid: parts[1] || "Hidden network",
                            signal: parts[2] || "--",
                            security: parts.slice(3).join(":") || "Open"
                        })
                    }
                    wifiRoot.networks = parsed
                    wifiScanProc.stdout.rows = []
                }
            }

            Component.onCompleted: wifiScanProc.running = true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 82
                    color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.10)
                    radius: 14
                    border.width: 1
                    border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.25)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        Text { text: "Network"; color: Colors.colBlue; font.family: root.fontFamily; font.pixelSize: 14; font.weight: Font.Bold }
                        Text { text: networkIcon() + "  " + networkName; color: Colors.colFg; font.family: root.fontFamily; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: "Local " + localIp + "   Public " + publicIp; color: Colors.colMuted; font.family: root.fontFamily; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 12
                        color: editorMouse.containsMouse ? Qt.rgba(Colors.colCyan.r, Colors.colCyan.g, Colors.colCyan.b, 0.16) : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Colors.colCyan.r, Colors.colCyan.g, Colors.colCyan.b, 0.26)

                        Text {
                            anchors.centerIn: parent
                            text: "Open Network Editor"
                            color: Colors.colCyan
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: editorMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launchCommand(["nm-connection-editor"])
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 82
                        Layout.preferredHeight: 34
                        radius: 12
                        color: scanMouse.containsMouse ? Qt.rgba(Colors.colGreen.r, Colors.colGreen.g, Colors.colGreen.b, 0.16) : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Colors.colGreen.r, Colors.colGreen.g, Colors.colGreen.b, 0.26)

                        Text {
                            anchors.centerIn: parent
                            text: "Rescan"
                            color: Colors.colGreen
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: scanMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: wifiScanProc.running = true
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: wifiColumn.height
                    clip: true

                    Column {
                        id: wifiColumn
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: wifiRoot.networks

                            Rectangle {
                                width: wifiColumn.width
                                height: 42
                                radius: 12
                                color: wifiMouse.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.14) : "transparent"
                                border.width: modelData.active === "yes" ? 1 : 0
                                border.color: Qt.rgba(Colors.colGreen.r, Colors.colGreen.g, Colors.colGreen.b, 0.28)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Text {
                                        text: modelData.active === "yes" ? "󰄬" : "󰖩"
                                        color: modelData.active === "yes" ? Colors.colGreen : Colors.colBlue
                                        font.family: root.fontFamily
                                        font.pixelSize: 14
                                    }

                                    Text {
                                        text: modelData.ssid
                                        color: Colors.colFg
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.signal + "%"
                                        color: Colors.colYellow
                                        font.family: root.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: wifiMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: audioDropdown

        Item {
            Flickable {
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: audioColumn.implicitHeight

                ColumnLayout {
                    id: audioColumn
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76
                        color: Qt.rgba(Colors.colPurple.r, Colors.colPurple.g, Colors.colPurple.b, 0.10)
                        radius: 14
                        border.width: 1
                        border.color: Qt.rgba(Colors.colPurple.r, Colors.colPurple.g, Colors.colPurple.b, 0.25)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true

                                Text { text: volumeIcon(); color: Colors.colPurple; font.family: root.fontFamily; font.pixelSize: 16 }
                                Text { text: "Audio"; color: Colors.colFg; font.family: root.fontFamily; font.pixelSize: 14; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: volumeLevel + "%"; color: Colors.colPurple; font.family: root.fontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                            }

                            Rectangle {
                                id: masterVolumeTrack
                                function updateVolumeFromX(xPos) {
                                    root.setVolume(Math.round((Math.max(0, Math.min(width, xPos)) / width) * 100))
                                }

                                Layout.fillWidth: true
                                Layout.preferredHeight: 12
                                radius: 6
                                color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.34)

                                Rectangle {
                                    width: parent.width * (volumeLevel / 100)
                                    height: parent.height
                                    radius: 6
                                    color: Colors.colPurple
                                }

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    x: Math.max(0, Math.min(parent.width - width, (parent.width * (volumeLevel / 100)) - width / 2))
                                    y: (parent.height - height) / 2
                                    color: Colors.colFg
                                    border.width: 2
                                    border.color: Colors.colPurple
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    preventStealing: true
                                    onPressed: mouse => masterVolumeTrack.updateVolumeFromX(mouse.x)
                                    onPositionChanged: mouse => {
                                        if (pressed) masterVolumeTrack.updateVolumeFromX(mouse.x)
                                    }
                                    onClicked: mouse => masterVolumeTrack.updateVolumeFromX(mouse.x)
                                }

                                WheelHandler {
                                    onWheel: event => {
                                        root.adjustVolume(event.angleDelta.y > 0 ? 5 : -5)
                                        event.accepted = true
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Outputs"
                        color: Colors.colFg
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: audioOutputs

                            Rectangle {
                                width: audioColumn.width
                                height: 42
                                visible: true
                                radius: 12
                                color: sinkMouse.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.14) : "transparent"
                                border.width: modelData.isDefault ? 1 : 0
                                border.color: Qt.rgba(Colors.colGreen.r, Colors.colGreen.g, Colors.colGreen.b, 0.28)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Text {
                                        text: modelData.isDefault ? "󰄬" : "󰕾"
                                        color: modelData.isDefault ? Colors.colGreen : Colors.colPurple
                                        font.family: root.fontFamily
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        text: modelData.name
                                        color: Colors.colFg
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.volume + "%"
                                        color: Colors.colMuted
                                        font.family: root.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: sinkMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.launchCommand(["wpctl", "set-default", modelData.id])
                                        Qt.callLater(root.refreshAudioGraph)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Inputs"
                        color: Colors.colFg
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: audioInputs

                            Rectangle {
                                width: audioColumn.width
                                height: 42
                                visible: true
                                radius: 12
                                color: sourceMouse.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.14) : "transparent"
                                border.width: modelData.isDefault ? 1 : 0
                                border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.28)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Text {
                                        text: modelData.isDefault ? "󰄬" : "󰍬"
                                        color: modelData.isDefault ? Colors.colBlue : Colors.colCyan
                                        font.family: root.fontFamily
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        text: modelData.name
                                        color: Colors.colFg
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.volume + "%"
                                        color: Colors.colMuted
                                        font.family: root.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: sourceMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.launchCommand(["wpctl", "set-default", modelData.id])
                                        Qt.callLater(root.refreshAudioGraph)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Applications"
                        color: Colors.colFg
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: audioStreams

                            Rectangle {
                                width: audioColumn.width
                                height: 58
                                visible: true
                                radius: 12
                                color: streamMouse.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.14) : "transparent"
                                border.width: 1
                                border.color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18)

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "󰕾"
                                            color: Colors.colPurple
                                            font.family: root.fontFamily
                                            font.pixelSize: 13
                                        }

                                        Text {
                                            text: modelData.name
                                            color: Colors.colFg
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.volume + "%"
                                            color: Colors.colMuted
                                            font.family: root.fontFamily
                                            font.pixelSize: 11
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 6
                                        radius: 3
                                        color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.24)

                                        Rectangle {
                                            width: parent.width * Math.max(0, Math.min(1, modelData.volume / 100))
                                            height: parent.height
                                            radius: 3
                                            color: Colors.colPurple
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: mouse => {
                                                var percent = Math.max(0, Math.min(150, Math.round((mouse.x / width) * 100)))
                                                root.launchCommand(["wpctl", "set-volume", modelData.id, (percent / 100).toFixed(2)])
                                                modelData.volume = percent
                                                Qt.callLater(root.refreshAudioGraph)
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: streamMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothDropdown

        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text { text: "Bluetooth"; color: Colors.colFg; font.family: root.fontFamily; font.pixelSize: 14; font.weight: Font.Bold }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 86
                        Layout.preferredHeight: 32
                        radius: 12
                        color: Bluetooth.enabled ? Qt.rgba(Colors.colGreen.r, Colors.colGreen.g, Colors.colGreen.b, 0.16) : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.12)
                        border.width: 1
                        border.color: Bluetooth.enabled ? Qt.rgba(Colors.colGreen.r, Colors.colGreen.g, Colors.colGreen.b, 0.28) : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.2)

                        Text {
                            anchors.centerIn: parent
                            text: Bluetooth.enabled ? "Enabled" : "Disabled"
                            color: Bluetooth.enabled ? Colors.colGreen : Colors.colMuted
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Bluetooth.enabled = !Bluetooth.enabled
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: btColumn.height
                    clip: true

                    Column {
                        id: btColumn
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: Bluetooth.devices.values

                            Rectangle {
                                width: btColumn.width
                                height: 46
                                radius: 12
                                color: btMouse.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.14) : "transparent"
                                border.width: modelData.connected ? 1 : 0
                                border.color: modelData.connected ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.30) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Text {
                                        text: ""
                                        color: modelData.connected ? Colors.colBlue : Colors.colMuted
                                        font.family: root.fontFamily
                                        font.pixelSize: 14
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.name || modelData.address
                                            color: Colors.colFg
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Available")
                                            color: modelData.connected ? Colors.colBlue : Colors.colMuted
                                            font.family: root.fontFamily
                                            font.pixelSize: 10
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 88
                                        Layout.preferredHeight: 28
                                        radius: 10
                                        color: btActionMouse.containsMouse ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.18) : "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.22)

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.connected ? "Disconnect" : (modelData.paired ? "Connect" : "Pair")
                                            color: Colors.colBlue
                                            font.family: root.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            id: btActionMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (modelData.connected) {
                                                    modelData.connected = false
                                                } else if (modelData.paired) {
                                                    modelData.connected = true
                                                } else {
                                                    modelData.paired = true
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: btMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: calendarDropdown

        Item {
            id: calendarRoot
            property date viewDate: new Date()

            function daysInMonth(date) {
                return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()
            }

            function firstWeekday(date) {
                return (new Date(date.getFullYear(), date.getMonth(), 1).getDay() + 6) % 7
            }

            function monthLabel() {
                return Qt.formatDate(viewDate, "MMMM yyyy")
            }

            function dayAt(index) {
                var day = index - firstWeekday(viewDate) + 1
                return day > 0 && day <= daysInMonth(viewDate) ? day : ""
            }

            function isToday(day) {
                if (day === "") return false
                var now = new Date()
                return now.getFullYear() === viewDate.getFullYear()
                    && now.getMonth() === viewDate.getMonth()
                    && now.getDate() === day
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 10
                        color: prevMonthMouse.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18) : "transparent"

                        Text { anchors.centerIn: parent; text: ""; color: Colors.colFg; font.family: root.fontFamily; font.pixelSize: 12 }

                        MouseArea {
                            id: prevMonthMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: calendarRoot.viewDate = new Date(calendarRoot.viewDate.getFullYear(), calendarRoot.viewDate.getMonth() - 1, 1)
                        }
                    }

                    Text {
                        text: calendarRoot.monthLabel()
                        color: Colors.colFg
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 10
                        color: nextMonthMouse.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18) : "transparent"

                        Text { anchors.centerIn: parent; text: ""; color: Colors.colFg; font.family: root.fontFamily; font.pixelSize: 12 }

                        MouseArea {
                            id: nextMonthMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: calendarRoot.viewDate = new Date(calendarRoot.viewDate.getFullYear(), calendarRoot.viewDate.getMonth() + 1, 1)
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                        model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

                        Text {
                            text: modelData
                            color: Colors.colMuted
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                    }

                    Repeater {
                        model: 42

                        Rectangle {
                            property var dayValue: calendarRoot.dayAt(index)
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 10
                            color: calendarRoot.isToday(dayValue) ? Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.18) : "transparent"
                            border.width: calendarRoot.isToday(dayValue) ? 1 : 0
                            border.color: Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.28)

                            Text {
                                anchors.centerIn: parent
                                text: parent.dayValue
                                color: calendarRoot.isToday(parent.dayValue) ? Colors.colOrange : Colors.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                font.weight: calendarRoot.isToday(parent.dayValue) ? Font.Bold : Font.Normal
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: spotifyDropdown

        Item {
            RowLayout {
                anchors.fill: parent
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 152
                    Layout.preferredHeight: 152
                    radius: 16
                    color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.10)
                    clip: true

                    Item {
                        anchors.fill: parent
                        visible: spotifyCoverArt !== ""
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: 152
                                height: 152
                                radius: 16
                                visible: false
                            }
                        }

                        Image {
                            anchors.fill: parent
                            source: spotifyCoverArt
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰓇"
                        color: Colors.colMuted
                        font.family: root.fontFamily
                        font.pixelSize: 40
                        visible: spotifyCoverArt === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    Text {
                        text: spotifyTrack
                        color: Colors.colFg
                        font.family: root.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: spotifyArtist || "Spotify"
                        color: Colors.colMuted
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.22)
                    }

                    Text {
                        text: spotifyStatus
                        color: spotifyStatus === "Playing" ? Colors.colGreen : Colors.colOrange
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: [
                                { icon: "󰒮", action: "previous", accent: Colors.colBlue },
                                { icon: spotifyStatus === "Playing" ? "󰏤" : "󰐊", action: "play-pause", accent: Colors.colGreen },
                                { icon: "󰒭", action: "next", accent: Colors.colPurple }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 42
                                radius: 14
                                color: spotifyActionHover.hovered ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.16) : "transparent"
                                border.width: 1
                                border.color: Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.24)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: modelData.accent
                                    font.family: root.fontFamily
                                    font.pixelSize: 17
                                    font.weight: Font.DemiBold
                                }

                                HoverHandler {
                                    id: spotifyActionHover
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: root.launchCommand(["playerctl", "-p", "spotify", modelData.action])
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: powerDropdown

        Item {
            GridLayout {
                anchors.fill: parent
                anchors.margins: 2
                columns: 5
                rowSpacing: 12
                columnSpacing: 12

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
                        Layout.preferredHeight: parent.height - 4
                        Layout.minimumHeight: 92
                        radius: 14
                        color: powerHover.hovered ? modelData.accent : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.30)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: modelData.icon
                                color: powerHover.hovered ? Colors.colBg : modelData.accent
                                font.family: root.fontFamily
                                font.pixelSize: 22
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: modelData.label
                                color: powerHover.hovered ? Colors.colBg : Colors.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        HoverHandler {
                            id: powerHover
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: root.runPowerAction(modelData.action)
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panelWindow
            property var modelData
            property bool isHDMI: modelData.name === "HDMI-A-1"
            property bool isDP: modelData.name === "DP-2"
            property int wsOffset: isDP ? 5 : 0
            property int localActiveWsId: {
                var id = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
                var lo = wsOffset + 1
                var hi = wsOffset + 5
                return (id >= lo && id <= hi) ? id : -1
            }
            property bool showDropdown: root.dropdownName !== "" && root.dropdownScreenName === modelData.name

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: 8
                left: 10
                right: 10
                bottom: 0
            }

            focusable: true
            aboveWindows: true
            exclusiveZone: root.panelHeight + 16
            implicitHeight: root.panelHeight + 16 + root.dropdownAreaHeight
            color: "transparent"
            mask: Region {
                item: barFrame

                Region {
                    item: panelWindow.showDropdown ? dropdownBridge : null
                }

                Region {
                    item: panelWindow.showDropdown ? dropdownStem : null
                }

                Region {
                    item: panelWindow.showDropdown ? dropdownFrame : null
                }
            }

            Rectangle {
                id: barFrame
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: root.panelHeight
                radius: 10
                color: Colors.colBg
                border.width: 1
                border.color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.28)
                Rectangle {
                    id: leftModule
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 6
                        topMargin: 4
                        bottomMargin: 4
                    }
                    width: leftLayout.implicitWidth + 16
                    radius: 10
                    color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.08)
                    clip: false

                    RowLayout {
                        id: leftLayout
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.topMargin: 3
                        anchors.bottomMargin: 3
                        spacing: 6

                        Item {
                            Layout.preferredWidth: 5 * 28 + 4 * 6 + 20
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: 5

                                Rectangle {
                                    id: workspaceRect
                                    property int wsId: index + 1 + wsOffset
                                    property var workspace: Hyprland.workspaces.values.find(ws => ws.id === wsId) ?? null
                                    property bool isActive: localActiveWsId === wsId
                                    width: isActive ? 48 : 28
                                    height: isActive ? 28 : 24
                                    y: isActive ? 0 : 2
                                    radius: 10
                                    color: isActive ? Colors.colBlue : (workspaceMouse.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18) : "transparent")
                                    x: {
                                        var activeIndex = -1
                                        for (var i = 0; i < 5; i++) {
                                            if (localActiveWsId === (i + 1 + wsOffset)) {
                                                activeIndex = i
                                                break
                                            }
                                        }

                                        if (activeIndex === -1) {
                                            return index * (28 + 6)
                                        }

                                        var pos = 0
                                        for (var j = 0; j < index; j++) {
                                            pos += (j === activeIndex ? 48 : 28) + 6
                                        }

                                        return pos
                                    }

                                    Behavior on width {
                                        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                                    }

                                    Behavior on height {
                                        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                                    }

                                    Behavior on x {
                                        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                                    }

                                    Behavior on y {
                                        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: isActive ? "●" : (workspace ? "•" : "·")
                                        color: isActive ? Colors.colBg : (workspace ? Colors.colFg : Colors.colMuted)
                                        font.family: root.fontFamily
                                        font.pixelSize: isActive ? 12 : 10
                                        font.weight: isActive ? Font.Bold : Font.Normal
                                        renderType: Text.NativeRendering
                                    }

                                    MouseArea {
                                        id: workspaceMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: Hyprland.dispatch("workspace " + wsId)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                            color: Colors.colMuted
                            opacity: 0.4
                        }

                        Text {
                            text: activeWindow
                            color: Colors.colPurple
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            font.weight: Font.DemiBold
                            Layout.maximumWidth: 300
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            Layout.alignment: Qt.AlignVCenter
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                        }
                    }
                }

                Rectangle {
                    id: rightModule
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        rightMargin: 6
                        topMargin: 4
                        bottomMargin: 4
                    }
                    width: rightLayout.implicitWidth + 16
                    radius: 10
                    color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.08)
                    clip: false

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        id: rightLayout
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.topMargin: 3
                        anchors.bottomMargin: 3
                        spacing: 8

                        Widgets.PrivacyStatus {
                            id: privacyChip
                            Layout.preferredWidth: implicitWidth
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignVCenter
                            fontFamily: root.fontFamily
                            micActive: root.micInUse
                            micApps: root.micApps
                            shareActive: root.screenShareActive
                            shareApps: root.screenShareApps
                            active: dropdownName === "privacy" && dropdownScreenName === modelData.name
                            onClicked: {
                                var point = privacyChip.mapToItem(barFrame, privacyChip.width / 2, privacyChip.height)
                                root.toggleDropdown("privacy", modelData.name, point.x, 320, 184)
                            }
                        }

                        Rectangle {
                            id: statusChip
                            Layout.preferredWidth: statusText.implicitWidth + 16
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: statusMouse.containsMouse ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.12) : "transparent"
                            border.width: dropdownName === "status" && dropdownScreenName === modelData.name ? 1 : 0
                            border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.24)

                            Text {
                                id: statusText
                                anchors.centerIn: parent
                                text: "󰄨 " + cpuUsage + "% / " + memUsage + "%"
                                color: Colors.colBlue
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: statusMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    var point = statusChip.mapToItem(barFrame, statusChip.width / 2, statusChip.height)
                                    root.toggleDropdown("status", modelData.name, point.x, 440, 270)
                                }
                            }
                        }

                        Rectangle {
                            id: trayChip
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: trayMouse.containsMouse ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.12) : "transparent"
                            border.width: dropdownName === "tray" && dropdownScreenName === modelData.name ? 1 : 0
                            border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.24)

                            Text {
                                anchors.centerIn: parent
                                text: "󰀻"
                                color: Colors.colBlue
                                font.family: root.fontFamily
                                font.pixelSize: 14
                            }

                            MouseArea {
                                id: trayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    var point = trayChip.mapToItem(barFrame, trayChip.width / 2, trayChip.height)
                                    root.toggleDropdown("tray", modelData.name, point.x, 500, 420)
                                }
                            }
                        }

                        Rectangle {
                                id: audioChip
                                Layout.preferredWidth: audioText.implicitWidth + 16
                                Layout.preferredHeight: 28
                                Layout.alignment: Qt.AlignVCenter
                                radius: 12
                                color: audioMouse.containsMouse ? Qt.rgba(Colors.colPurple.r, Colors.colPurple.g, Colors.colPurple.b, 0.12) : "transparent"
                                border.width: dropdownName === "audio" && dropdownScreenName === modelData.name ? 1 : 0
                                border.color: Qt.rgba(Colors.colPurple.r, Colors.colPurple.g, Colors.colPurple.b, 0.24)

                                Text {
                                    id: audioText
                                    anchors.centerIn: parent
                                    text: root.volumeIcon() + " " + volumeLevel + "%"
                                    color: Colors.colPurple
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    id: audioMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var point = audioChip.mapToItem(barFrame, audioChip.width / 2, audioChip.height)
                                        root.toggleDropdown("audio", modelData.name, point.x, 460, 360)
                                    }
                                }
                            }

                        Rectangle {
                                id: wifiChip
                                Layout.preferredWidth: wifiText.implicitWidth + 16
                                Layout.preferredHeight: 28
                                Layout.alignment: Qt.AlignVCenter
                                radius: 12
                                color: wifiMouse.containsMouse ? Qt.rgba(root.networkAccent().r, root.networkAccent().g, root.networkAccent().b, 0.12) : "transparent"
                                border.width: dropdownName === "wifi" && dropdownScreenName === modelData.name ? 1 : 0
                                border.color: Qt.rgba(root.networkAccent().r, root.networkAccent().g, root.networkAccent().b, 0.24)

                                Text {
                                    id: wifiText
                                    anchors.centerIn: parent
                                    text: root.networkIcon()
                                    color: root.networkAccent()
                                    font.family: root.fontFamily
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: wifiMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var point = wifiChip.mapToItem(barFrame, wifiChip.width / 2, wifiChip.height)
                                        root.toggleDropdown("wifi", modelData.name, point.x, 420, 280)
                                    }
                                }
                            }

                        Rectangle {
                                id: bluetoothChip
                                Layout.preferredWidth: btText.implicitWidth + 16
                                Layout.preferredHeight: 28
                                Layout.alignment: Qt.AlignVCenter
                                radius: 12
                                color: btMouse.containsMouse ? Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.12) : "transparent"
                                border.width: dropdownName === "bluetooth" && dropdownScreenName === modelData.name ? 1 : 0
                                border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.24)

                                Text {
                                    id: btText
                                    anchors.centerIn: parent
                                    text: ""
                                    color: Bluetooth.enabled ? Colors.colBlue : Colors.colMuted
                                    font.family: root.fontFamily
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: btMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var point = bluetoothChip.mapToItem(barFrame, bluetoothChip.width / 2, bluetoothChip.height)
                                        root.toggleDropdown("bluetooth", modelData.name, point.x, 390, 250)
                                    }
                                }
                            }

                        Rectangle {
                                id: clockChip
                                Layout.preferredWidth: clockText.implicitWidth + 18
                                Layout.preferredHeight: 28
                                Layout.alignment: Qt.AlignVCenter
                                radius: 12
                                color: clockMouse.containsMouse ? Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.12) : "transparent"
                                border.width: dropdownName === "calendar" && dropdownScreenName === modelData.name ? 1 : 0
                                border.color: Qt.rgba(Colors.colOrange.r, Colors.colOrange.g, Colors.colOrange.b, 0.24)

                                Text {
                                    id: clockText
                                    anchors.centerIn: parent
                                    text: Qt.formatDateTime(new Date(), "HH:mm  ddd, dd MMM")
                                    color: Colors.colOrange
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Bold

                                    Timer {
                                        interval: 1000
                                        running: true
                                        repeat: true
                                        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm  ddd, dd MMM")
                                    }
                                }

                                MouseArea {
                                    id: clockMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var point = clockChip.mapToItem(barFrame, clockChip.width / 2, clockChip.height)
                                        root.toggleDropdown("calendar", modelData.name, point.x, 320, 255)
                                    }
                                }
                            }

                        Rectangle {
                                id: powerChip
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 28
                                Layout.alignment: Qt.AlignVCenter
                                radius: 12
                                color: powerMouse.containsMouse ? Qt.rgba(Colors.colRed.r, Colors.colRed.g, Colors.colRed.b, 0.14) : "transparent"
                                border.width: dropdownName === "power" && dropdownScreenName === modelData.name ? 1 : 0
                                border.color: Qt.rgba(Colors.colRed.r, Colors.colRed.g, Colors.colRed.b, 0.24)

                                Text {
                                    anchors.centerIn: parent
                                    text: "⏻"
                                    color: Colors.colRed
                                    font.family: root.fontFamily
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: powerMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var point = powerChip.mapToItem(barFrame, powerChip.width / 2, powerChip.height)
                                        root.toggleDropdown("power", modelData.name, point.x, 440, 150)
                                    }
                                }
                        }
                    }
                }

                Rectangle {
                    id: centerModule
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        bottom: parent.bottom
                        topMargin: 4
                        bottomMargin: 4
                    }
                    width: centerLayout.implicitWidth + 16
                    radius: 10
                    color: isHDMI ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.08) : "transparent"
                    visible: isHDMI
                    clip: false

                    RowLayout {
                        id: centerLayout
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.topMargin: 3
                        anchors.bottomMargin: 3
                        spacing: 8

                        Rectangle {
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: catLayout.implicitWidth + 12
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: Qt.rgba(root.catAccent().r, root.catAccent().g, root.catAccent().b, 0.12)
                            border.width: 1
                            border.color: Qt.rgba(root.catAccent().r, root.catAccent().g, root.catAccent().b, 0.22)

                            RowLayout {
                                id: catLayout
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: root.catMood()
                                    color: root.catAccent()
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    text: cpuUsage + "%"
                                    color: Colors.colMuted
                                    font.family: root.fontFamily
                                    font.pixelSize: 11
                                    renderType: Text.NativeRendering
                                }
                            }
                        }

                        Rectangle {
                            id: spotifyStrip
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: spotifyLayout.implicitWidth + 18
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: spotifyArtLayer.visible ? "transparent" : (spotifyStatus === "Playing" ? Colors.colGreen : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.10))
                            clip: true

                            Item {
                                id: spotifyArtLayer
                                anchors.fill: parent
                                visible: spotifyStatus === "Playing" && spotifyCoverArt !== ""
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: spotifyArtLayer.width
                                        height: spotifyArtLayer.height
                                        radius: spotifyStrip.radius
                                        visible: false
                                    }
                                }

                                Image {
                                    id: spotifyArtSource
                                    anchors.fill: parent
                                    source: spotifyCoverArt
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    visible: false
                                }

                                FastBlur {
                                    id: spotifyBlur
                                    anchors.fill: parent
                                    source: spotifyArtSource
                                    radius: 40
                                    transparentBorder: true
                                }
                            }

                            RowLayout {
                                id: spotifyLayout
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰓇"
                                    color: spotifyArtLayer.visible ? Colors.colFg : (spotifyStatus === "Playing" ? Colors.colBg : Colors.colMuted)
                                    font.family: root.fontFamily
                                    font.pixelSize: 13
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    text: (spotifyArtist ? spotifyArtist + " - " : "") + spotifyTrack
                                    color: spotifyArtLayer.visible ? Colors.colFg : (spotifyStatus === "Playing" ? Colors.colBg : Colors.colMuted)
                                    font.family: root.fontFamily
                                    font.pixelSize: root.fontSize
                                    font.weight: spotifyStatus === "Playing" ? Font.Bold : Font.DemiBold
                                    Layout.maximumWidth: 320
                                    elide: Text.ElideRight
                                    renderType: Text.NativeRendering
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        root.launchCommand(["playerctl", "-p", "spotify", "next"])
                                    } else if (mouse.button === Qt.LeftButton) {
                                        root.launchCommand(["playerctl", "-p", "spotify", "play-pause"])
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        root.launchCommand(["playerctl", "-p", "spotify", "previous"])
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: spotifyMenuChip
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: spotifyMenuArt.visible ? "transparent" : (spotifyMenuHover.containsMouse ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18) : "transparent")
                            border.width: dropdownName === "spotify" && dropdownScreenName === modelData.name ? 1 : 0
                            border.color: Qt.rgba(Colors.colGreen.r, Colors.colGreen.g, Colors.colGreen.b, 0.24)
                            clip: true

                            Item {
                                id: spotifyMenuArt
                                anchors.fill: parent
                                visible: spotifyStatus === "Playing" && spotifyCoverArt !== ""
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: spotifyMenuChip.width
                                        height: spotifyMenuChip.height
                                        radius: spotifyMenuChip.radius
                                        visible: false
                                    }
                                }

                                Image {
                                    anchors.fill: parent
                                    source: spotifyCoverArt
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    visible: false
                                }

                                FastBlur {
                                    anchors.fill: parent
                                    source: spotifyMenuArt.children[0]
                                    radius: 28
                                    transparentBorder: true
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "⋯"
                                color: spotifyMenuArt.visible ? Colors.colFg : Colors.colMuted
                                font.family: root.fontFamily
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: spotifyMenuHover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    var point = spotifyMenuChip.mapToItem(barFrame, spotifyMenuChip.width / 2, spotifyMenuChip.height)
                                    root.toggleDropdown("spotify", modelData.name, point.x, 420, 180)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: dropdownLayer
                anchors {
                    top: barFrame.bottom
                    left: parent.left
                    right: parent.right
                }
                anchors.topMargin: -8
                height: root.dropdownAreaHeight
                visible: showDropdown || dropdownShell.opacity > 0

                Item {
                    id: dropdownShell
                    property real bridgeCenterX: Math.max(56, Math.min(root.dropdownAnchorX - x, width - 56))
                    x: Math.round(Math.max(10, Math.min(root.dropdownAnchorX - root.dropdownWidth / 2, barFrame.width - root.dropdownWidth - 10)))
                    y: showDropdown ? 0 : -12
                    width: root.dropdownWidth
                    height: root.dropdownAreaHeight
                    opacity: showDropdown ? 1 : 0
                    visible: opacity > 0

                    Behavior on x {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Behavior on y {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        id: dropdownBridge
                        x: Math.round(dropdownShell.bridgeCenterX - width / 2)
                        y: 0
                        width: Math.min(124, Math.max(92, root.dropdownWidth * 0.28))
                        height: 34
                        radius: 17
                        color: Colors.colBg
                        border.width: 1
                        border.color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.28)
                    }

                    Rectangle {
                        id: dropdownStem
                        x: dropdownBridge.x + 10
                        y: 12
                        width: dropdownBridge.width - 20
                        height: 24
                        radius: 12
                        color: Colors.colBg
                    }

                    Rectangle {
                        id: dropdownFrame
                        x: 0
                        y: 18
                        width: parent.width
                        height: root.dropdownHeight
                        radius: 18
                        color: Colors.colBg
                        border.width: 1
                        border.color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.28)
                        clip: true

                        Rectangle {
                            x: dropdownBridge.x + 8
                            y: 0
                            width: dropdownBridge.width - 16
                            height: 14
                            color: Colors.colBg
                        }

                        Loader {
                            anchors.fill: parent
                            anchors.margins: 14
                            active: showDropdown
                            sourceComponent: {
                            if (root.dropdownName === "privacy") return privacyDropdown
                            if (root.dropdownName === "status") return statusDropdown
                            if (root.dropdownName === "spotify") return spotifyDropdown
                            if (root.dropdownName === "tray") return trayDropdown
                                if (root.dropdownName === "wifi") return wifiDropdown
                                if (root.dropdownName === "audio") return audioDropdown
                                if (root.dropdownName === "bluetooth") return bluetoothDropdown
                                if (root.dropdownName === "calendar") return calendarDropdown
                                if (root.dropdownName === "power") return powerDropdown
                                return null
                            }
                        }
                    }
                }
            }

            FocusScope {
                anchors.fill: parent
                focus: showDropdown

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.closeDropdown()
                        event.accepted = true
                    }
                }
            }
        }
    }
}
