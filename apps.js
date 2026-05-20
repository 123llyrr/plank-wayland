.pragma library

var items = [
    {
        "appId": "com.mitchellh.ghostty",
        "name": "Ghostty",
        "icon": "com.mitchellh.ghostty",
        "fallback": "C",
        "command": "/usr/bin/ghostty --gtk-single-instance=true"
    },
    {
        "appId": "QQ",
        "name": "QQ",
        "icon": "/usr/share/icons/linuxqq.png",
        "fallback": "Q",
        "command": "env QT_QPA_PLATFORM=wayland MOZ_ENABLE_WAYLAND=1 ELECTRON_OZONE_PLATFORM_HINT=wayland DESKTOPINTEGRATION=false /usr/bin/linuxqq --no-sandbox %U"
    },
    {
        "appId": "Alacritty",
        "name": "Alacritty",
        "icon": "/usr/share/pixmaps/Alacritty.svg",
        "fallback": "A",
        "command": "alacritty"
    },
    {
        "appId": "chromium",
        "name": "Chromium",
        "icon": "chromium",
        "fallback": "C",
        "command": "/usr/bin/chromium %U"
    },
    {
        "appId": "thunar",
        "name": "Thunar 文件管理器",
        "icon": "org.xfce.thunar",
        "fallback": "T",
        "command": "thunar %U"
    },
    {
        "appId": "io.github.kolunmi.Bazaar",
        "name": "Bazaar",
        "icon": "io.github.kolunmi.Bazaar",
        "fallback": "I",
        "command": "bazaar %U"
    },
    {
        "appId": "nwg-look",
        "name": "GTK Settings",
        "icon": "nwg-look",
        "fallback": "N",
        "command": "nwg-look"
    },
    {
        "appId": "google-chrome",
        "name": "Google Chrome",
        "icon": "google-chrome",
        "fallback": "G",
        "command": "/usr/bin/google-chrome-stable %U"
    },
    {
        "appId": "libreoffice-startcenter",
        "name": "LibreOffice",
        "icon": "libreoffice-startcenter",
        "fallback": "L",
        "command": "libreoffice %U"
    },
    {
        "appId": "top.akizip.akizip",
        "name": "Akizip",
        "icon": "top.akizip.akizip",
        "fallback": "T",
        "command": "/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=akizip --file-forwarding top.akizip.akizip @@ %F @@"
    },
    {
        "appId": "org.kde.kcalc",
        "name": "KCalc 计算器",
        "icon": "accessories-calculator",
        "fallback": "O",
        "command": "kcalc"
    },
    {
        "appId": "faugus-launcher",
        "name": "Faugus Launcher",
        "icon": "faugus-launcher",
        "fallback": "F",
        "command": "faugus-launcher %f"
    },
    {
        "appId": "com.github.tchx84.Flatseal",
        "name": "Flatseal",
        "icon": "com.github.tchx84.Flatseal",
        "fallback": "C",
        "command": "/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=com.github.tchx84.Flatseal com.github.tchx84.Flatseal"
    },
    {
        "appId": "org.kde.kate",
        "name": "Kate 编辑器",
        "icon": "kate",
        "fallback": "O",
        "command": "kate -b %U"
    },
    {
        "appId": "mpv",
        "name": "mpv 媒体播放器",
        "icon": "mpv",
        "fallback": "M",
        "command": "mpv --player-operation-mode=pseudo-gui -- %U"
    }
]
