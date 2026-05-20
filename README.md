# plank-wayland

当前逻辑参考 Plank：

- 打开的软件会自动出现在 Dock。
- 关闭未固定的软件后，它会自动从 Dock 消失。
- 右键 Dock 图标可固定或取消固定。
- 左键图标：运行中则聚焦窗口，未运行则启动应用。

## 设置

Dock 设置在：

```text
settings.js
```

主要字段：

- `iconSize`: 基础图标大小
- `zoomEnabled`: 是否启用缩放
- `zoomPercent`: 放大比例，Plank 默认是 `150`
- `itemPadding`: 图标间距，单位按 Plank 逻辑为 IconSize 的十分之一百分比
- `horizPadding`, `topPadding`, `bottomPadding`: 边距，参考 Plank theme
- `zoomDuration`: 鼠标进入/离开 Dock 的整体 zoom 动画时间
- `launchBounceTime`, `launchBounceHeight`: 启动/点击 bounce 动画
- `autoHide`: 鼠标离开时是否自动隐藏

## 样式

样式也在 `settings.js`：

```js
var styleName = "macos"
```

可选：

- `macos`: 亮玻璃 macOS 风格
- `plank`: 深色 Plank 风格
- `glass`: 更透明的玻璃风格

每套样式可调：

- `radius`: Dock 圆角
- `backgroundColor`: Dock 背景
- `innerBackgroundColor`: 内层暗面
- `borderColor`, `borderWidth`: 边框
- `shadowColor`: 外层阴影
- `runningItemColor`: 运行中图标底色
- `tooltipColor`, `menuColor`: tooltip / 菜单颜色
- `indicatorStyle`: `dot` / `line` / `legacy`
- `indicatorColor`: 运行指示器颜色
- `pinnedBadgeColor`: 固定标记颜色

## 固定应用

固定应用保存在：

```text
apps.js
```

一般不需要手动编辑。
