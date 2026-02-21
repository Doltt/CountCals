# App Module

## 职责
应用入口和根级导航容器。

## 文件
- `PaceApp.swift` - App 入口，配置 ModelContainer 和主题
- `ContentView.swift` - 主容器：TabView + 悬浮 Add Food 按钮

## 依赖
- `Features.Home` - 首页 Tab
- `Features.Settings` - 设置 Tab
- `Features.FoodCamera` - 添加食物功能

## 导航结构
```
ContentView (ZStack)
├── TabView
│   ├── HomeView (tag: 0)
│   └── SettingsView (tag: 1)
└── Floating "Add Food" Button
    └── AddFoodView (fullScreenCover)
```

## 注意事项
- 悬浮按钮固定在右下角，橙色胶囊样式
- 添加食物后自动切换回 Home Tab
- 支持 URL Scheme (pace://add-food) 从 Live Activity 跳转
