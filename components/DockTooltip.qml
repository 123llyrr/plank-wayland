import QtQuick
import "../settings.js" as DockSettings

Item {
    id: root

    property string text: ""
    property bool shown: false
    property var settings: null
    readonly property var theme: settings ? settings.theme : DockSettings.theme
    readonly property color bubbleColor: theme.tooltipColor || "#dd2b2b2b"
    readonly property color bubbleBorderColor: theme.tooltipBorderColor || "#44ffffff"
    readonly property color labelColor: theme.textColor || "white"

    z: 1000
    width: bubble.width
    height: bubble.height
    opacity: (shown && text.length > 0) ? 1 : 0
    visible: opacity > 0
    y: shown ? -height - 10 : -height - 6
    enabled: false // Ensure it doesn't intercept mouse events

    Behavior on opacity { NumberAnimation { duration: DockSettings.dock.fadeTime; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    Rectangle {
        id: bubble
        width: label.implicitWidth + 18
        height: label.implicitHeight + 10
        radius: 8
        color: root.bubbleColor
        border.color: root.bubbleBorderColor
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: root.labelColor
            font.pixelSize: 12
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
