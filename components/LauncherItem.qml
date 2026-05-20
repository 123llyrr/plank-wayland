import QtQuick
import "."

DockItem {
    id: root

    // Custom app structure for the launcher
    app: {
        "name": "Launchpad",
        "appId": "launchpad",
        "icon": "",
        "launcherIcon": true,
        "running": false,
        "pinned": false,
        "fallback": ""
    }

    signal launchRequested()

    function trigger(button) {
        if (button === Qt.RightButton) return
        root.launchRequested()
    }
}
