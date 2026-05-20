import QtQuick
import "../settings.js" as DockSettings

Rectangle {
    id: root

    property bool active: false
    property real itemZoom: 1
    property var settings: null
    property color customColor: "transparent"
    readonly property var theme: settings ? settings.theme : DockSettings.theme

    readonly property bool lineStyle: theme.indicatorStyle === "line"
    readonly property bool legacyStyle: theme.indicatorStyle === "legacy"
    readonly property color indicatorColor: customColor !== "transparent" ? customColor : theme.indicatorColor

    width: active ? (lineStyle ? DockSettings.dock.indicatorSize * 3.2 : DockSettings.dock.indicatorSize * Math.max(1, Math.min(itemZoom, 1.35))) : 0
    height: active ? (lineStyle ? Math.max(2, DockSettings.dock.indicatorSize / 2) : DockSettings.dock.indicatorSize) : 0
    radius: height / 2
    color: indicatorColor
    opacity: active ? (legacyStyle ? 0.65 : 0.95) : 0

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 2.4
        height: parent.height * 2.4
        radius: height / 2
        color: indicatorColor
        opacity: root.active && root.legacyStyle ? 0.18 : 0
    }
}
