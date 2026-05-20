import Quickshell
import Quickshell.Hyprland
import QtQuick

Item {
    id: root

    property var pinnedApps: []
    readonly property var pinnedDockApps: pinnedApps.map(appFromPinned)
    property var dockApps: pinnedDockApps
    property bool ready: false
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

    function desktopEntryIds(appId) {
        const id = normalizeId(appId)
        const aliases = {
            "obs": ["com.obsproject.Studio"],
            "com.obsproject.studio": ["com.obsproject.Studio"]
        }
        const result = [appId, id]
        const extra = aliases[id] || [iconForAppId(appId)]
        for (let i = 0; i < extra.length; i++) {
            if (result.indexOf(extra[i]) < 0) result.push(extra[i])
        }
        return result
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
        const command = entryValue(entry, ["execString", "exec"])
        if (command) {
            const first = command.trim().split(/\s+/)[0]
            const parts = first.split("/")
            return parts[parts.length - 1]
        }

        try {
            const values = entry.command ? Array.from(entry.command) : []
            if (values.length > 0) {
                const parts = String(values[0]).split("/")
                return parts[parts.length - 1]
            }
        } catch (e) {}

        return ""
    }

    function entryMatchesAppId(entry, appId) {
        const id = normalizeId(appId)
        const values = [
            entryValue(entry, ["id", "desktopId"]),
            entryValue(entry, ["name"]),
            entryValue(entry, ["icon"]),
            entryValue(entry, ["startupWmClass", "startupWMClass", "startupClass", "wmClass"]),
            executableNameFromEntry(entry)
        ]

        for (let i = 0; i < values.length; i++) {
            if (normalizeId(values[i]) === id) return true
        }
        return false
    }

    function scanDesktopEntry(appId) {
        try {
            const entries = DesktopEntries.applications.values || []
            for (let i = 0; i < entries.length; i++) {
                const entry = entries[i]
                if (entryMatchesAppId(entry, appId)) return entry
            }
        } catch (e) {}
        return null
    }

    function desktopEntry(appId) {
        if (!appId) return null
        const cacheKey = String(appId).toLowerCase()
        if (entryCache[cacheKey] !== undefined) return entryCache[cacheKey]

        const ids = desktopEntryIds(appId)
        let foundEntry = null
        for (let i = 0; i < ids.length; i++) {
            const id = ids[i]
            try {
                foundEntry = DesktopEntries.heuristicLookup(id) || DesktopEntries.byId(id)
                if (foundEntry) break
            } catch (e) {}
        }
        if (!foundEntry) foundEntry = scanDesktopEntry(appId)
        entryCache[cacheKey] = foundEntry
        return foundEntry
    }

    function iconForAppId(appId) {
        const id = normalizeId(appId)
        if (id === "obs" || id === "com.obsproject.studio") return "obs"

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

    function iconAliasesForAppId(appId) {
        const id = normalizeId(appId)
        if (id === "obs" || id === "com.obsproject.studio") return ["obs", "com.obsproject.Studio"]
        return []
    }

    function entryCommand(entry, appId) {
        if (!entry) return appId
        try {
            if (entry.command && entry.command.length !== undefined) return Array.from(entry.command)
        } catch (e) {}
        return entry.execString || appId
    }

    function appFromId(appId, toplevels, pinned, pending) {
        const entry = pending ? null : desktopEntry(appId)
        const title = toplevels.length > 0 ? (toplevels[0].title || appId) : appId
        return {
            appId: appId,
            desktopId: entry && entry.id ? entry.id : "",
            name: entry && entry.name ? entry.name : title,
            icon: iconForAppId(appId) || (entry && entry.icon ? entry.icon : appId),
            iconAliases: iconAliasesForAppId(appId),
            command: entryCommand(entry, appId),
            fallback: appId.length > 0 ? appId[0].toUpperCase() : "?",
            pinned: pinned,
            running: pending || toplevels.length > 0,
            pending: !!pending,
            toplevels: toplevels
        }
    }

    function appFromPinned(pinned) {
        const appId = pinned.appId || pinned.icon || pinned.name
        const aliases = pinned.iconAliases || iconAliasesForAppId(appId)
        return {
            appId: appId,
            desktopId: pinned.desktopId || "",
            name: pinned.name || appId,
            icon: aliases.length > 0 ? aliases[0] : (pinned.icon || appId),
            iconAliases: aliases,
            command: pinned.command || appId,
            fallback: pinned.fallback || (appId.length > 0 ? appId[0].toUpperCase() : "?"),
            pinned: true,
            running: false,
            pending: false,
            toplevels: []
        }
    }

    function toplevelId(toplevel, fallbackIndex) {
        if (!toplevel) return String(fallbackIndex)
        try {
            const ipc = toplevel.lastIpcObject
            return String(toplevel.address || (ipc && ipc.address) || toplevel.title || fallbackIndex)
        } catch (e) {
            return String(toplevel.title || fallbackIndex)
        }
    }

    function toplevelSignature(toplevels) {
        const ids = []
        for (let i = 0; i < toplevels.length; i++) ids.push(toplevelId(toplevels[i], i))
        return ids.join(",")
    }

    function appSignature(app) {
        return [app.appId, app.desktopId, app.name, app.icon, app.command, app.pinned, app.running, app.pending, toplevelSignature(app.toplevels)].join("|")
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
            result.push(running ? appFromId(running.appId, running.toplevels, true, !!running.pending) : appFromPinned(pinned))
            used[key] = true
        }

        for (const key in grouped) {
            if (!used[key]) {
                const running = grouped[key]
                result.push(appFromId(running.appId, running.toplevels, false, !!running.pending))
            }
        }

        const nextSignature = result.map(appSignature).join(";;")
        if (!ready) ready = true
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
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.entryCache = ({})
            root.scheduleUpdate(false)
        }
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
