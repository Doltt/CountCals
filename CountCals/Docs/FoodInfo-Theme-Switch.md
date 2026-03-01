# Food Info 界面切换暗黑/亮色模式不立即生效的原因

## 现象（以实际为准）

- 在设置里切换浅色/深色后，**当前任意页面（包括 Food Info）都不会立刻变**。
- **返回再进一次** Food Info 也**不会**变。
- 只有**杀死 App 再打开**，新主题才会生效。

说明问题不在「Food Info 这一页」或「导航栈」，而在**整窗的主题在运行期间根本没有被重新应用**。

## 正确原因：主题写在 App 根上，运行中不会重新生效

### 1. 主题现在写在哪

在 `CountCalsApp.swift` 里：

```swift
@main
struct CountCalsApp: App {
    @State private var settings = AppSettingsManager.shared
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView(...)
                        .preferredColorScheme(settings.theme.colorScheme)  // ← 在这里
                } else { ... }
            }
        }
    }
}
```

也就是说，**整窗的亮/暗**是由「App 根」上的 `.preferredColorScheme(settings.theme.colorScheme)` 决定的。

### 2. 为什么改了设置也不变

- 在设置里选主题时，代码是 `settings.theme = theme`（即改的是 `AppSettingsManager.shared.theme`），并会写入 UserDefaults，**数据已经更新**。
- 但 **SwiftUI 的 `App` / `Scene` 的 body 在运行期可能不会因为 @Observable 变化而重新执行**。  
  也就是说，`CountCalsApp` 的 body 只在 App 启动、或极少数系统触发的更新时跑过，之后你在设置里改 `settings.theme`，**根上的 `.preferredColorScheme(...)` 并没有被重新计算、也没有再次应用到窗口**。
- 所以**整窗**的 preferred color scheme 一直停留在**启动时**的值，所有页面（包括 Food Info）都跟着这个「旧」主题走，直到进程被杀死。

### 3. 为什么杀死 App 再进就对了

- 进程重启后，`CountCalsApp` 的 body 会重新执行。
- 此时从 UserDefaults 读出来的已经是新主题，`settings.theme.colorScheme` 是对的，所以 `.preferredColorScheme(settings.theme.colorScheme)` 从**一启动**就用了新值，整窗（包括 Food Info）自然就是新主题。

## 总结

| 现象 | 原因 |
|------|------|
| 切主题后当前页、返回再进都不变 | 主题是在 **App 根** 用 `.preferredColorScheme` 设的，运行中根 body 没有重新跑，窗口的 preferred 没更新 |
| 只有杀死 App 再进才对 | 重启后根 body 重新执行，用到了已保存的新主题 |

本质是：**不是 Food Info 或导航栈的问题，而是「根上的 preferredColorScheme 在运行期没有随设置更新」**。

## 修复方案（已实现：SwiftUI 原生方式）

1. **根视图可观测、且应用 preferredColorScheme**  
   - 在 `ContentView` 使用 `@Bindable private var settings = AppSettingsManager.shared`，让主题变化时根视图必然重绘，并继续使用 `.preferredColorScheme(settings.theme.colorScheme)`。这样整窗主题会随设置立即更新。

2. **Food Info 自身也应用 preferredColorScheme**  
   - 在 `FoodDetailSheet`、`FoodDetailPage` 根视图上增加 `.preferredColorScheme(settings.theme.colorScheme)`。当用户停留在食物详情/编辑时切换主题，这两个视图会因读取 `settings.theme` 而重绘，本屏立即切到新主题，不依赖窗口 trait 下发。

3. **编辑区用原生 Form**  
   - 食物信息的编辑区改为 SwiftUI 原生 `Form` + `Section`，语义色和键盘收起由系统处理，随 `@Environment(\.colorScheme)` 和当前 preferredColorScheme 自动适配，无需额外逻辑。
