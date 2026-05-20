import QtQuick
import "../settings.js" as DockSettings

Item {
    id: root

    property var apps: []
    property var settings: null
    readonly property var theme: settings ? settings.theme : DockSettings.theme
    readonly property color barGradientStart: theme.barGradientStart || theme.backgroundColor || "#44ffffff"
    readonly property color barGradientEnd: theme.barGradientEnd || theme.backgroundColor || "#44ffffff"
    property real dockMouseX: -10000
    property bool dockHovered: false
    property real zoomProgress: 0
    property bool autoHide: settings ? settings.autoHide : DockSettings.dock.autoHide
    property bool smartHideEnabled: false
    property bool isOverlapped: false
    property bool menuOpen: false
    property bool hidden: (autoHide || (smartHideEnabled && isOverlapped)) && !dockHovered && !menuOpen
    property var menuApp: null
    readonly property real menuX: menuApp ? Math.max(0, Math.min(dockMaxWidth - 210, itemCenterForApp(menuApp) - 105)) : 0
    readonly property real menuBottomMargin: layerHeight + 10

    readonly property real baseItemSize: settings ? settings.iconSize : DockSettings.dock.iconSize
    readonly property bool zoomEnabled: settings ? settings.zoomEnabled : DockSettings.dock.zoomEnabled
    readonly property real zoomPercent: (settings ? settings.zoomPercent : DockSettings.dock.zoomPercent) / 100
    readonly property real maxItemSize: baseItemSize * zoomPercent
    readonly property real dockSpacing: DockSettings.dock.itemPadding * baseItemSize / 10
    readonly property real dockPadding: Math.max(0, DockSettings.dock.horizPadding * baseItemSize / 10) + 28
    readonly property real topPadding: DockSettings.dock.topPadding * baseItemSize / 10
    readonly property real bottomPadding: DockSettings.dock.bottomPadding * baseItemSize / 10
    readonly property int totalItemCount: apps.length + 1
    readonly property real dockItemsWidth: Math.max(0, totalItemCount * baseItemSize + (totalItemCount - 1) * dockSpacing)
    readonly property real dockMaxWidth: Math.ceil(dockItemsWidth + dockPadding * 2 + (maxItemSize - baseItemSize) * 2)
    readonly property real layerHeight: Math.ceil(baseItemSize + Math.max(0, -topPadding) + bottomPadding + (maxItemSize - baseItemSize) + 40)
    readonly property real barHorizontalPadding: Math.max(6, DockSettings.dock.horizPadding * baseItemSize / 10 + 6)
    readonly property real barTopPadding: Math.max(5, topPadding > 0 ? topPadding : 5)
    readonly property real barBottomPadding: Math.max(5, bottomPadding)
    readonly property real barWidth: Math.ceil(dockItemsWidth + barHorizontalPadding * 2)
    readonly property real barHeight: Math.ceil(baseItemSize + barTopPadding + barBottomPadding)
    readonly property real barRadius: Math.min(theme.radius || 16, barHeight / 2)
    readonly property real trackerBottom: layerHeight - bottomPadding + 4
    readonly property real trackerTop: layerHeight - bottomPadding - (dockHovered ? maxItemSize : baseItemSize) - 8
    readonly property real trackerHeight: Math.max(1, trackerBottom - trackerTop)

    signal activate(var app)
    signal openMenu(var app)
    signal launch()

    function appKey(app) {
        return String((app && (app.appId || app.icon || app.name)) || "").toLowerCase().replace(/\.desktop$/, "")
    }

    function itemCenterForApp(app) {
        const key = appKey(app)
        const baseStep = baseItemSize + dockSpacing
        const baseStart = (dockMaxWidth - dockItemsWidth) / 2
        for (let i = 0; i < apps.length; i++) {
            if (appKey(apps[i]) === key) return baseStart + i * baseStep + baseItemSize / 2
        }
        return dockMaxWidth / 2
    }

    function updatePointer(mouseX) {
        hoverLeaveTimer.stop()
        if (Math.abs(dockMouseX - mouseX) > 0.5) dockMouseX = mouseX
        if (!dockHovered) dockHovered = true
    }

    function schedulePointerLeave() {
        hoverLeaveTimer.restart()
    }

    implicitWidth: dockMaxWidth
    implicitHeight: baseItemSize + topPadding + bottomPadding
    y: (layerHeight - height) + (hidden ? DockSettings.dock.hideOffset : 0)

    // The transparent layer stays larger so magnified icons have room above the bar.

    onDockHoveredChanged: zoomProgress = dockHovered ? 1 : 0

    Behavior on zoomProgress {
        NumberAnimation {
            duration: Math.max(0, DockSettings.dock.zoomDuration)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: Math.max(0, DockSettings.dock.slideTime)
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: hoverLeaveTimer
        interval: 70
        repeat: false
        onTriggered: {
            root.dockHovered = false
            root.dockMouseX = -10000
        }
    }

    // Keep the visible dock frame tight; layerHeight is only the transparent zoom hit area.
    Item {
        anchors.horizontalCenter: itemsLayer.horizontalCenter
        anchors.bottom: itemsLayer.bottom
        width: root.barWidth
        height: root.barHeight
        visible: root.totalItemCount > 0

        Rectangle {
            anchors.fill: parent
            radius: root.barRadius
            border.color: root.theme.borderColor || "#22ffffff"
            border.width: root.theme.borderWidth !== undefined ? root.theme.borderWidth : 0.5
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0; color: root.barGradientStart }
                GradientStop { position: 1; color: root.barGradientEnd }
            }
        }
    }

    Item {
        id: itemsLayer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.layerHeight

        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            y: root.trackerTop
            height: root.trackerHeight
            z: -1
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onPositionChanged: function(mouse) { root.updatePointer(mouse.x) }
            onEntered: root.updatePointer(mouseX)
            onExited: root.schedulePointerLeave()
        }


        Repeater {
            model: [null].concat(root.apps)

            Loader {
                required property var modelData
                required property int index

                sourceComponent: index === 0 ? launcherComp : itemComp

                property var app: modelData
                property int itemIndex: index
            }
        }

        Component {
            id: launcherComp
            LauncherItem {
                settings: root.settings
                dockMouseX: root.dockMouseX
                zoomProgress: root.zoomProgress
                dockWidth: root.width
                itemCount: root.apps.length + 1
                baseItemSize: root.baseItemSize
                zoomPercent: root.zoomPercent
                zoomIconSize: root.zoomEnabled ? root.maxItemSize : root.baseItemSize
                dockSpacing: root.dockSpacing
                dockItemsWidth: root.dockItemsWidth
                bottomPadding: root.bottomPadding
                layerHeight: root.layerHeight
                onPointerMoved: dockX => root.updatePointer(dockX)
                onPointerExited: root.schedulePointerLeave()
                onLaunchRequested: root.launch()
            }
        }

        Component {
            id: itemComp
            DockItem {
                app: modelData
                settings: root.settings
                itemIndex: index
                dockMouseX: root.dockMouseX
                zoomProgress: root.zoomProgress
                dockWidth: root.width
                itemCount: root.apps.length + 1
                baseItemSize: root.baseItemSize
                zoomPercent: root.zoomPercent
                zoomIconSize: root.zoomEnabled ? root.maxItemSize : root.baseItemSize
                dockSpacing: root.dockSpacing
                dockItemsWidth: root.dockItemsWidth
                bottomPadding: root.bottomPadding
                layerHeight: root.layerHeight
                onActivate: app => root.activate(app)
                onOpenMenu: app => root.openMenu(app)
                onPointerMoved: dockX => root.updatePointer(dockX)
                onPointerExited: root.schedulePointerLeave()
            }
        }
    }
}
