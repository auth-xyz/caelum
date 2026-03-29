import QtQuick
import QtQuick.Layouts

import ".."

Item {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font Propo"
    property bool micActive: false
    property string micApps: "Idle"
    property bool shareActive: false
    property string shareApps: "Idle"
    property bool active: false
    signal clicked()

    readonly property bool chipHovered: privacyMouse.containsMouse
    readonly property bool anyActive: micActive || shareActive

    implicitWidth: 56
    implicitHeight: 28

    Rectangle {
        id: chip
        anchors.fill: parent
        radius: 12
        color: chipHovered ? Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.12)
                           : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.06)
        border.width: active ? 1 : 0
        border.color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.24)

        Behavior on color {
            ColorAnimation { duration: 160 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 7
            anchors.rightMargin: 8
            spacing: 7

            Rectangle {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                radius: 8
                color: root.micActive ? Colors.colOrange : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.3)

                Text {
                    anchors.fill: parent
                    text: ""
                    color: root.micActive ? Colors.colBg : Colors.colFg
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }

            Rectangle {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                radius: 8
                color: root.shareActive ? Colors.colBlue : Qt.rgba(Colors.colMuted.r, Colors.colMuted.g, Colors.colMuted.b, 0.3)

                Text {
                    anchors.fill: parent
                    text: "󰍹"
                    color: root.shareActive ? Colors.colBg : Colors.colFg
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }
        }

        MouseArea {
            id: privacyMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.clicked()
        }
    }
}
