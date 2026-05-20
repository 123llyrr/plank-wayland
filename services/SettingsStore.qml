import Quickshell.Io
import Quickshell
import QtQuick
import "../settings.js" as DockSettings

Item {
    id: root

    property string styleName: DockSettings.styleName
    property string uiLanguage: DockSettings.uiLanguage || "zh-CN"
    property int iconSize: DockSettings.dock.iconSize
    property int zoomPercent: DockSettings.dock.zoomPercent
    property bool zoomEnabled: DockSettings.dock.zoomEnabled
    property bool followSystemIconTheme: DockSettings.dock.followSystemIconTheme !== false
    property int iconThemeRevision: 0
    property string systemIconTheme: ""
    property bool iconThemeLoaded: false
    property var iconCache: ({})
    property var pendingIconRequests: ({})
    property bool autoHide: DockSettings.dock.autoHide
    property bool smartHide: DockSettings.dock.smartHide || false
    property string indicatorStyle: DockSettings.theme.indicatorStyle
    property int radiusAdjust: 0
    property int opacityAdjust: 0
    readonly property var theme: buildTheme(styleName, indicatorStyle)

    signal changed()

    Component.onCompleted: refreshSystemIconTheme(false)

    function styleDefaults(name) {
        const style = DockSettings.styles[name] || DockSettings.styles.macos
        return style
    }

    function alphaHex(value) {
        const bounded = Math.max(0, Math.min(255, value))
        const text = bounded.toString(16)
        return text.length === 1 ? "0" + text : text
    }

    function adjustAlpha(color, delta) {
        if (!color || color === "transparent" || color[0] !== "#" || color.length !== 9) return color
        const alpha = parseInt(color.slice(1, 3), 16)
        return "#" + alphaHex(alpha + delta) + color.slice(3)
    }

    function iniValue(text, key) {
        const lines = String(text || "").split(/\r?\n/)
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            const parts = line.split("=")
            if (parts.length >= 2 && parts[0].trim() === key) return parts.slice(1).join("=").trim()
        }
        return ""
    }

    function kdeIconTheme(text) {
        const lines = String(text || "").split(/\r?\n/)
        let inIcons = false
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (line === "[Icons]") {
                inIcons = true
                continue
            }
            if (line[0] === "[") inIcons = false
            const parts = line.split("=")
            if (inIcons && parts.length >= 2 && parts[0].trim() === "Theme") return parts.slice(1).join("=").trim()
        }
        return ""
    }

    function detectSystemIconTheme() {
        return iniValue(gtk3Settings.text(), "gtk-icon-theme-name")
            || iniValue(gtk4Settings.text(), "gtk-icon-theme-name")
            || kdeIconTheme(kdeGlobals.text())
            || Quickshell.env("QS_ICON_THEME")
            || ""
    }

    function refreshSystemIconTheme(restartOnChange) {
        const next = detectSystemIconTheme()
        const changed = next !== systemIconTheme
        if (changed) systemIconTheme = next
        if (changed) {
            iconCache = ({})
            pendingIconRequests = ({})
        }
        iconThemeRevision += 1
        iconThemeLoaded = true
    }

    function fallbackIconSource(icon, fallbackPath) {
        if (fallbackPath && String(fallbackPath).startsWith("/")) return "file://" + fallbackPath
        const path = Quickshell.iconPath(icon, true)
        return path || "image://icon/" + icon
    }

    function iconCacheKey(icon) {
        return systemIconTheme + "|" + icon
    }

    function requestIcon(icon) {
        const key = iconCacheKey(icon)
        if (pendingIconRequests[key]) return

        const next = ({})
        for (const existing in pendingIconRequests) next[existing] = pendingIconRequests[existing]
        next[key] = icon
        pendingIconRequests = next
        iconResolveTimer.restart()
    }

    function iconSource(icon, revision, fallbackPath) {
        const name = String(icon || "")
        if (!name) return fallbackIconSource(name, fallbackPath)
        if (name[0] === "/") return "file://" + name
        if (!followSystemIconTheme || !systemIconTheme) return fallbackIconSource(name, fallbackPath)

        const key = iconCacheKey(name)
        if (iconCache[key] !== undefined) {
            return iconCache[key] ? "file://" + iconCache[key] : fallbackIconSource(name, fallbackPath)
        }

        requestIcon(name)
        return fallbackIconSource(name, fallbackPath)
    }

    function resolvePendingIcons() {
        if (iconResolver.running) {
            iconResolveTimer.restart()
            return
        }

        const requests = pendingIconRequests
        pendingIconRequests = ({})

        const icons = []
        for (const key in requests) icons.push(requests[key])
        if (icons.length === 0) return

        iconResolver.exec(["python3", Quickshell.shellPath("services/resolve-icons.py"), systemIconTheme].concat(icons))
    }

    function applyResolvedIcons(text) {
        const next = ({})
        for (const key in iconCache) next[key] = iconCache[key]

        const lines = String(text || "").split(/\r?\n/)
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (!line) continue
            const splitAt = line.indexOf("\t")
            if (splitAt < 0) continue
            const icon = line.slice(0, splitAt)
            next[iconCacheKey(icon)] = line.slice(splitAt + 1)
        }

        iconCache = next
        iconThemeRevision += 1
    }

    function buildTheme(name, indicator) {
        const base = JSON.parse(JSON.stringify(styleDefaults(name)))
        base.indicatorStyle = indicator
        base.radius = Math.max(0, base.radius + radiusAdjust)
        const alphaFields = ["backgroundColor", "innerBackgroundColor", "shadowColor", "runningItemColor", "barGradientStart", "barGradientEnd", "barHighlightColor", "barBottomShadeColor", "barShadowColor"]
        for (let i = 0; i < alphaFields.length; i++) {
            const field = alphaFields[i]
            base[field] = adjustAlpha(base[field], opacityAdjust)
        }
        return base
    }

    function save() {
        const dock = {
            iconSize: iconSize,
            zoomEnabled: zoomEnabled,
            followSystemIconTheme: followSystemIconTheme,
            zoomPercent: zoomPercent,
            itemPadding: DockSettings.dock.itemPadding,
            horizPadding: DockSettings.dock.horizPadding,
            topPadding: DockSettings.dock.topPadding,
            bottomPadding: DockSettings.dock.bottomPadding,
            indicatorSize: DockSettings.dock.indicatorSize,
            zoomDuration: DockSettings.dock.zoomDuration,
            clickTime: DockSettings.dock.clickTime,
            slideTime: DockSettings.dock.slideTime,
            fadeTime: DockSettings.dock.fadeTime,
            launchBounceTime: DockSettings.dock.launchBounceTime,
            launchBounceHeight: DockSettings.dock.launchBounceHeight,
            urgentBounceTime: DockSettings.dock.urgentBounceTime,
            urgentBounceHeight: DockSettings.dock.urgentBounceHeight,
            autoHide: autoHide,
            smartHide: smartHide,
            hideOffset: DockSettings.dock.hideOffset,
            menuBottomMargin: DockSettings.dock.menuBottomMargin
        }

        const styles = JSON.parse(JSON.stringify(DockSettings.styles))
        if (styles[styleName]) styles[styleName].indicatorStyle = indicatorStyle

        const text = ".pragma library\n\n"
            + "var dock = " + JSON.stringify(dock, null, 4) + "\n\n"
            + "var styleName = " + JSON.stringify(styleName) + "\n\n"
            + "var uiLanguage = " + JSON.stringify(uiLanguage) + "\n\n"
            + "var styles = " + JSON.stringify(styles, null, 4) + "\n\n"
            + "var theme = styles[styleName] || styles.macos\n"

        file.setText(text)
        changed()
    }

    function setStyle(name) {
        styleName = name
        indicatorStyle = styleDefaults(name).indicatorStyle || "dot"
        radiusAdjust = 0
        opacityAdjust = 0
        save()
    }

    function setIconSize(value) {
        iconSize = Math.max(32, Math.min(96, value))
        save()
    }

    function setZoomPercent(value) {
        zoomPercent = Math.max(100, Math.min(300, value))
        save()
    }

    function toggleZoom() {
        zoomEnabled = !zoomEnabled
        save()
    }

    function toggleFollowSystemIconTheme() {
        followSystemIconTheme = !followSystemIconTheme
        refreshSystemIconTheme(false)
        save()
    }

    function toggleAutoHide() {
        autoHide = !autoHide
        save()
    }

    function toggleSmartHide() {
        smartHide = !smartHide
        save()
    }

    function cycleIndicator() {
        const styles = ["dot", "line", "legacy"]
        const index = styles.indexOf(indicatorStyle)
        indicatorStyle = styles[(index + 1) % styles.length]
        save()
    }

    function adjustRadius(delta) {
        radiusAdjust = Math.max(-16, Math.min(24, radiusAdjust + delta))
        changed()
    }

    function adjustOpacity(delta) {
        opacityAdjust = Math.max(-96, Math.min(96, opacityAdjust + delta))
        changed()
    }

    FileView {
        id: file
        path: "/home/liuxue/桌面/quickshell-macos-dock/settings.js"
        blockWrites: false
        atomicWrites: true
        printErrors: true
    }

    Timer {
        id: iconResolveTimer
        interval: 35
        repeat: false
        onTriggered: root.resolvePendingIcons()
    }

    Process {
        id: iconResolver
        stdout: StdioCollector { id: iconResolverStdout }
        onExited: root.applyResolvedIcons(iconResolverStdout.text)
    }

    FileView {
        id: gtk3Settings
        path: (Quickshell.env("HOME") || "") + "/.config/gtk-3.0/settings.ini"
        preload: true
        watchChanges: root.followSystemIconTheme
        printErrors: false
        onLoaded: root.refreshSystemIconTheme(false)
        onTextChanged: root.refreshSystemIconTheme(true)
        onFileChanged: reload()
    }

    FileView {
        id: gtk4Settings
        path: (Quickshell.env("HOME") || "") + "/.config/gtk-4.0/settings.ini"
        preload: true
        watchChanges: root.followSystemIconTheme
        printErrors: false
        onLoaded: root.refreshSystemIconTheme(false)
        onTextChanged: root.refreshSystemIconTheme(true)
        onFileChanged: reload()
    }

    FileView {
        id: kdeGlobals
        path: (Quickshell.env("HOME") || "") + "/.config/kdeglobals"
        preload: true
        watchChanges: root.followSystemIconTheme
        printErrors: false
        onLoaded: root.refreshSystemIconTheme(false)
        onTextChanged: root.refreshSystemIconTheme(true)
        onFileChanged: reload()
    }
}
