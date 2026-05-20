import Quickshell
import Quickshell.Hyprland
import QtQuick
import "components"
import "services"
import "settings.js" as DockSettings

ShellRoot {
    id: root

    property var menuApp: null
    property bool menuOpen: false
    property bool settingsOpen: false
    property bool closeLayerOpen: false
    property real menuX: 0
    property real menuBottomMargin: DockSettings.dock.menuBottomMargin

    function focusToplevel(win) {
        if (!win) return false
        try {
            if (win.address) {
                const address = String(win.address).startsWith("0x") ? String(win.address) : "0x" + String(win.address)
                Hyprland.dispatch("focuswindow address:" + address)
                Hyprland.dispatch("alterzorder top,address:" + address)
                return true
            }
        } catch (e) {}
        try {
            const ipc = win.lastIpcObject
            if (ipc && ipc.address) {
                const address = String(ipc.address).startsWith("0x") ? String(ipc.address) : "0x" + String(ipc.address)
                Hyprland.dispatch("focuswindow address:" + address)
                Hyprland.dispatch("alterzorder top,address:" + address)
                return true
            }
        } catch (e) {}
        return false
    }

    function activateApp(app) {
        if (!app) return
        if (app.running && app.toplevels.length > 0) {
            const active = Hyprland.activeToplevel
            const lastIndex = typeof app.lastFocusIndex === "number" ? app.lastFocusIndex : -1
            let targetIndex = 0

            if (active && app.toplevels.length > 1) {
                const currentIndex = app.toplevels.indexOf(active)
                targetIndex = currentIndex >= 0 ? (currentIndex + 1) % app.toplevels.length : (lastIndex + 1) % app.toplevels.length
            }

            app.lastFocusIndex = targetIndex
            if (focusToplevel(app.toplevels[targetIndex])) return
        }
        Quickshell.execDetached(["sh", "-c", app.command || app.appId])
    }

    SettingsStore {
        id: settingsStore
    }

    PinnedApps {
        id: pinnedApps
        onChanged: windowModel.update()
    }

    WindowModel {
        id: windowModel
        pinnedApps: pinnedApps.apps
    }

    property bool isOverlapped: {
        if (!settingsStore.smartHide) return false
        const active = Hyprland.activeToplevel
        if (!active) return false

        // Always hide if fullscreen
        if (active.fullscreen) return true

        try {
            const ipc = active.lastIpcObject
            if (ipc && Array.isArray(ipc.at) && Array.isArray(ipc.size) && ipc.at.length >= 2 && ipc.size.length >= 2) {
                const winBottom = ipc.at[1] + ipc.size[1]
                const screenHeight = dockWindow.screen.height
                // If window is within the bottom 120 pixels of the screen
                return winBottom > (screenHeight - 120)
            }
        } catch (e) {
            console.log("SmartHide: Overlap check failed", e)
        }

        // Fallback for tiled windows if IPC is incomplete
        return !active.floating
    }

    PanelWindow {
        id: dockWindow

        anchors {
            bottom: true
        }

        margins {
            bottom: 0
        }

        color: "transparent"
        implicitWidth: dock.implicitWidth
        implicitHeight: dock.layerHeight
        exclusiveZone: (dock.hidden || !settingsStore.smartHide) ? 0 : dock.height

        Dock {
            id: dock
            anchors.horizontalCenter: parent.horizontalCenter
            apps: windowModel.dockApps
            settings: settingsStore
            smartHideEnabled: settingsStore.smartHide
            isOverlapped: root.isOverlapped
            menuOpen: root.menuOpen || root.settingsOpen
            menuApp: root.menuApp
            onActivate: app => root.activateApp(app)
            onOpenMenu: app => {
                root.menuApp = app
                root.menuX = dock.menuX
                root.menuBottomMargin = dock.menuBottomMargin
                root.menuOpen = true
            }
        }
    }

    PanelWindow {
        visible: root.menuOpen

        anchors {
            bottom: true
        }

        margins {
            bottom: root.menuBottomMargin
            left: root.menuX
        }

        color: "transparent"
        implicitWidth: dockMenu.implicitWidth
        implicitHeight: dockMenu.implicitHeight
        exclusiveZone: 0

        DockMenu {
            id: dockMenu
            anchors.fill: parent
            app: root.menuApp
            settings: settingsStore
            onPinRequested: app => pinnedApps.pin(app)
            onUnpinRequested: app => pinnedApps.unpin(app.appId)
            onSettingsRequested: {
                root.settingsOpen = true
                root.menuOpen = false
            }
            onCloseRequested: root.menuOpen = false
        }
    }

    PanelWindow {
        visible: root.settingsOpen

        anchors {
            bottom: true
            right: true
        }

        margins {
            bottom: 24
            right: 24
        }

        color: "transparent"
        implicitWidth: 420
        implicitHeight: 640
        exclusiveZone: 0

        SettingsPanel {
            anchors.fill: parent
            store: settingsStore
            onCloseRequested: root.settingsOpen = false
        }
    }
}
