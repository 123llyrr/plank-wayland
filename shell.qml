import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "components"
import "services"
import "settings.js" as DockSettings

ShellRoot {
    id: root

    property var menuApp: null
    property bool menuOpen: false
    property bool launcherOpen: false
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

    function normalizeId(id) {
        return String(id || "").toLowerCase().replace(/\.desktop$/, "")
    }

    function desktopEntryForApp(app) {
        if (!app) return null
        const candidates = [app.desktopId, app.appId, app.icon, app.name]
        for (let i = 0; i < candidates.length; i++) {
            const id = String(candidates[i] || "")
            if (!id || id.startsWith("/")) continue
            try {
                const entry = DesktopEntries.heuristicLookup(id) || DesktopEntries.byId(id) || DesktopEntries.byId(normalizeId(id))
                if (entry) return entry
            } catch (e) {}
        }
        for (let i = 0; i < candidates.length; i++) {
            const entry = scanDesktopEntry(candidates[i])
            if (entry) return entry
        }
        return null
    }

    function entryValue(entry, keys) {
        if (!entry) return ""
        for (let i = 0; i < keys.length; i++) {
            try {
                const value = entry[keys[i]]
                if (value !== undefined && value !== null && String(value)) return String(value)
            } catch (e) {}
        }
        return ""
    }

    function executableNameFromEntry(entry) {
        const exec = entryValue(entry, ["execString", "exec"])
        if (exec) {
            const first = exec.trim().split(/\s+/)[0]
            const parts = first.split("/")
            return parts[parts.length - 1]
        }
        try {
            const command = entry.command ? Array.from(entry.command) : []
            if (command.length > 0) {
                const parts = String(command[0]).split("/")
                return parts[parts.length - 1]
            }
        } catch (e) {}
        return ""
    }

    function entryMatchesId(entry, id) {
        const normalized = normalizeId(id)
        if (!normalized) return false
        const values = [
            entryValue(entry, ["id", "desktopId"]),
            entryValue(entry, ["name"]),
            entryValue(entry, ["icon"]),
            entryValue(entry, ["startupWmClass", "startupWMClass", "startupClass", "wmClass"]),
            executableNameFromEntry(entry)
        ]
        for (let i = 0; i < values.length; i++) {
            if (normalizeId(values[i]) === normalized) return true
        }
        return false
    }

    function scanDesktopEntry(id) {
        if (!id || String(id).startsWith("/")) return null
        try {
            const entries = DesktopEntries.applications.values || []
            for (let i = 0; i < entries.length; i++) {
                const entry = entries[i]
                if (entryMatchesId(entry, id)) return entry
            }
        } catch (e) {}
        return null
    }

    function commandArray(command) {
        if (!command) return []
        if (Array.isArray(command)) return command
        if (typeof command === "string") return []
        if (command.length !== undefined) return Array.from(command)
        return []
    }

    function cleanedCommandArray(command) {
        const values = commandArray(command)
        const result = []
        for (let i = 0; i < values.length; i++) {
            const part = String(values[i] || "").trim()
            if (!part || /^%[fFuUdDnNickvm]$/.test(part)) continue
            result.push(part.replace(/%%/g, "%"))
        }
        while (result.length > 1 && result[result.length - 1] === "--") result.pop()
        return result
    }

    function cleanedExec(text) {
        let exec = String(text || "")
        if (!exec) return ""
        exec = exec.replace(/%%/g, "\u0000")
        exec = exec.replace(/%[fFuUdDnNickvm]/g, "")
        exec = exec.replace(/\u0000/g, "%")
        exec = exec.replace(/\s+--\s*$/g, "")
        exec = exec.replace(/\s+/g, " ")
        return exec.trim()
    }

    function looksLikeDesktopId(command, app) {
        const text = String(command || "").trim()
        if (!text || text.indexOf(" ") >= 0 || text.indexOf("/") >= 0) return false
        if (text.indexOf(".") >= 0) return true
        const key = normalizeId(text)
        return key === normalizeId(app && app.appId) || key === normalizeId(app && app.icon)
    }

    function launchApp(app) {
        const entry = desktopEntryForApp(app)
        const arrayCommand = cleanedCommandArray(app && app.command)
        if (arrayCommand.length > 0) {
            Quickshell.execDetached(arrayCommand)
            return
        }

        const rawCommand = String((app && app.command) || "")
        const command = cleanedExec(rawCommand)
        if (command) {
            if (entry && entry.execute && looksLikeDesktopId(command, app)) {
                entry.execute()
                return
            }
            Quickshell.execDetached(["sh", "-c", command])
            return
        }

        if (entry && entry.execute) {
            entry.execute()
            return
        }

        const fallback = cleanedExec(app && app.appId)
        if (fallback) Quickshell.execDetached(["sh", "-c", fallback])
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
        launchApp(app)
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
        visible: windowModel.ready

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
        WlrLayershell.namespace: "plank-wayland-dock"

        Dock {
            id: dock
            anchors.horizontalCenter: parent.horizontalCenter
            apps: windowModel.dockApps.length > 0 ? windowModel.dockApps : windowModel.pinnedDockApps
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
            onLaunch: root.launcherOpen = !root.launcherOpen
        }
    }

    PanelWindow {
        id: launcherWindow
        visible: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusiveZone: 0
        mask: Region { item: root.launcherOpen ? launcher : null }
        WlrLayershell.namespace: "plank-wayland-launcher"
        WlrLayershell.keyboardFocus: root.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        AppLauncher {
            id: launcher
            anchors.fill: parent
            shown: root.launcherOpen
            settings: settingsStore
            onCloseRequested: root.launcherOpen = false
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
