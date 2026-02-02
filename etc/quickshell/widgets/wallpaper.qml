import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".." 

ShellRoot {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font"

    property string wallpaperDirectory: "/home/auth/.repos/caelum/wallpapers/"
    property var wallpaperFiles: []
    property int wallpaperCount: 0  

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
            color: Theme.colBg
            opacity: 0.98
            radius: 5
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15


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
                                    color: Theme.colMuted
                                    radius: 5
                                    border.color: wallpaperMouseArea.containsMouse ? Theme.colCyan : "transparent"

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
                                            color: Theme.colBg
                                            opacity: 0.9

                                            Text {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                text: modelData.split('/').pop()
                                                color: Theme.colFg
                                                font.pixelSize: 12
                                                font.family: root.fontFamily
                                                elide: Text.ElideMiddle
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        Text {
                                            visible: wallpaperMouseArea.containsMouse
                                            text: "✓"
                                            color: Theme.colCyan
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
                                            var setWallpaperProc = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
                                            setWallpaperProc.command = ["swww", "img", modelData]
                                            setWallpaperProc.running = true
                                            
                                            console.log("Setting wallpaper:", modelData)
                                            
                                            closeTimer.start()
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
