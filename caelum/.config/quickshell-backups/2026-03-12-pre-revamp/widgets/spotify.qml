import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."

ShellRoot {
    id: root

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"

    // Spotify metadata (will be passed from main shell)
    property string currentTrack: "No track playing"
    property string currentArtist: ""
    property string currentAlbum: ""
    property string playbackStatus: "Paused"
    property string coverArtUrl: ""
    property int volume: 100
    property int position: 0
    property int length: 0

    FloatingWindow {
        id: spotifyPanel
        visible: true
        title: "qsspotify"
       
        color: "transparent"
        screen: Quickshell.screens[0]
        
        width: 400
        height: 180
        
        // Position near top-center
        Component.onCompleted: {
            if (screen) {
                var screenGeometry = screen.geometry
                x = (screenGeometry.width - width) / 2
                y = 80
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.colBg
            opacity: 0.98
            radius: 12
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // Cover Art (Left side)
                Rectangle {
                    Layout.preferredWidth: 148
                    Layout.preferredHeight: 148
                    color: Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.15)
                    radius: 8

                    Image {
                        id: coverArt
                        anchors.fill: parent
                        source: coverArtUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: coverArtUrl !== ""
                        smooth: true
                        
                        layer.enabled: true
                        layer.effect: ShaderEffect {
                            property real borderRadius: 8
                        }
                    }

                    // Fallback icon
                    Text {
                        text: ""
                        color: Colors.colMuted
                        font.pixelSize: 64
                        font.family: root.fontFamily
                        anchors.centerIn: parent
                        visible: coverArtUrl === ""
                    }
                }

                // Right side - Info and controls
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    // Track Info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: currentTrack
                            color: Colors.colFg
                            font.pixelSize: 16
                            font.family: root.fontFamily
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: currentArtist
                            color: Colors.colMuted
                            font.pixelSize: 13
                            font.family: root.fontFamily
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Progress bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            color: Colors.colMuted
                            opacity: 0.3
                            radius: 2

                            Rectangle {
                                width: length > 0 ? parent.width * (position / length) : 0
                                height: parent.height
                                color: Colors.colGreen
                                radius: 2

                                Behavior on width {
                                    NumberAnimation { duration: 200 }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: formatTime(position)
                                color: Colors.colMuted
                                font.pixelSize: 10
                                font.family: root.fontFamily
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: formatTime(length)
                                color: Colors.colMuted
                                font.pixelSize: 10
                                font.family: root.fontFamily
                            }
                        }
                    }

                    // Controls row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Volume Control
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: volume === 0 ? "󰝟" : volume < 50 ? "󰕿" : "󰕾"
                                color: Colors.colPurple
                                font.pixelSize: 16
                                font.family: root.fontFamily
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                color: Colors.colMuted
                                opacity: 0.3
                                radius: 3

                                Rectangle {
                                    width: parent.width * (volume / 100)
                                    height: parent.height
                                    color: Colors.colPurple
                                    radius: 3

                                    Behavior on width {
                                        NumberAnimation { duration: 100 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: mouse => {
                                        var newVolume = Math.round((mouse.x / width) * 100)
                                        volume = Math.max(0, Math.min(100, newVolume))
                                        
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                        proc.command = ["playerctl", "-p", "spotify", "volume", (newVolume / 100).toFixed(2)]
                                        proc.running = true
                                    }
                                }
                            }

                            Text {
                                text: volume + "%"
                                color: Colors.colPurple
                                font.pixelSize: 11
                                font.family: root.fontFamily
                                font.bold: true
                                Layout.preferredWidth: 35
                            }
                        }

                        // Playback Controls
                        RowLayout {
                            spacing: 4

                            // Previous
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                color: prevMouseArea.containsMouse ? Colors.colMuted : "transparent"
                                radius: 16
                                border.color: Colors.colMuted
                                border.width: 1

                                Text {
                                    text: "󰒮"
                                    color: Colors.colFg
                                    font.pixelSize: 14
                                    font.family: root.fontFamily
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: prevMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                        proc.command = ["playerctl", "-p", "spotify", "previous"]
                                        proc.running = true
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            // Play/Pause
                            Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                color: playMouseArea.containsMouse ? Colors.colGreen : "transparent"
                                radius: 19
                                border.color: Colors.colGreen
                                border.width: 2

                                Text {
                                    text: playbackStatus === "Playing" ? "󰏤" : "󰐊"
                                    color: playMouseArea.containsMouse ? Colors.colBg : Colors.colGreen
                                    font.pixelSize: 18
                                    font.family: root.fontFamily
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: playMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                        proc.command = ["playerctl", "-p", "spotify", "play-pause"]
                                        proc.running = true
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            // Next
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                color: nextMouseArea.containsMouse ? Colors.colMuted : "transparent"
                                radius: 16
                                border.color: Colors.colMuted
                                border.width: 1

                                Text {
                                    text: "󰒭"
                                    color: Colors.colFg
                                    font.pixelSize: 14
                                    font.family: root.fontFamily
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: nextMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                        proc.command = ["playerctl", "-p", "spotify", "next"]
                                        proc.running = true
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Helper function to format time
    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // Update metadata process
    Process {
        id: metadataProc
        command: ["sh", "-c", "playerctl -p spotify metadata --format '{{artist}}|{{title}}|{{album}}|{{status}}|{{mpris:artUrl}}|{{volume}}|{{position}}|{{mpris:length}}' 2>/dev/null || echo '||||||0|0'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split('|')
                if (parts.length >= 8) {
                    currentArtist = parts[0] || ""
                    currentTrack = parts[1] || "No track playing"
                    currentAlbum = parts[2] || ""
                    playbackStatus = parts[3] || "Paused"
                    coverArtUrl = parts[4] || ""
                    volume = Math.round(parseFloat(parts[5]) * 100) || 100
                    position = parseInt(parts[6]) / 1000000 || 0  // Convert from microseconds
                    length = parseInt(parts[7]) / 1000000 || 0     // Convert from microseconds
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Update timer
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            metadataProc.running = true
            // Update position while playing
            if (playbackStatus === "Playing") {
                position += 0.5
            }
        }
    }
}
