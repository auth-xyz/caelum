import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".." 

ShellRoot {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font"

    property string wallpaperDirectory: "/home/auth/wallpapers/"
    property var wallpaperFiles: []
    property int wallpaperCount: 0

    // Display mode: 0 = All Displays, 1 = Individual (left=DP, right=HDMI)
    property int displayMode: 0
    property string hdmiOutput: "HDMI-A-1"
    property string dpOutput: "DP-2"

    // Track which displays have been set in individual mode
    property bool hdmiSet: false
    property bool dpSet: false

    function setWallpaper(path, output) {
        if (output === "") {
            setAllProc.command = ["awww", "img", path]
            setAllProc.running = true
            console.log("Setting wallpaper:", path, "(all displays)")
            closeTimer.start()
        } else if (output === root.hdmiOutput) {
            setHdmiProc.command = ["awww", "img", "-o", output, path]
            setHdmiProc.running = true
            root.hdmiSet = true
            console.log("Setting wallpaper:", path, "on", output)
        } else {
            setDpProc.command = ["awww", "img", "-o", output, path]
            setDpProc.running = true
            root.dpSet = true
            console.log("Setting wallpaper:", path, "on", output)
        }
    }

    Process {
        id: setAllProc
        stderr: SplitParser { onRead: data => console.log("setAll STDERR:", data) }
    }
    Process {
        id: setHdmiProc
        stderr: SplitParser { onRead: data => console.log("setHdmi STDERR:", data) }
    }
    Process {
        id: setDpProc
        stderr: SplitParser { onRead: data => console.log("setDp STDERR:", data) }
    }

    Process {
        id: wallpaperListProc
        command: ["sh", "-c", "find " + root.wallpaperDirectory + " -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) | sort"]
        
        property var tempFiles: []
        
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim().length > 0) {
                    wallpaperListProc.tempFiles.push(data.trim())
                }
            }
        }
        stderr: SplitParser {
            onRead: data => {
                console.log("STDERR:", data)
            }
        }
        onExited: (code, status) => {
            console.log("Process exited with code:", code)
            console.log("Found wallpapers:", wallpaperListProc.tempFiles.length)
            root.wallpaperFiles = wallpaperListProc.tempFiles
            root.wallpaperCount = wallpaperListProc.tempFiles.length
        }
        Component.onCompleted: {
            console.log("Searching in:", root.wallpaperDirectory)
            running = true
        }
    }

    FloatingWindow {
        id: wallpaperPicker
        visible: true
        title: "qswp"
        color: "transparent"
        screen: Quickshell.screens[0]

        Rectangle {
            anchors.fill: parent
            color: Colors.colBg
            opacity: 0.98
            radius: 5
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                // --- Display mode dropdown ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Display:"
                        color: Colors.colFg
                        font.pixelSize: 13
                        font.family: root.fontFamily
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        id: dropdownButton
                        width: 180
                        height: 30
                        radius: 5
                        color: dropdownMouseArea.containsMouse ? Colors.colMuted : Qt.darker(Colors.colMuted, 1.2)
                        border.color: Colors.colCyan
                        border.width: 1

                        property var options: ["All Displays", "Individual (HDMI / DP)"]

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: dropdownButton.options[root.displayMode]
                                color: Colors.colFg
                                font.pixelSize: 12
                                font.family: root.fontFamily
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                text: dropdownPopup.visible ? "▲" : "▼"
                                color: Colors.colCyan
                                font.pixelSize: 10
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: dropdownMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: dropdownPopup.visible = !dropdownPopup.visible
                        }
                    }

                    // Hint / status label
                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (root.displayMode === 0) return "Sets wallpaper on all displays"
                            var parts = []
                            if (root.dpSet)   parts.push("DP ✓")
                            if (root.hdmiSet) parts.push("HDMI ✓")
                            var done = parts.join("  ")
                            return done.length > 0
                                ? done + "  —  Left-click → DP  |  Right-click → HDMI"
                                : "Left-click → DP  |  Right-click → HDMI"
                        }
                        color: Colors.colCyan
                        font.pixelSize: 11
                        font.family: root.fontFamily
                        opacity: 0.8
                        elide: Text.ElideRight
                    }

                    // Done button (individual mode only)
                    Rectangle {
                        visible: root.displayMode === 1
                        width: 60
                        height: 26
                        radius: 5
                        color: doneMouseArea.containsMouse ? Colors.colCyan : Qt.darker(Colors.colCyan, 1.5)
                        border.color: Colors.colCyan
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Done"
                            color: Colors.colBg
                            font.pixelSize: 12
                            font.family: root.fontFamily
                            font.bold: true
                        }

                        MouseArea {
                            id: doneMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.quit()
                        }
                    }
                }

                // Dropdown popup — floats over the grid via Item + z
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 0  // takes no space in layout
                    z: 999

                    Rectangle {
                        id: dropdownPopup
                        visible: false
                        width: 200
                        height: dropdownColumn.height + 8
                        radius: 5
                        color: Colors.colBg
                        border.color: Colors.colCyan
                        border.width: 1
                        y: 0

                        Column {
                            id: dropdownColumn
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 4
                            spacing: 2

                            Repeater {
                                model: ["All Displays", "Individual (HDMI / DP)"]

                                Rectangle {
                                    width: parent.width
                                    height: 28
                                    radius: 4
                                    color: optMouseArea.containsMouse
                                        ? Colors.colMuted
                                        : (root.displayMode === index ? Qt.darker(Colors.colMuted, 1.1) : "transparent")

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        text: (root.displayMode === index ? "● " : "  ") + modelData
                                        color: root.displayMode === index ? Colors.colCyan : Colors.colFg
                                        font.pixelSize: 12
                                        font.family: root.fontFamily
                                    }

                                    MouseArea {
                                        id: optMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            root.displayMode = index
                                            root.hdmiSet = false
                                            root.dpSet = false
                                            dropdownPopup.visible = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Flickable {
                        id: flickable
                        anchors.fill: parent
                        anchors.rightMargin: 12
                        contentHeight: wallpaperGrid.height
                        boundsBehavior: Flickable.StopAtBounds
                        
                        GridLayout {
                            id: wallpaperGrid
                            width: parent.width
                            columns: 3
                            rowSpacing: 15
                            columnSpacing: 15

                            Repeater {
                                model: root.wallpaperFiles

                                Rectangle {
                                    Layout.preferredWidth: (wallpaperGrid.width - 30) / 3
                                    Layout.preferredHeight: 180
                                    color: Colors.colMuted
                                    radius: 5
                                    border.color: wallpaperMouseArea.containsMouse ? Colors.colCyan : "transparent"

                                    layer.enabled: true
                                    layer.effect: ShaderEffect {
                                        property real corner: 10
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        radius: 5
                                        color: "black"
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: "file://" + modelData
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                            asynchronous: true

                                            Rectangle {
                                                anchors.fill: parent
                                                color: "black"
                                                opacity: wallpaperMouseArea.containsMouse ? 0.3 : 0
                                                Behavior on opacity {
                                                    NumberAnimation { duration: 150 }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 35
                                            color: Colors.colBg
                                            opacity: 0.9

                                            Text {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                text: modelData.split('/').pop()
                                                color: Colors.colFg
                                                font.pixelSize: 12
                                                font.family: root.fontFamily
                                                elide: Text.ElideMiddle
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        Text {
                                            visible: wallpaperMouseArea.containsMouse
                                            text: root.displayMode === 0 ? "✓" : "L=DP  R=HDMI"
                                            color: Colors.colCyan
                                            font.pixelSize: root.displayMode === 0 ? 48 : 14
                                            font.bold: true
                                            anchors.centerIn: parent
                                            opacity: 0.9
                                        }
                                    }

                                    MouseArea {
                                        id: wallpaperMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                                        onClicked: mouse => {
                                            if (root.displayMode === 0) {
                                                root.setWallpaper(modelData, "")
                                            } else {
                                                if (mouse.button === Qt.LeftButton) {
                                                    root.setWallpaper(modelData, root.dpOutput)
                                                } else if (mouse.button === Qt.RightButton) {
                                                    root.setWallpaper(modelData, root.hdmiOutput)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        color: Colors.colMuted
                        opacity: 0.3
                        radius: 4
                        visible: flickable.contentHeight > flickable.height

                        Rectangle {
                            id: scrollThumb
                            width: parent.width
                            height: Math.max(30, (flickable.height / flickable.contentHeight) * parent.height)
                            y: (flickable.contentY / flickable.contentHeight) * parent.height
                            color: Colors.colCyan
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

        FocusScope {
            anchors.fill: parent
            focus: true
            
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    Qt.quit()
                }
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: Qt.quit()
    }
}
