import Quickshell.Widgets
import Quickshell
import QtQuick
import "../settings.js" as DockSettings

Rectangle {
    id: root

    required property var app
    property var settings: null
    readonly property var theme: settings ? settings.theme : DockSettings.theme
    readonly property bool followSystemIconTheme: settings ? settings.followSystemIconTheme : (DockSettings.dock.followSystemIconTheme !== false)
    readonly property int iconThemeRevision: settings ? settings.iconThemeRevision : 0
    readonly property string rawIcon: String(root.app.icon || "")
    readonly property bool rawFileIcon: rawIcon.startsWith("/")
    readonly property string lookupIcon: rawFileIcon ? String(root.app.appId || root.app.name || "") : rawIcon
    readonly property string resolvedThemeIcon: settings ? settings.iconSource(lookupIcon, iconThemeRevision, rawFileIcon ? rawIcon : "") : resolveThemeIcon(lookupIcon, followSystemIconTheme, iconThemeRevision, rawFileIcon ? rawIcon : "")
    property int itemIndex: 0

    property real dockMouseX: -10000
    property real zoomProgress: 0
    property real dockWidth: 0
    property int itemCount: 0
    property real baseItemSize: 50
    property real zoomPercent: 1.5
    property real zoomIconSize: baseItemSize * zoomPercent
    property real dockSpacing: 8
    property real dockItemsWidth: 0
    property real bottomPadding: 0
    property real layerHeight: 118
    property bool hovered: false
    property bool bouncing: false

    signal activate(var app)
    signal openMenu(var app)
    signal pointerMoved(real dockX)
    signal pointerExited()

    readonly property real baseStep: baseItemSize + dockSpacing
    readonly property real baseStart: (dockWidth - dockItemsWidth) / 2
    readonly property real staticCenter: Math.floor(baseStart + itemIndex * baseStep + baseItemSize / 2)
    property real distanceRaw: Math.abs(dockMouseX - staticCenter)
    property real offsetBase: Math.min(distanceRaw, zoomIconSize)
    property real offsetPercent: zoomIconSize > 0 ? Math.min(1, offsetBase / zoomIconSize) : 1
    property real zoomInPercent: 1 + (zoomPercent - 1) * zoomProgress
    property real zoomShape: 1 - Math.pow(offsetPercent, 2)
    property real zoom: 1 + zoomShape * (zoomInPercent - 1)
    property real offset: offsetBase * (zoomInPercent - 1) * (1 - offsetPercent / 3)
    property real centerPosition: staticCenter + (dockMouseX > staticCenter ? -offset : offset)
    property real lift: baseItemSize * zoom / 2 - baseItemSize / 2
    property real bounceTime: 0
    property real appearProgress: 0
    readonly property real bounceLift: easingBounce(bounceTime, DockSettings.dock.launchBounceTime, 2) * baseItemSize * DockSettings.dock.launchBounceHeight
    readonly property real hitHorizontalMargin: Math.ceil(Math.max(6, (baseItemSize * zoom - baseItemSize) / 2 + 8))
    readonly property real hitTopMargin: Math.ceil(Math.max(6, lift + bounceLift + (baseItemSize * zoom - baseItemSize) + 8))

    function easingBounce(t, d, n) {
        if (d <= 0) return 0
        const p = Math.max(0, Math.min(1, t / d))
        return Math.abs(Math.sin(n * Math.PI * p) * Math.min(1, (1 - p) * (2 * n) / (2 * n - 1)))
    }

    function bounce() {
        bouncing = true
        bounceAnimation.restart()
    }

    function trigger(button) {
        if (button === Qt.RightButton) {
            root.openMenu(root.app)
            return
        }

        root.bounce()
        root.activate(root.app)
    }

    function reportPointer(localX) {
        pointerMoved(x + hitMouse.x + localX)
    }

    function resolveThemeIcon(icon, followTheme, revision, fallbackPath) {
        if (!icon) return fallbackPath ? "file://" + fallbackPath : ""
        const path = followTheme ? Quickshell.iconPath(icon, true) : ""
        return path || (fallbackPath ? "file://" + fallbackPath : "image://icon/" + icon)
    }

    SequentialAnimation {
        id: bounceAnimation
        SpringAnimation {
            target: root;
            property: "bounceTime";
            from: 0;
            to: DockSettings.dock.launchBounceTime;
            duration: DockSettings.dock.launchBounceTime;
            spring: 2;
            damping: 0.3
        }
        ScriptAction { script: root.bouncing = false }
    }

    width: baseItemSize
    height: baseItemSize
    x: centerPosition - width / 2
    y: layerHeight - baseItemSize - bottomPadding
    z: zoom
    opacity: appearProgress
    scale: 0.94 + 0.06 * appearProgress
    transformOrigin: Item.Bottom
    radius: 18
    color: app.running ? theme.runningItemColor : "transparent"

    Component.onCompleted: appearProgress = 1

    Behavior on appearProgress { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 90 } }

    Item {
        id: iconShell
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.lift + root.bounceLift
        width: root.baseItemSize
        height: root.baseItemSize
        scale: Math.max(0.1, root.zoom)
        z: root.zoom
        transformOrigin: Item.Bottom

        IconImage {
            id: iconImage
            anchors.fill: parent
            anchors.margins: 5
            source: root.resolvedThemeIcon
            asynchronous: true
            mipmap: true
            visible: status === Image.Ready
        }

        Image {
            id: fileIconImage
            anchors.fill: parent
            anchors.margins: 5
            source: ""
            mipmap: true
            smooth: true
            visible: false
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: 8
            color: Qt.hsla((root.app.appId.length * 0.137) % 1, 0.6, 0.7, 1)
            visible: !iconImage.visible && !fileIconImage.visible

            Text {
                anchors.centerIn: parent
                text: root.app.fallback
                color: "#ffffff"
                font.pixelSize: root.baseItemSize * 0.4
                font.weight: Font.Bold
            }
        }

    }

    Indicator {
        active: root.app.running
        itemZoom: root.zoom
        settings: root.settings
        customColor: root.app.running ? iconImage.palette.highlight : "transparent"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
    }

    DockTooltip {
        text: root.app.name
        shown: root.hovered && root.zoom > 1.15
        settings: root.settings
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 8
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        color: root.theme.pinnedBadgeColor
        anchors.right: iconShell.right
        anchors.top: iconShell.top
        visible: root.app.pinned
    }

    MouseArea {
        id: hitMouse
        anchors.fill: parent
        anchors.leftMargin: -root.hitHorizontalMargin
        anchors.rightMargin: -root.hitHorizontalMargin
        anchors.topMargin: -root.hitTopMargin
        anchors.bottomMargin: -2
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onEntered: {
            root.hovered = true
            root.reportPointer(mouseX)
        }
        onPositionChanged: function(mouse) { root.reportPointer(mouse.x) }
        onExited: {
            root.hovered = false
            root.pointerExited()
        }
        onPressed: function(mouse) {
            root.trigger(mouse.button)
            mouse.accepted = true
        }
    }
}
