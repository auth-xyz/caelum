import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font Propo"
    property int panelHeight: 34
    property int dropdownAreaHeight: 260

    property string dropdownName: ""
    property string dropdownScreenName: ""
    property real dropdownAnchorX: 0
    property int dropdownWidth: 300
    property int dropdownHeight: 160

    property int volumeLevel: 0
    property string activeWindow: "Desktop"
    property string networkStatus: "offline"
    property string networkType: "none"
    property string networkName: "Offline"
    property string networkDevice: ""
    property string localIp: "Unavailable"
    property var wifiNetworks: []
    property date calendarDate: new Date()

    function launchCommand(command) {
        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
        proc.command = command
        proc.running = true
    }

    function workspaceStart(screenName) {
        return screenName === "DP-2" ? 6 : 1
    }

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

        if (name === "wifi") {
            wifiScanProc.running = true
        }
    }

    function setVolume(percent) {
        var clamped = Math.max(0, Math.min(100, percent))
        launchCommand(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (clamped / 100).toFixed(2)])
        volumeLevel = clamped
    }

    function adjustVolume(delta) {
        setVolume(volumeLevel + delta)
    }

    function networkLabel() {
        if (networkStatus !== "online") return "OFF"
        if (networkType === "wifi") return "WIFI"
        if (networkType === "ethernet") return "ETH"
        return "NET"
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
        case "poweroff":
            launchCommand(["systemctl", "poweroff"])
            break
        }
    }

    function monthLabel() {
        return Qt.formatDateTime(calendarDate, "MMMM yyyy")
    }

    function previousMonth() {
        calendarDate = new Date(calendarDate.getFullYear(), calendarDate.getMonth() - 1, 1)
    }

    function nextMonth() {
        calendarDate = new Date(calendarDate.getFullYear(), calendarDate.getMonth() + 1, 1)
    }

    function monthOffset() {
        var first = new Date(calendarDate.getFullYear(), calendarDate.getMonth(), 1).getDay()
        return first === 0 ? 6 : first - 1
    }

    function monthDays() {
        return new Date(calendarDate.getFullYear(), calendarDate.getMonth() + 1, 0).getDate()
    }

    function dayAt(index) {
        var day = index - monthOffset() + 1
        return day >= 1 && day <= monthDays() ? day : 0
    }

    function isToday(day) {
        if (day <= 0) return false
        var now = new Date()
        return now.getFullYear() === calendarDate.getFullYear()
            && now.getMonth() === calendarDate.getMonth()
            && now.getDate() === day
    }

    Process {
        id: volumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var match = data.match(/Volume:\s*([\d.]+)/)
                if (match) volumeLevel = Math.round(parseFloat(match[1]) * 100)
            }
        }
    }

    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
        stdout: SplitParser {
            onRead: data => activeWindow = data && data.trim() ? data.trim() : "Desktop"
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
                networkName = parts[3] || root.networkLabel()
            }
        }
    }

    Process {
        id: localIpProc
        command: ["sh", "-c", "if [ -n '" + root.networkDevice + "' ]; then nmcli -g IP4.ADDRESS device show '" + root.networkDevice + "' | head -1 | cut -d/ -f1; else echo 'Unavailable'; fi"]
        stdout: SplitParser {
            onRead: data => {
                localIp = data && data.trim() ? data.trim() : "Unavailable"
            }
        }
    }

    Process {
        id: wifiScanProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list | head -n 8"]
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
                    ssid: parts[1] || "Hidden",
                    signal: parts[2] || "--",
                    security: parts.slice(3).join(":") || "Open"
                })
            }

            wifiNetworks = parsed
            wifiScanProc.stdout.rows = []
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            volumeProc.running = true
            windowProc.running = true
            networkProc.running = true

            if (networkDevice !== "") {
                localIpProc.running = true
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            if (dropdownName === "wifi") {
                wifiScanProc.running = true
            }
        }
    }

    Component {
        id: volumeDropdown

        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Text {
                    text: "AUDIO"
                    color: Colors.colFg
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Rectangle {
                    id: volumeCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.22)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "VOL"
                                color: Colors.colMuted
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: volumeLevel + "%"
                                color: Colors.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            id: volumeTrack
                            function updateFromX(xPos) {
                                root.setVolume(Math.round((Math.max(0, Math.min(width, xPos)) / width) * 100))
                            }

                            Layout.fillWidth: true
                            Layout.preferredHeight: 10
                            color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.34)

                            Rectangle {
                                width: parent.width * (volumeLevel / 100)
                                height: parent.height
                                color: Colors.colFg
                            }

                            Rectangle {
                                width: 14
                                height: 14
                                x: Math.max(0, Math.min(parent.width - width, parent.width * (volumeLevel / 100) - width / 2))
                                y: (parent.height - height) / 2
                                color: Colors.colBg

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    color: Colors.colFg
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                onPressed: mouse => volumeTrack.updateFromX(mouse.x)
                                onPositionChanged: mouse => {
                                    if (pressed) volumeTrack.updateFromX(mouse.x)
                                }
                                onClicked: mouse => volumeTrack.updateFromX(mouse.x)
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
            }
        }
    }

    Component {
        id: wifiDropdown

        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: "NETWORK"
                    color: Colors.colFg
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    color: networkStatus === "online"
                        ? Qt.rgba(Colors.colGreen.r, Colors.colGreen.g, Colors.colGreen.b, 0.2)
                        : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.16)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Text {
                            text: root.networkLabel() + "  " + networkName
                            color: Colors.colFg
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "IP  " + localIp
                            color: Colors.colMuted
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }

                Repeater {
                    model: wifiNetworks

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        color: modelData.active === "yes"
                            ? Qt.rgba(Colors.colFg.r, Colors.colFg.g, Colors.colFg.b, 0.16)
                            : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.14)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: modelData.active === "yes" ? "ON" : "--"
                                color: modelData.active === "yes" ? Colors.colGreen : Colors.colMuted
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }

                            Text {
                                text: modelData.ssid
                                color: Colors.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.signal + "%"
                                color: Colors.colMuted
                                font.family: root.fontFamily
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                Text {
                    visible: wifiNetworks.length === 0
                    text: "No networks listed."
                    color: Colors.colMuted
                    font.family: root.fontFamily
                    font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: calendarDropdown

        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 24
                        color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18)

                        Text {
                            anchors.centerIn: parent
                            text: "<"
                            color: Colors.colFg
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.previousMonth()
                        }
                    }

                    Text {
                        text: root.monthLabel()
                        color: Colors.colFg
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 24
                        color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18)

                        Text {
                            anchors.centerIn: parent
                            text: ">"
                            color: Colors.colFg
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.nextMonth()
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 4
                    rowSpacing: 4

                    Repeater {
                        model: ["M", "T", "W", "T", "F", "S", "S"]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.16)

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: Colors.colMuted
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Repeater {
                        model: 42

                        Rectangle {
                            required property int index
                            property int day: root.dayAt(index)

                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            color: day === 0 ? "transparent"
                                : root.isToday(day)
                                    ? Colors.colFg
                                    : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.14)

                            Text {
                                anchors.centerIn: parent
                                text: parent.day > 0 ? parent.day.toString() : ""
                                color: root.isToday(parent.day) ? Colors.colBg : Colors.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
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
            RowLayout {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: [
                        { label: "LOCK", action: "lock" },
                        { label: "EXIT", action: "logout" },
                        { label: "SUSP", action: "suspend" },
                        { label: "OFF", action: "poweroff" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: powerMouse.containsMouse
                            ? Qt.rgba(Colors.colFg.r, Colors.colFg.g, Colors.colFg.b, 0.88)
                            : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.24)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: powerMouse.containsMouse ? Colors.colBg : Colors.colFg
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.runPowerAction(modelData.action)
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
            property int wsStart: root.workspaceStart(modelData.name)
            property int localActiveWsId: {
                var current = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
                return current >= wsStart && current < wsStart + 5 ? current : -1
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
                top: 0
                left: 0
                right: 0
                bottom: 0
            }

            focusable: true
            aboveWindows: true
            exclusiveZone: root.panelHeight
            implicitHeight: root.panelHeight + 8 + root.dropdownAreaHeight
            color: "transparent"
            mask: Region {
                item: brutalBar

                Region {
                    item: panelWindow.showDropdown ? dropdownBridge : null
                }

                Region {
                    item: panelWindow.showDropdown ? dropdownFrame : null
                }
            }

            Rectangle {
                id: brutalBar
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: root.panelHeight
                color: Colors.colBg

                Rectangle {
                    id: leftModule
                    anchors {
                        left: parent.left
                        leftMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    width: leftRow.implicitWidth
                    height: 24
                    color: "transparent"

                    RowLayout {
                        id: leftRow
                        anchors.fill: parent
                        spacing: 4

                        Repeater {
                            model: 5

                            Rectangle {
                                property int wsId: index + panelWindow.wsStart
                                property bool isActive: panelWindow.localActiveWsId === wsId
                                property bool exists: Hyprland.workspaces.values.find(ws => ws.id === wsId) !== null

                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                color: isActive ? Colors.colFg : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, exists ? 0.16 : 0.08)

                                Text {
                                    anchors.centerIn: parent
                                    text: wsId.toString()
                                    color: isActive ? Colors.colBg : (exists ? Colors.colFg : Colors.colMuted)
                                    font.family: root.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Hyprland.dispatch("workspace " + wsId)
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.42, 520)
                    text: activeWindow
                    color: Colors.colFg
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    id: rightModule
                    anchors {
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    width: rightRow.implicitWidth
                    height: 24
                    color: "transparent"

                    RowLayout {
                        id: rightRow
                        anchors.fill: parent
                        spacing: 6

                        Rectangle {
                            id: volumeChip
                            Layout.preferredWidth: volumeText.implicitWidth + 10
                            Layout.preferredHeight: 24
                            color: dropdownName === "volume" && dropdownScreenName === modelData.name
                                ? Qt.rgba(Colors.colFg.r, Colors.colFg.g, Colors.colFg.b, 0.18)
                                : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18)

                            Text {
                                id: volumeText
                                anchors.centerIn: parent
                                text: "VOL " + volumeLevel + "%"
                                color: Colors.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                renderType: Text.NativeRendering
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    var point = volumeChip.mapToItem(brutalBar, volumeChip.width / 2, volumeChip.height)
                                    root.toggleDropdown("volume", modelData.name, point.x, 280, 92)
                                }
                            }

                            WheelHandler {
                                onWheel: event => {
                                    root.adjustVolume(event.angleDelta.y > 0 ? 5 : -5)
                                    event.accepted = true
                                }
                            }
                        }

                        Rectangle {
                            id: wifiChip
                            Layout.preferredWidth: networkText.implicitWidth + 10
                            Layout.preferredHeight: 24
                            color: dropdownName === "wifi" && dropdownScreenName === modelData.name
                                ? Qt.rgba(Colors.colFg.r, Colors.colFg.g, Colors.colFg.b, 0.18)
                                : networkStatus === "online"
                                    ? Qt.rgba(Colors.colGreen.r, Colors.colGreen.g, Colors.colGreen.b, 0.22)
                                    : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.14)

                            Text {
                                id: networkText
                                anchors.centerIn: parent
                                text: root.networkLabel()
                                color: networkStatus === "online" ? Colors.colFg : Colors.colMuted
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                renderType: Text.NativeRendering
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var point = wifiChip.mapToItem(brutalBar, wifiChip.width / 2, wifiChip.height)
                                    root.toggleDropdown("wifi", modelData.name, point.x, 320, 208)
                                }
                            }
                        }

                        Rectangle {
                            id: clockChip
                            Layout.preferredWidth: clockText.implicitWidth + 10
                            Layout.preferredHeight: 24
                            color: dropdownName === "calendar" && dropdownScreenName === modelData.name
                                ? Qt.rgba(Colors.colFg.r, Colors.colFg.g, Colors.colFg.b, 0.18)
                                : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18)

                            Text {
                                id: clockText
                                anchors.centerIn: parent
                                text: Qt.formatDateTime(new Date(), "HH:mm  dd/MM")
                                color: Colors.colFg
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                renderType: Text.NativeRendering

                                Timer {
                                    interval: 1000
                                    running: true
                                    repeat: true
                                    onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm  dd/MM")
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var point = clockChip.mapToItem(brutalBar, clockChip.width / 2, clockChip.height)
                                    root.toggleDropdown("calendar", modelData.name, point.x, 260, 210)
                                }
                            }
                        }

                        Rectangle {
                            id: powerChip
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 24
                            color: dropdownName === "power" && dropdownScreenName === modelData.name
                                ? Qt.rgba(Colors.colRed.r, Colors.colRed.g, Colors.colRed.b, 0.9)
                                : Qt.rgba(Colors.colRed.r, Colors.colRed.g, Colors.colRed.b, 0.2)

                            Text {
                                anchors.centerIn: parent
                                text: "PWR"
                                color: dropdownName === "power" && dropdownScreenName === modelData.name ? Colors.colBg : Colors.colRed
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                renderType: Text.NativeRendering
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var point = powerChip.mapToItem(brutalBar, powerChip.width / 2, powerChip.height)
                                    root.toggleDropdown("power", modelData.name, point.x, 260, 36)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: dropdownLayer
                anchors {
                    top: brutalBar.bottom
                    left: parent.left
                    right: parent.right
                }
                anchors.topMargin: 6
                height: root.dropdownAreaHeight
                visible: panelWindow.showDropdown

                Rectangle {
                    id: dropdownBridge
                    visible: panelWindow.showDropdown
                    x: Math.round(Math.max(0, Math.min(root.dropdownAnchorX - 36, dropdownLayer.width - width)))
                    y: 0
                    width: 72
                    height: 8
                    color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18)
                }

                Rectangle {
                    id: dropdownFrame
                    visible: panelWindow.showDropdown
                    x: Math.round(Math.max(0, Math.min(root.dropdownAnchorX - root.dropdownWidth / 2, dropdownLayer.width - root.dropdownWidth)))
                    y: 8
                    width: root.dropdownWidth
                    height: root.dropdownHeight
                    color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.18)

                    Loader {
                        anchors.fill: parent
                        anchors.margins: 10
                        active: panelWindow.showDropdown
                        sourceComponent: {
                            if (root.dropdownName === "volume") return volumeDropdown
                            if (root.dropdownName === "wifi") return wifiDropdown
                            if (root.dropdownName === "calendar") return calendarDropdown
                            if (root.dropdownName === "power") return powerDropdown
                            return null
                        }
                    }
                }
            }

            FocusScope {
                anchors.fill: parent
                focus: true

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
