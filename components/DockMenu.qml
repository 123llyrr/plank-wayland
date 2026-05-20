import QtQuick
import QtQuick.Layouts
import "../settings.js" as DockSettings
import "../i18n.js" as I18n

Rectangle {
    id: root

    property var app: null
    property var settings: null
    readonly property var theme: settings ? settings.theme : DockSettings.theme
    readonly property string configuredLanguage: settings ? settings.uiLanguage : (DockSettings.uiLanguage || "zh-CN")
    readonly property string language: configuredLanguage === "auto" ? Qt.locale().name : configuredLanguage
    readonly property color panelColor: theme.menuColor || "#ee242428"
    readonly property color panelBorderColor: theme.menuBorderColor || "#55ffffff"
    readonly property color textColor: theme.textColor || "white"
    readonly property color closeButtonColor: theme.innerBackgroundColor || "#333338"
    readonly property color closeButtonHoverColor: Qt.rgba(closeButtonColor.r, closeButtonColor.g, closeButtonColor.b, 0.85)

    signal pinRequested(var app)
    signal unpinRequested(var app)
    signal settingsRequested()
    signal closeRequested()

    function t(key) {
        return I18n.text(key, language)
    }

    implicitWidth: 210
    implicitHeight: content.implicitHeight + 20
    radius: 16
    color: panelColor
    border.color: panelBorderColor
    border.width: 1

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.app ? root.app.name : ""
                color: root.textColor
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: closeMouse.containsMouse ? root.closeButtonHoverColor : root.closeButtonColor

                Text { anchors.centerIn: parent; text: "×"; color: root.textColor; font.pixelSize: 14 }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        SettingsButton {
            Layout.fillWidth: true
            neutral: true
            text: root.app && root.app.pinned ? root.t("unpinFromDock") : root.t("pinToDock")
            onClicked: {
                if (root.app) {
                    if (root.app.pinned) root.unpinRequested(root.app)
                    else root.pinRequested(root.app)
                }
                root.closeRequested()
            }
        }

        SettingsButton {
            Layout.fillWidth: true
            neutral: true
            text: root.t("dockSettings")
            onClicked: {
                root.settingsRequested()
                root.closeRequested()
            }
        }

        SettingsButton {
            Layout.fillWidth: true
            neutral: true
            text: root.t("close")
            onClicked: root.closeRequested()
        }
    }
}
