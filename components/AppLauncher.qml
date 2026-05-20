import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    property bool shown: false
    property var settings: null
    property var allApps: []
    property string query: ""
    property real revealProgress: 0
    property bool settingsOpen: false
    property bool refreshFeedback: false
    property real refreshRotation: 0
    readonly property string layoutMode: settings ? settings.launcherLayoutMode : "auto"
    readonly property string backgroundStyle: settings ? settings.launcherBackgroundStyle : "glass"
    readonly property bool showLabels: settings ? settings.launcherShowLabels : true
    readonly property bool hoverMagnification: settings ? settings.launcherHoverMagnification : false
    readonly property bool pressFeedback: settings ? settings.launcherPressFeedback : false
    readonly property real iconScale: settings ? settings.launcherIconScale : 1
    readonly property var filteredApps: filterApps(query, allApps)
    readonly property int visibleCount: filteredApps.length
    readonly property bool screenCompact: width < 980 || height < 720
    readonly property bool fullscreen: layoutMode === "fullscreen"
    readonly property bool compact: layoutMode === "compact" || (layoutMode === "auto" && screenCompact)
    readonly property real panelWidth: Math.max(360, Math.min(width - 56, fullscreen ? width - 56 : (compact ? 960 : 1360)))
    readonly property real panelHeight: Math.max(420, Math.min(height - 76, fullscreen ? height - 76 : (compact ? 680 : 820)))

    signal closeRequested()

    visible: true
    enabled: shown
    color: "transparent"
    focus: shown

    Component.onCompleted: loadApplications()
    onShownChanged: {
        if (!shown) {
            revealProgress = 0
            settingsOpen = false
            return
        }
        query = ""
        loadApplications()
        revealProgress = 1
        Qt.callLater(function() {
            searchInput.forceActiveFocus()
            appGrid.currentIndex = visibleCount > 0 ? 0 : -1
            appGrid.jumpToPage(0)
        })
    }
    onLayoutModeChanged: resetGridPosition()
    onShowLabelsChanged: resetGridPosition()
    onIconScaleChanged: resetGridPosition()
    onCompactChanged: resetGridPosition()

    function loadApplications() {
        const values = DesktopEntries.applications.values || []
        const entries = Array.from(values)
        const seen = ({})
        const next = []

        for (let i = 0; i < entries.length; i++) {
            const app = entries[i]
            if (!app || app.noDisplay || app.hidden || !app.name) continue

            const key = String(app.id || app.name) + "|" + String(app.exec || app.execString || "")
            if (seen[key]) continue
            seen[key] = true
            next.push(app)
        }

        next.sort(function(a, b) {
            return String(a.name || "").localeCompare(String(b.name || ""))
        })
        allApps = next
    }

    function resetGridPosition() {
        if (!shown) return
        Qt.callLater(function() {
            appGrid.currentIndex = visibleCount > 0 ? 0 : -1
            appGrid.jumpToPage(0)
        })
    }

    function appText(app) {
        return [app.name, app.genericName, app.comment, app.id, executableName(app)].join(" ").toLowerCase()
    }

    function executableName(app) {
        const command = app && app.command ? app.command : []
        if (command.length > 0) {
            const parts = String(command[0]).split("/")
            return parts[parts.length - 1].split(" ")[0]
        }

        const exec = String((app && (app.exec || app.execString)) || "")
        if (!exec) return ""
        const parts = exec.split("/")
        return parts[parts.length - 1].split(" ")[0]
    }

    function filterApps(text, apps) {
        const term = String(text || "").trim().toLowerCase()
        if (!term) return apps

        const result = []
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i]
            if (appText(app).indexOf(term) >= 0) result.push(app)
        }

        result.sort(function(a, b) {
            const aName = String(a.name || "").toLowerCase()
            const bName = String(b.name || "").toLowerCase()
            const aStarts = aName.startsWith(term)
            const bStarts = bName.startsWith(term)
            if (aStarts !== bStarts) return aStarts ? -1 : 1
            return aName.localeCompare(bName)
        })
        return result
    }

    function iconSource(app) {
        const icon = String((app && app.icon) || "application-x-executable")
        const icons = obsIconAliases(app, icon)
        if (settings) return settings.iconSource(icons, settings.iconThemeRevision, icon.startsWith("/") ? icon : "")
        if (icon.startsWith("/")) return "file://" + icon
        return "image://icon/" + icon
    }

    function obsIconAliases(app, icon) {
        const id = String((app && (app.id || app.appId)) || "").toLowerCase()
        const name = String((app && app.name) || "").toLowerCase()
        const executable = executableName(app).toLowerCase()
        if (id.indexOf("obsproject") >= 0 || id === "obs" || name === "obs studio" || executable === "obs") {
            return ["obs", "com.obsproject.Studio"]
        }
        return icon
    }

    function fallbackText(app) {
        const name = String((app && app.name) || "?").trim()
        return name.length > 0 ? name[0].toUpperCase() : "?"
    }

    function cleanedExec(app) {
        let exec = String((app && (app.execString || app.exec)) || "")
        if (!exec) return ""
        exec = exec.replace(/%%/g, "\u0000")
        exec = exec.replace(/%[fFuUdDnNickvm]/g, "")
        exec = exec.replace(/\u0000/g, "%")
        return exec.trim()
    }

    function commandArray(app) {
        const command = app && app.command ? app.command : []
        if (Array.isArray(command)) return command
        if (typeof command === "string") return command ? [command] : []
        if (command.length !== undefined) return Array.from(command)
        return []
    }

    function launch(app) {
        if (!app) return
        closeRequested()
        Qt.callLater(function() {
            if (app.execute) {
                app.execute()
                return
            }

            const command = commandArray(app)
            if (command.length > 0) {
                Quickshell.execDetached(command)
                return
            }

            const exec = cleanedExec(app)
            if (exec) Quickshell.execDetached(["sh", "-c", exec])
        })
    }

    function refreshApplications() {
        loadApplications()
        refreshFeedback = true
        refreshSpin.restart()
        refreshFeedbackTimer.restart()
    }

    function setLayoutMode(value) {
        if (settings) settings.setLauncherLayoutMode(value)
    }

    function setBackgroundStyle(value) {
        if (settings) settings.setLauncherBackgroundStyle(value)
    }

    function setIconScale(value) {
        if (settings) settings.setLauncherIconScale(value)
    }

    function toggleShowLabels() {
        if (settings) settings.toggleLauncherShowLabels()
    }

    function toggleHoverMagnification() {
        if (settings) settings.toggleLauncherHoverMagnification()
    }

    function togglePressFeedback() {
        if (settings) settings.toggleLauncherPressFeedback()
    }

    function saveSettings() {
        if (settings) settings.save()
    }

    function panelColor(position) {
        if (backgroundStyle === "dark") return position === 0 ? "#f01d2138" : (position === 1 ? "#ec11182b" : "#e90c1020")
        if (backgroundStyle === "blue") return position === 0 ? "#f01d3aa0" : (position === 1 ? "#e90a3388" : "#ec082663")
        return position === 0 ? "#f02b167a" : (position === 1 ? "#ec092861" : "#e90d2f80")
    }

    function glowColor() {
        if (backgroundStyle === "dark") return "#55c8d0ff"
        if (backgroundStyle === "blue") return "#6697c8ff"
        return "#66f3f0ff"
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.loadApplications() }
    }

    NumberAnimation {
        id: refreshSpin
        target: root
        property: "refreshRotation"
        from: 0
        to: 360
        duration: 280
        easing.type: Easing.OutCubic
    }

    Timer {
        id: refreshFeedbackTimer
        interval: 900
        repeat: false
        onTriggered: root.refreshFeedback = false
    }

    Keys.onEscapePressed: {
        if (root.settingsOpen) root.settingsOpen = false
        else root.closeRequested()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: outerGlow
        width: panel.width + 58
        height: panel.height + 58
        radius: panel.radius + 28
        anchors.centerIn: panel
        color: "transparent"
        border.width: 16
        border.color: root.glowColor()
        opacity: root.revealProgress * 0.62
    }

    Rectangle {
        width: panel.width + 28
        height: panel.height + 28
        radius: panel.radius + 14
        anchors.centerIn: panel
        color: "#342859ff"
        opacity: root.revealProgress * 0.72
    }

    Rectangle {
        id: panel
        width: root.panelWidth
        height: root.panelHeight
        radius: 34
        anchors.centerIn: parent
        opacity: root.revealProgress
        scale: 1
        border.width: 1
        border.color: "#4dffffff"
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.panelColor(0) }
            GradientStop { position: 0.52; color: root.panelColor(0.52) }
            GradientStop { position: 1.0; color: root.panelColor(1) }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) { mouse.accepted = true }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 14
            radius: panel.radius - 10
            color: "#1bffffff"
            border.width: 1
            border.color: "#18ffffff"
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 42
            anchors.rightMargin: 42
            anchors.topMargin: 108
            height: 1
            color: "#18ffffff"
            visible: !root.compact
        }

        Rectangle {
            id: searchBox
            height: 46
            radius: 18
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: root.compact ? 28 : 34
            width: Math.min(parent.width - 160, 520)
            color: searchInput.activeFocus ? "#2affffff" : "#1b000000"
            border.width: 1
            border.color: searchInput.activeFocus ? "#65b6c8ff" : "#22ffffff"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "⌕"
                color: "#c8d7e3ff"
                font.pixelSize: 22
            }

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 52
                anchors.rightMargin: 18
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: "#f8fbff"
                selectionColor: "#6aa7c8ff"
                selectedTextColor: "#101329"
                text: root.query
                font.pixelSize: 18
                font.weight: Font.Medium
                onTextChanged: {
                    root.query = text
                    appGrid.currentIndex = root.visibleCount > 0 ? 0 : -1
                    Qt.callLater(function() { appGrid.jumpToPage(0) })
                }
                Keys.onEscapePressed: {
                    if (root.settingsOpen) root.settingsOpen = false
                    else root.closeRequested()
                }
                Keys.onReturnPressed: root.launch(appGrid.currentItem ? appGrid.currentItem.app : root.filteredApps[0])
                Keys.onEnterPressed: root.launch(appGrid.currentItem ? appGrid.currentItem.app : root.filteredApps[0])
            }

            Text {
                anchors.fill: searchInput
                verticalAlignment: Text.AlignVCenter
                text: "Search"
                color: "#8ee8efff"
                font.pixelSize: 18
                visible: searchInput.text.length === 0
            }
        }

        Rectangle {
            id: moreButton
            width: 42
            height: 42
            radius: 21
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: root.compact ? 30 : 56
            anchors.topMargin: root.compact ? 30 : 36
            color: moreMouse.containsMouse ? "#31ffffff" : "#14000000"
            border.width: 1
            border.color: "#2affffff"

            Text {
                anchors.centerIn: parent
                text: "•••"
                color: "#a8d7e3ff"
                font.pixelSize: 17
                font.bold: true
            }

            MouseArea {
                id: moreMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.settingsOpen = !root.settingsOpen
            }
        }

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: root.compact ? 32 : 56
            anchors.topMargin: root.compact ? 36 : 43
            text: root.visibleCount + " apps"
            color: "#82e8efff"
            font.pixelSize: 14
            font.weight: Font.Medium
            visible: !root.compact
        }

        Rectangle {
            id: settingsPanel
            z: 20
            width: Math.min(390, panel.width - 46)
            height: 486
            radius: 28
            anchors.top: moreButton.bottom
            anchors.right: moreButton.right
            anchors.topMargin: 16
            visible: root.settingsOpen
            opacity: root.settingsOpen ? 1 : 0
            color: "#f018203b"
            border.width: 1
            border.color: "#33ffffff"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(mouse) { mouse.accepted = true }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Row {
                    width: parent.width
                    height: 30

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 36
                        text: "启动器设置"
                        color: "white"
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "×"
                        color: "#c8ffffff"
                        font.pixelSize: 26
                        horizontalAlignment: Text.AlignHCenter
                        width: 32

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.settingsOpen = false
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Text { text: "显示模式"; color: "#b8ffffff"; font.pixelSize: 13; font.weight: Font.Medium }
                    Row {
                        spacing: 8
                        Repeater {
                            model: [{ "label": "自动", "value": "auto" }, { "label": "紧凑", "value": "compact" }, { "label": "全屏", "value": "fullscreen" }]
                            Rectangle {
                                width: (settingsPanel.width - 56) / 3
                                height: 36
                                radius: 12
                                color: root.layoutMode === modelData.value ? "#2d8cff" : "#24ffffff"
                                border.width: 1
                                border.color: root.layoutMode === modelData.value ? "#66caffff" : "#18ffffff"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: "white"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setLayoutMode(modelData.value)
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Text { text: "背景样式"; color: "#b8ffffff"; font.pixelSize: 13; font.weight: Font.Medium }
                    Row {
                        spacing: 8
                        Repeater {
                            model: [{ "label": "玻璃", "value": "glass" }, { "label": "蓝紫", "value": "blue" }, { "label": "深色", "value": "dark" }]
                            Rectangle {
                                width: (settingsPanel.width - 56) / 3
                                height: 36
                                radius: 12
                                color: root.backgroundStyle === modelData.value ? "#2d8cff" : "#24ffffff"
                                border.width: 1
                                border.color: root.backgroundStyle === modelData.value ? "#66caffff" : "#18ffffff"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: "white"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setBackgroundStyle(modelData.value)
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Text { text: "图标大小"; color: "#b8ffffff"; font.pixelSize: 13; font.weight: Font.Medium }
                    Row {
                        spacing: 8
                        Repeater {
                            model: [{ "label": "小", "value": 0.86 }, { "label": "默认", "value": 1.0 }, { "label": "大", "value": 1.16 }]
                            Rectangle {
                                width: (settingsPanel.width - 56) / 3
                                height: 36
                                radius: 12
                                color: Math.abs(root.iconScale - modelData.value) < 0.01 ? "#2d8cff" : "#24ffffff"
                                border.width: 1
                                border.color: Math.abs(root.iconScale - modelData.value) < 0.01 ? "#66caffff" : "#18ffffff"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: "white"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setIconScale(modelData.value)
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10

                    Row {
                        width: parent.width
                        height: 34
                        Text { width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter; text: "显示应用名称"; color: "white"; font.pixelSize: 15 }
                        Rectangle {
                            width: 52; height: 28; radius: 14; anchors.verticalCenter: parent.verticalCenter
                            color: root.showLabels ? "#2d8cff" : "#44ffffff"
                            Rectangle { width: 22; height: 22; radius: 11; y: 3; x: root.showLabels ? 27 : 3; color: "#f3f6ff" }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleShowLabels() }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 34
                        Text { width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter; text: "悬停放大"; color: "white"; font.pixelSize: 15 }
                        Rectangle {
                            width: 52; height: 28; radius: 14; anchors.verticalCenter: parent.verticalCenter
                            color: root.hoverMagnification ? "#2d8cff" : "#44ffffff"
                            Rectangle { width: 22; height: 22; radius: 11; y: 3; x: root.hoverMagnification ? 27 : 3; color: "#f3f6ff" }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleHoverMagnification() }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 34
                        Text { width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter; text: "按下反馈"; color: "white"; font.pixelSize: 15 }
                        Rectangle {
                            width: 52; height: 28; radius: 14; anchors.verticalCenter: parent.verticalCenter
                            color: root.pressFeedback ? "#2d8cff" : "#44ffffff"
                            Rectangle { width: 22; height: 22; radius: 11; y: 3; x: root.pressFeedback ? 27 : 3; color: "#f3f6ff" }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.togglePressFeedback() }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 42
                    spacing: 10

                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: parent.height
                        radius: 14
                        color: saveMouse.containsMouse || (root.settings && root.settings.dirty) ? "#2d8cff" : "#24ffffff"
                        border.width: 1
                        border.color: saveMouse.containsMouse || (root.settings && root.settings.dirty) ? "#66caffff" : "#1fffffff"

                        Text {
                            anchors.centerIn: parent
                            text: root.settings && root.settings.dirty ? "保存设置" : "已保存"
                            color: "white"
                            font.pixelSize: 15
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: saveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.saveSettings()
                        }
                    }

                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: parent.height
                        radius: 14
                        color: root.refreshFeedback ? "#2d8cff" : (refreshMouse.containsMouse ? "#38ffffff" : "#24ffffff")
                        border.width: 1
                        border.color: root.refreshFeedback ? "#66caffff" : "#1fffffff"

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "↻"
                                color: "white"
                                font.pixelSize: 17
                                font.weight: Font.Medium
                                rotation: root.refreshRotation
                            }

                            Text {
                                text: root.refreshFeedback ? "已刷新" : "刷新应用"
                                color: "white"
                                font.pixelSize: 15
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshApplications()
                        }
                    }
                }
            }
        }

        GridView {
            id: appGrid
            anchors.top: searchBox.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: pageDots.top
            anchors.topMargin: root.compact ? 22 : 56
            anchors.leftMargin: root.compact ? 30 : 70
            anchors.rightMargin: root.compact ? 30 : 70
            anchors.bottomMargin: 18
            clip: true
            cellWidth: root.compact ? 104 : 136
            cellHeight: root.showLabels ? (root.compact ? 106 : 122) : (root.compact ? 84 : 96)
            cacheBuffer: Math.max(height * 1.5, cellHeight * 4)
            model: root.filteredApps
            currentIndex: root.visibleCount > 0 ? 0 : -1
            boundsBehavior: Flickable.DragAndOvershootBounds
            flickDeceleration: 2400
            maximumFlickVelocity: 5200
            reuseItems: true

            readonly property int columnsPerPage: Math.max(1, Math.floor(width / cellWidth))
            readonly property int rowsPerPage: Math.max(1, Math.floor(height / cellHeight))
            readonly property int itemsPerPage: Math.max(1, columnsPerPage * rowsPerPage)
            readonly property int pageCount: Math.max(1, Math.ceil(root.visibleCount / itemsPerPage))
            readonly property real pageStep: Math.max(1, rowsPerPage * cellHeight)
            readonly property int currentPage: Math.max(0, Math.min(pageCount - 1, Math.round(contentY / pageStep)))

            function jumpToPage(page) {
                if (root.visibleCount <= 0) {
                    contentY = 0
                    return
                }
                const targetIndex = Math.max(0, Math.min(root.visibleCount - 1, page * itemsPerPage))
                positionViewAtIndex(targetIndex, GridView.Beginning)
            }

            delegate: Item {
                id: appItem
                required property var modelData
                required property int index
                property var app: modelData
                property bool hovered: false
                property bool pressed: false
                property real itemIconSize: (root.compact ? 58 : 70) * root.iconScale

                width: appGrid.cellWidth
                height: appGrid.cellHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: appGrid.cellWidth - 16
                    height: appGrid.cellHeight - 8
                    radius: 22
                    color: appItem.hovered || appGrid.currentIndex === appItem.index ? "#22ffffff" : "transparent"
                    border.width: appItem.hovered || appGrid.currentIndex === appItem.index ? 1 : 0
                    border.color: "#24ffffff"

                    Item {
                        id: iconBox
                        width: appItem.itemIconSize
                        height: appItem.itemIconSize
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: root.compact ? 8 : 10
                        scale: root.pressFeedback && appItem.pressed ? 0.94 : (root.hoverMagnification && appItem.hovered ? 1.08 : 1)

                        IconImage {
                            id: iconImage
                            anchors.fill: parent
                            source: root.iconSource(appItem.app)
                            asynchronous: true
                            mipmap: true
                            visible: status === Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#5c6d8cff" }
                                GradientStop { position: 1.0; color: "#46335cff" }
                            }
                            visible: !iconImage.visible

                            Text {
                                anchors.centerIn: parent
                                text: root.fallbackText(appItem.app)
                                color: "white"
                                font.pixelSize: root.compact ? 23 : 28
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: iconBox.bottom
                        anchors.topMargin: root.compact ? 7 : 9
                        horizontalAlignment: Text.AlignHCenter
                        text: appItem.app.name || "Unknown"
                        color: "#f5ffffff"
                        font.pixelSize: root.compact ? 12 : 14
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        visible: root.showLabels
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: appItem.hovered = true
                    onExited: {
                        appItem.hovered = false
                        appItem.pressed = false
                    }
                    onPressed: appItem.pressed = true
                    onReleased: appItem.pressed = false
                    onCanceled: appItem.pressed = false
                    onClicked: root.launch(appItem.app)
                }
            }
        }

        Text {
            anchors.centerIn: appGrid
            text: root.query ? "没有找到匹配应用" : "没有可启动的应用"
            color: "#bfe8efff"
            font.pixelSize: 20
            font.weight: Font.Medium
            visible: root.visibleCount === 0
        }

        Row {
            id: pageDots
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.compact ? 18 : 30
            spacing: 10
            visible: appGrid.pageCount > 1

            Repeater {
                model: appGrid.pageCount

                Rectangle {
                    width: appGrid.currentPage === index ? 10 : 8
                    height: width
                    radius: width / 2
                    color: appGrid.currentPage === index ? "#d8ffffff" : "#42ffffff"

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appGrid.jumpToPage(index)
                    }
                }
            }
        }
    }
}
