.pragma library

var zh = {
    dockSettings: "Dock 设置",
    style: "外观样式",
    iconSize: "图标大小",
    systemIconTheme: "跟随图标主题",
    currentIconTheme: "当前主题",
    unknown: "未知",
    magnification: "悬停放大",
    autoHide: "自动隐藏",
    smartHide: "智能避让",
    indicator: "运行指示器",
    fineTune: "细节微调",
    radiusMinus: "圆角 −",
    radiusPlus: "圆角 +",
    radiusShort: "圆角",
    fainter: "更淡",
    stronger: "更亮",
    opacity: "透明度",
    close: "关闭",
    pinToDock: "固定到 Dock",
    unpinFromDock: "从 Dock 移除",
    on: "开",
    off: "关",
    px: "px",
    savedHint: "修改会立即预览，点击保存写入本 Dock 的 settings.js。",
    saveChanges: "保存设置",
    saved: "已保存",
    indicator_dot: "圆点",
    indicator_line: "线条",
    indicator_legacy: "经典"
}

var en = {
    dockSettings: "Dock Settings",
    style: "Style",
    iconSize: "Icon Size",
    systemIconTheme: "System Icon Theme",
    currentIconTheme: "Current Icon Theme",
    unknown: "Unknown",
    magnification: "Magnification",
    autoHide: "Auto Hide",
    smartHide: "Smart Hide",
    indicator: "Indicator",
    fineTune: "Fine Tune",
    radiusMinus: "Radius −",
    radiusPlus: "Radius +",
    radiusShort: "R",
    fainter: "Fainter",
    stronger: "Stronger",
    opacity: "Opacity",
    close: "Close",
    pinToDock: "Pin to Dock",
    unpinFromDock: "Unpin from Dock",
    on: "On",
    off: "Off",
    px: "px",
    savedHint: "Changes preview immediately. Click save to write this Dock's settings.js.",
    saveChanges: "Save Settings",
    saved: "Saved",
    indicator_dot: "dot",
    indicator_line: "line",
    indicator_legacy: "legacy"
}

var zhStyles = {
    obsidian: "黑曜石",
    "deep-sea": "深海",
    nebula: "星云",
    frost: "霜白",
    "liquid-titanium": "液态钛",
    "onyx-gold": "黑金",
    "aurora-noir": "极光夜",
    "champagne-glass": "香槟玻璃",
    "rose-quartz": "玫瑰石英",
    "cobalt-pro": "钴蓝 Pro",
    macos: "macOS",
    "macos-dark": "暗色",
    "macos-light": "亮色",
    plank: "Plank",
    "plank-transparent": "Plank 透明",
    glass: "玻璃",
    "clear-glass": "透明玻璃",
    "black-glass": "黑玻璃",
    neon: "霓虹",
    minimal: "极简"
}

var enStyles = {
    obsidian: "Obsidian",
    "deep-sea": "Deep Sea",
    nebula: "Nebula",
    frost: "Frost",
    "liquid-titanium": "Liquid Ti",
    "onyx-gold": "Onyx Gold",
    "aurora-noir": "Aurora Noir",
    "champagne-glass": "Champagne",
    "rose-quartz": "Rose Quartz",
    "cobalt-pro": "Cobalt Pro",
    macos: "macOS",
    "macos-dark": "Dark",
    "macos-light": "Light",
    plank: "Plank",
    "plank-transparent": "Plank T",
    glass: "Glass",
    "clear-glass": "Clear",
    "black-glass": "Black",
    neon: "Neon",
    minimal: "Minimal"
}

function lang(localeName) {
    const value = String(localeName || "zh-CN").toLowerCase()
    return value.indexOf("zh") === 0 ? "zh" : "en"
}

function map(localeName) {
    return lang(localeName) === "zh" ? zh : en
}

function text(key, localeName) {
    const current = map(localeName)
    return current[key] || en[key] || key
}

function state(key, enabled, localeName) {
    const separator = lang(localeName) === "zh" ? "：" : ": "
    return text(key, localeName) + separator + text(enabled ? "on" : "off", localeName)
}

function labelValue(key, value, localeName) {
    const separator = lang(localeName) === "zh" ? "：" : ": "
    return text(key, localeName) + separator + value
}

function indicatorStyle(value, localeName) {
    return text("indicator_" + value, localeName)
}

function styleLabel(name, localeName) {
    if (lang(localeName) === "zh") return zhStyles[name] || name
    return enStyles[name] || name
}

function selected(label, active) {
    return label + (active ? "  ✓" : "")
}
