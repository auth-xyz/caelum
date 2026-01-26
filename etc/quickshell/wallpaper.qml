import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    Theme {
        id: theme
    }

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"

    // Wallpaper configuration
    property string wallpaperDirectory: "/home/auth/.repos/caelum/wallpapers/"
    property var wallpaperFiles: []
    property int wallpaperCount: 0  // Helper to trigger UI updates

    // Load wallpaper list on startup
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
            // Assign all at once to trigger Repeater update
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
        
        width: 1000
        height: 700
        
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
            color: theme.colBg
            opacity: 0.98
            radius: 12
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "󰸉 Select Wallpaper"
                        color: theme.colCyan
                        font.pixelSize: 24
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.wallpaperCount + " wallpapers"
                        color: theme.colMuted
                        font.pixelSize: 14
                        font.family: root.fontFamily
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        color: closeMouseArea.containsMouse ? theme.colCyan : "transparent"
                        radius: 8
                        border.color: theme.colCyan
                        border.width: 2

                        Text {
                            text: "✕"
                            color: closeMouseArea.containsMouse ? theme.colBg : theme.colCyan
                            font.pixelSize: 20
                            font.bold: true
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.quit()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    color: theme.colMuted
                }

                // Scrollable area with custom scrollbar
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
                                    color: theme.colMuted
                                    radius: 10
                                    border.color: wallpaperMouseArea.containsMouse ? theme.colCyan : "transparent"
                                    border.width: 3

                                    layer.enabled: true
                                    layer.effect: ShaderEffect {
                                        property real corner: 10
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        radius: 8
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

                                        // Filename overlay
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 35
                                            color: theme.colBg
                                            opacity: 0.9

                                            Text {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                text: modelData.split('/').pop()
                                                color: theme.colFg
                                                font.pixelSize: 12
                                                font.family: root.fontFamily
                                                elide: Text.ElideMiddle
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        // Hover icon
                                        Text {
                                            visible: wallpaperMouseArea.containsMouse
                                            text: "✓"
                                            color: theme.colCyan
                                            font.pixelSize: 48
                                            font.bold: true
                                            anchors.centerIn: parent
                                            opacity: 0.9
                                        }
                                    }

                                    MouseArea {
                                        id: wallpaperMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        
                                        onClicked: {
                                            // Set wallpaper using swww
                                            var setWallpaperProc = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
                                            setWallpaperProc.command = ["swww", "img", modelData]
                                            setWallpaperProc.running = true
                                            
                                            console.log("Setting wallpaper:", modelData)
                                            
                                            // Close picker after short delay
                                            closeTimer.start()
                                        }
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
                        color: theme.colMuted
                        opacity: 0.3
                        radius: 4
                        visible: flickable.contentHeight > flickable.height

                        Rectangle {
                            id: scrollThumb
                            width: parent.width
                            height: Math.max(30, (flickable.height / flickable.contentHeight) * parent.height)
                            y: (flickable.contentY / flickable.contentHeight) * parent.height
                            color: theme.colCyan
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

                // Footer
                Text {
                    text: "Click a wallpaper to apply • Press ESC or click ✕ to close"
                    color: theme.colMuted
                    font.pixelSize: 12
                    font.family: root.fontFamily
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // ESC key handling via FocusScope
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

    // Timer to close after wallpaper selection
    Timer {
        id: closeTimer
        interval: 200
        onTriggered: Qt.quit()
    }
}
