# Pace

一款简洁的 iOS 卡路里追踪应用，使用 AI 识别食物并自动计算营养摄入。

## 功能特性

- 🤖 **AI 食物识别** - 拍照即可识别食物并估算卡路里
- 📊 **三环可视化** - 直观展示卡路里、蛋白质、脂肪摄入进度
- 📱 **实时活动** - 锁屏和灵动岛显示每日进度
- ⚙️ **智能 TDEE** - 根据活动等级自动调整目标
- 🎨 **自适应主题** - 支持浅色/深色模式
- 🌐 **多语言** - 中文/英文切换

## 技术栈

- SwiftUI + SwiftData
- iOS 26.2+
- VisionKit (图像分割)
- Live Activity (实时活动)

## 项目结构

项目采用模块化架构，按功能分组：

```
Pace/
├── App/              # 应用入口 (TabView 导航)
├── Features/         # 功能模块
│   ├── Home/         # 首页/仪表盘
│   ├── Settings/     # 设置
│   └── FoodCamera/   # AI 相机
├── Core/             # 核心层
│   ├── Models/       # 数据模型
│   ├── Services/     # 业务服务
│   └── DesignSystem/ # 设计系统
└── Resources/        # 资源文件
```

## 开发

### 构建
```bash
xcodebuild -project Pace.xcodeproj -scheme Pace -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### 架构说明

详细架构文档请查看各模块的文档：
- [App 模块](Docs/App.md)
- [Home 模块](Docs/Home.md)
- [Settings 模块](Docs/Settings.md)
- [FoodCamera 模块](Docs/FoodCamera.md)
- [Core 模块](Docs/Core.md)

## 隐私说明

- 食物图片仅用于 AI 识别，不保存到本地或云端
- 身体数据仅存储在设备本地 (UserDefaults)
- 食物记录使用 SwiftData 本地存储

## License

MIT
