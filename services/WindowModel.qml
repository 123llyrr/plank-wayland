import Quickshell
import Quickshell.Hyprland
import QtQuick

Item {
    id: root

    property var pinnedApps: []
    property var dockApps: []
    property string modelSignature: ""
    property bool updateScheduled: false
    property bool refreshScheduled: false
    property int refreshRetryCount: 0
    property var entryCache: ({})
    property var pendingApps: ({})
    readonly property int pendingAppTtl: 2500

    onPinnedAppsChanged: scheduleUpdate(false)

    signal appsChanged()

    Component.onCompleted: update()

    function normalizeId(id) {
        return String(id || "").toLowerCase().replace(/\.desktop$/, "")
    }

    function appIdForToplevel(toplevel) {
        if (!toplevel) return ""
        try {
            const ipc = toplevel.lastIpcObject
            if (ipc) return String(ipc.class || ipc.initialClass || ipc.appId || ipc.wm_class || "")
        } catch (e) {}
        return ""
    }

    function desktopEntry(appId) {
        if (!appId) return null
        const cacheKey = String(appId).toLowerCase()
        if (entryCache[cacheKey] !== undefined) return entryCache[cacheKey]

        const ids = [appId, cacheKey, iconForAppId(appId)]
        let foundEntry = null
        for (let i = 0; i < ids.length; i++) {
            const id = ids[i]
            try {
                foundEntry = DesktopEntries.heuristicLookup(id) || DesktopEntries.byId(id)
                if (foundEntry) break
            } catch (e) {}
        }
        entryCache[cacheKey] = foundEntry
        return foundEntry
    }

    function iconForAppId(appId) {
        const id = normalizeId(appId)
        const aliases = {
            "alacritty": ["Alacritty", "org.alacritty.Alacritty", "alacritty", "/usr/share/pixmaps/Alacritty.svg"],
            "thunar": ["org.xfce.thunar", "Thunar", "thunar"],
            "io.github.kolunmi.bazaar": ["io.github.kolunmi.Bazaar", "io.github.kolunmi.bazaar", "/usr/share/icons/hicolor/scalable/apps/io.github.kolunmi.Bazaar.svg"]
        }
        const candidates = aliases[id] || [String(appId || "").toLowerCase()]
        for (let i = 0; i < candidates.length; i++) {
            const icon = candidates[i]
            if (String(icon).startsWith("/")) return icon
            try {
                if (Quickshell.hasThemeIcon(icon)) return icon
            } catch (e) {}
        }
        return String(appId || "").toLowerCase()
    }

    function appFromId(appId, toplevels, pinned, pending) {
        const entry = pending ? null : desktopEntry(appId)
        const title = toplevels.length > 0 ? (toplevels[0].title || appId) : appId
        return {
            appId: appId,
            name: entry && entry.name ? entry.name : title,
            icon: entry && entry.icon ? entry.icon : iconForAppId(appId),
            command: entry && entry.execString ? entry.execString : appId,
            fallback: appId.length > 0 ? appId[0].toUpperCase() : "?",
            pinned: pinned,
            running: pending || toplevels.length > 0,
            pending: !!pending,
            toplevels: toplevels
        }
    }

    function appSignature(app) {
        return [app.appId, app.name, app.icon, app.command, app.pinned, app.running, app.pending, app.toplevels.length].join("|")
    }

    function rawEventName(event) {
        return String(event && event.name !== undefined ? event.name : event)
    }

    function rawEventData(event) {
        if (!event) return ""
        if (event.data !== undefined) return String(event.data)
        if (event.args !== undefined) return String(event.args)
        return ""
    }

    function openEventAppId(event) {
        const parts = rawEventData(event).split(",")
        return parts.length >= 3 ? parts[2].trim() : ""
    }

    function rememberPendingApp(appId) {
        const key = normalizeId(appId)
        if (!key) return

        const next = ({})
        for (const existing in pendingApps) next[existing] = pendingApps[existing]
        next[key] = { appId: appId, addedAt: Date.now() }
        pendingApps = next
    }

    function scheduleRefreshRetries(count) {
        refreshRetryCount = Math.max(refreshRetryCount, count)
        refreshRetryTimer.restart()
    }

    function scheduleUpdate(refresh) {
        refreshScheduled = refreshScheduled || refresh
        if (updateScheduled) return
        updateScheduled = true
        Qt.callLater(function() {
            if (root.refreshScheduled) Hyprland.refreshToplevels()
            root.refreshScheduled = false
            root.updateScheduled = false
            root.update()
        })
    }

    function update() {
        const grouped = ({})
        try {
            const wins = Hyprland.toplevels.values || []
            for (let i = 0; i < wins.length; i++) {
                const win = wins[i]
                const appId = appIdForToplevel(win)
                if (!appId) continue
                const key = normalizeId(appId)
                if (!grouped[key]) grouped[key] = { appId: appId, toplevels: [] }
                grouped[key].toplevels.push(win)
            }
        } catch (e) {}

        const now = Date.now()
        const nextPending = ({})
        for (const key in pendingApps) {
            const pending = pendingApps[key]
            if (!pending || grouped[key]) continue
            if (now - pending.addedAt > pendingAppTtl) continue
            grouped[key] = { appId: pending.appId, toplevels: [], pending: true }
            nextPending[key] = pending
        }
        let pendingChanged = false
        for (const key in pendingApps) {
            if (pendingApps[key] !== nextPending[key]) {
                pendingChanged = true
                break
            }
        }
        if (!pendingChanged) {
            for (const key in nextPending) {
                if (pendingApps[key] !== nextPending[key]) {
                    pendingChanged = true
                    break
                }
            }
        }
        if (pendingChanged) pendingApps = nextPending

        const result = []
        const used = ({})

        for (let i = 0; i < pinnedApps.length; i++) {
            const pinned = pinnedApps[i]
            const appId = pinned.appId || pinned.icon || pinned.name
            const key = normalizeId(appId)
            const running = grouped[key]
            result.push(running ? appFromId(running.appId, running.toplevels, true, !!running.pending) : {
                appId: appId,
                name: pinned.name || appId,
                icon: pinned.icon || appId,
                command: pinned.command || appId,
                fallback: pinned.fallback || (appId.length > 0 ? appId[0].toUpperCase() : "?"),
                pinned: true,
                running: false,
                pending: false,
                toplevels: []
            })
            used[key] = true
        }

        for (const key in grouped) {
            if (!used[key]) {
                const running = grouped[key]
                result.push(appFromId(running.appId, running.toplevels, false, !!running.pending))
            }
        }

        const nextSignature = result.map(appSignature).join(";;")
        if (nextSignature === modelSignature) return
        modelSignature = nextSignature
        dockApps = result
        appsChanged()
    }

    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() { root.scheduleUpdate(false) }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const name = root.rawEventName(event)
            if (name.indexOf("openwindow") >= 0) {
                root.rememberPendingApp(root.openEventAppId(event))
                root.scheduleUpdate(true)
                root.scheduleRefreshRetries(2)
                return
            }
            if (name.indexOf("closewindow") >= 0) {
                root.scheduleUpdate(true)
                root.scheduleRefreshRetries(2)
                return
            }
            // Focus and move events do not change the dock app list; avoid rebuilding on every switch.
        }
    }

    Timer {
        id: refreshRetryTimer
        interval: root.refreshRetryCount > 1 ? 80 : 160
        repeat: false
        onTriggered: {
            if (root.refreshRetryCount <= 0) return
            root.refreshRetryCount -= 1
            root.scheduleUpdate(true)
            if (root.refreshRetryCount > 0) restart()
        }
    }
}
