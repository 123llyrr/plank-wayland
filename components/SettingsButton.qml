import QtQuick
import QtQuick.Layouts
import "../settings.js" as DockSettings

Rectangle {
    id: root

    property string text: ""
    property var settings: null
    property bool neutral: false
    readonly property var theme: settings ? settings.theme : DockSettings.theme
    readonly property color buttonColor: neutral ? (theme.innerBackgroundColor || "#333338") : theme.menuItemColor
    readonly property color hoverColor: neutral ? Qt.rgba(buttonColor.r, buttonColor.g, buttonColor.b, 0.85) : theme.menuItemHoverColor
    readonly property color labelColor: theme.textColor || "white"
    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 32
    radius: 10
    color: mouse.containsMouse ? hoverColor : buttonColor

    Behavior on color { ColorAnimation { duration: 80 } }

    Text {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        text: root.text
        color: root.labelColor
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
