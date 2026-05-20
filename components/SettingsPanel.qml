import QtQuick
import QtQuick.Layouts
import "../settings.js" as DockSettings
import "../i18n.js" as I18n

Rectangle {
    id: root

    property var store: null
    readonly property var theme: store ? store.theme : DockSettings.theme
    readonly property string configuredLanguage: store ? store.uiLanguage : (DockSettings.uiLanguage || "zh-CN")
    readonly property string language: configuredLanguage === "auto" ? Qt.locale().name : configuredLanguage
    readonly property color panelColor: theme.menuColor || "#ee242428"
    readonly property color panelBorderColor: theme.menuBorderColor || "#55ffffff"
    readonly property color textColor: theme.textColor || "white"
    readonly property color subtleTextColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.72)
    readonly property color closeButtonColor: theme.innerBackgroundColor || "#333338"
    readonly property color closeButtonHoverColor: Qt.rgba(closeButtonColor.r, closeButtonColor.g, closeButtonColor.b, 0.85)

    signal closeRequested()

    width: 420
    height: 640
    radius: 18
    color: panelColor
    border.color: panelBorderColor
    border.width: 1

    function t(key) {
        return I18n.text(key, language)
    }

    function state(key, enabled) {
        return I18n.state(key, enabled, language)
    }

    function styleButton(name) {
        return I18n.selected(I18n.styleLabel(name, language), store && store.styleName === name)
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 14
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 10

            RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.t("dockSettings")
                color: root.textColor
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: closeMouse.containsMouse ? root.closeButtonHoverColor : root.closeButtonColor

                Text { anchors.centerIn: parent; text: "×"; color: root.textColor; font.pixelSize: 18 }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Text { text: root.t("style"); color: root.textColor; opacity: 0.75; font.pixelSize: 12 }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 8
            rowSpacing: 8

            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("obsidian"); onClicked: root.store.setStyle("obsidian") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("deep-sea"); onClicked: root.store.setStyle("deep-sea") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("nebula"); onClicked: root.store.setStyle("nebula") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("frost"); onClicked: root.store.setStyle("frost") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("liquid-titanium"); onClicked: root.store.setStyle("liquid-titanium") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("onyx-gold"); onClicked: root.store.setStyle("onyx-gold") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("aurora-noir"); onClicked: root.store.setStyle("aurora-noir") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("champagne-glass"); onClicked: root.store.setStyle("champagne-glass") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("rose-quartz"); onClicked: root.store.setStyle("rose-quartz") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("cobalt-pro"); onClicked: root.store.setStyle("cobalt-pro") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("macos"); onClicked: root.store.setStyle("macos") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("macos-dark"); onClicked: root.store.setStyle("macos-dark") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("macos-light"); onClicked: root.store.setStyle("macos-light") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("plank"); onClicked: root.store.setStyle("plank") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("plank-transparent"); onClicked: root.store.setStyle("plank-transparent") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("glass"); onClicked: root.store.setStyle("glass") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("clear-glass"); onClicked: root.store.setStyle("clear-glass") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("black-glass"); onClicked: root.store.setStyle("black-glass") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("neon"); onClicked: root.store.setStyle("neon") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("minimal"); onClicked: root.store.setStyle("minimal") }
        }

        Text { text: root.t("iconSize"); color: root.textColor; opacity: 0.75; font.pixelSize: 12 }

        RowLayout {
            Layout.fillWidth: true
            SettingsButton { settings: root.store; neutral: true; text: "−"; onClicked: root.store.setIconSize(root.store.iconSize - 4) }
            Text { text: root.store ? root.store.iconSize + " " + root.t("px") : ""; color: root.textColor; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            SettingsButton { settings: root.store; neutral: true; text: "+"; onClicked: root.store.setIconSize(root.store.iconSize + 4) }
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.state("systemIconTheme", root.store && root.store.followSystemIconTheme)
            onClicked: root.store.toggleFollowSystemIconTheme()
        }

        Text {
            Layout.fillWidth: true
            text: root.store ? I18n.labelValue("currentIconTheme", root.store.systemIconTheme || root.t("unknown"), root.language) : ""
            color: root.textColor
            opacity: 0.55
            elide: Text.ElideRight
            font.pixelSize: 11
        }

        Text { text: root.t("magnification"); color: root.textColor; opacity: 0.75; font.pixelSize: 12 }

        RowLayout {
            Layout.fillWidth: true
            SettingsButton { settings: root.store; neutral: true; text: "−"; onClicked: root.store.setZoomPercent(root.store.zoomPercent - 10) }
            Text { text: root.store ? root.store.zoomPercent + "%" : ""; color: root.textColor; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            SettingsButton { settings: root.store; neutral: true; text: "+"; onClicked: root.store.setZoomPercent(root.store.zoomPercent + 10) }
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.state("magnification", root.store && root.store.zoomEnabled)
            onClicked: root.store.toggleZoom()
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.state("autoHide", root.store && root.store.autoHide)
            onClicked: root.store.toggleAutoHide()
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.state("smartHide", root.store && root.store.smartHide)
            onClicked: root.store.toggleSmartHide()
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.store ? I18n.labelValue("indicator", I18n.indicatorStyle(root.store.indicatorStyle, root.language), root.language) : root.t("indicator")
            onClicked: root.store.cycleIndicator()
        }

        Text { text: root.t("fineTune"); color: root.textColor; opacity: 0.75; font.pixelSize: 12 }

        RowLayout {
            Layout.fillWidth: true
            SettingsButton { settings: root.store; neutral: true; text: root.t("radiusMinus"); onClicked: root.store.adjustRadius(-2) }
            Text { text: root.store ? root.t("radiusShort") + " " + (root.theme.radius || 0) : ""; color: root.textColor; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            SettingsButton { settings: root.store; neutral: true; text: root.t("radiusPlus"); onClicked: root.store.adjustRadius(2) }
        }

        RowLayout {
            Layout.fillWidth: true
            SettingsButton { settings: root.store; neutral: true; text: root.t("fainter"); onClicked: root.store.adjustOpacity(-16) }
            Text { text: root.store ? root.t("opacity") + " " + root.store.opacityAdjust : ""; color: root.textColor; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            SettingsButton { settings: root.store; neutral: true; text: root.t("stronger"); onClicked: root.store.adjustOpacity(16) }
        }

        Text {
            Layout.fillWidth: true
            text: root.t("savedHint")
            color: root.textColor
            opacity: 0.55
            wrapMode: Text.WordWrap
            font.pixelSize: 11
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: false
            text: root.store && root.store.dirty ? root.t("saveChanges") : root.t("saved")
            onClicked: if (root.store) root.store.save()
        }
        }
    }
}
