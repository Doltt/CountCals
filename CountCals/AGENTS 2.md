# countCals iOS App

> **Agent Guide**: 这是模块化架构的 Pace 项目。每个模块有独立的 `AGENTS.md`，修改前请先阅读对应模块的文档。

> ⚠️ **重要提醒（所有对话必须遵守）**
> 
> 处理本项目的**任何代码修改、文件编辑、配置更改**前，**必须先读取 `plan-first-mode` skill** 并严格执行：
> 1. 说明对需求的理解
> 2. 说明实现方案
> 3. **等待用户明确确认**
> 4. 执行修改
> 
> **禁止未经确认直接修改代码。**

## 项目概述
countCals 是一款 iOS 卡路里追踪应用，使用 SwiftUI + SwiftData 构建。

## 技术栈
- **UI Framework**: SwiftUI (iOS 26.2+)
- **数据持久化**: SwiftData + UserDefaults
- **架构**: 模块化 MVVM (Feature-based)
- **设计**: SF Pro Rounded, 自适应浅色/深色模式

## 模块结构

```
countCals/
├── App/                    # 应用入口和根导航
│   ├── CountCalsApp.swift
│   ├── ContentView.swift
│   └── AGENTS.md
├── Features/               # 功能模块（按功能分组）
│   ├── Home/               # 首页/仪表盘
│   ├── Settings/           # 设置和个人资料
│   └── FoodCamera/         # AI 相机识别
├── Core/                   # 核心层（共享依赖）
│   ├── Models/             # 数据模型
│   ├── Services/           # 业务服务
│   └── DesignSystem/       # 设计系统
└── Resources/              # 资源文件
```

## 快速导航

| 如果要修改... | 查看模块 | 关键文件 |
|--------------|---------|---------|
| Tab 导航/悬浮按钮 | `App/` | `ContentView.swift` |
| 首页三环/活动等级 | `Features/Home/` | `HomeView.swift` |
| 设置/语言/主题 | `Features/Settings/` | `SettingsView.swift` |
| 相机/AI 识别 | `Features/FoodCamera/` | `FoodCameraView.swift` |
| TDEE 计算逻辑 | `Core/Services/` | `CalorieService.swift` |
| 数据模型 | `Core/Models/` | `FoodEntry.swift` |
| 字体/颜色规范 | `Core/DesignSystem/` | `Font+PaceRounded.swift` |

## 依赖关系图

```
App (ContentView)
    ├── Features.Home ───────┐
    ├── Features.Settings ───┤→ Core (Models, Services, DesignSystem)
    └── Features.FoodCamera ─┘
```

**原则**: 
- Feature 模块可以依赖 Core
- Feature 模块之间避免循环依赖
- App 模块作为唯一聚合点

## 开发规范

### 1. 添加新功能
1. 确定功能属于哪个 Feature 模块
2. 阅读该模块的文档 (Docs/*.md)
3. 如需新模型，添加到 `Core/Models/`
4. 如需新服务，添加到 `Core/Services/`

### 2. 修改现有功能
1. 定位文件所在模块
2. 检查模块的文档 (Docs/*.md) 了解数据流
3. 修改后必须构建验证

### 3. 构建与部署（强制）

**任何代码修改后，必须执行完整的「构建+部署」流程，而不仅仅是构建验证。**

#### 完整流程
```
修改代码 → 构建 → 部署到设备 → 启动应用
```

#### 步骤
```bash
# 1. 获取设备 ID
xcrun devicectl list devices

# 2. 编译（真机）
xcodebuild -project countCals.xcodeproj -scheme countCals -destination "platform=iOS,id=DEVICE_ID" build

# 3. 安装
xcrun devicectl device install app --device "DEVICE_UUID" \
  ~/Library/Developer/Xcode/DerivedData/Pace-*/Build/Products/Debug-iphoneos/Pace.app

# 4. 启动
xcrun devicectl device process launch --device "DEVICE_UUID" com.tree.countCals
```

#### 检查清单（必须完成）
- [ ] 代码修改完成
- [ ] 编译成功 (BUILD SUCCEEDED)
- [ ] 安装成功 (App installed)
- [ ] 应用启动 (Launched application)

**⚠️ 禁止只构建不部署。构建成功但未到设备上验证，任务不算完成。**

## 颜色规范
```swift
// 主色调
Color(red: 1, green: 0.267, blue: 0)       // 橙色 #FF4400
Color(red: 0.2, green: 0.68, blue: 0.38)   // 绿色 #33AD60
Color(red: 0.996, green: 0.56, blue: 0.66) // 粉色 #FE8FA9

// 背景
Color(red: 0.02, green: 0.02, blue: 0.02)  // 深色模式背景
Color(red: 0.98, green: 0.98, blue: 0.98)  // 浅色模式背景
```

## 字体规范
```swift
.font(.paceRounded(.body))                    // 正文
.font(.paceRounded(size: 40))                 // 大标题（活动等级）
.font(.paceRounded(.subheadline, weight: .semibold)) // 按钮文字
```

## 注意事项
- **不要**在 Feature 模块间直接导入（通过 App 模块协调）
- **不要**修改 `Core/Models` 而不检查影响范围
- **必须**在修改后执行构建验证
- **优先**使用 `AppSettingsManager.shared` 获取当前语言/主题
