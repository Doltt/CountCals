# Home Feature Module

## 职责
应用首页/仪表盘，展示用户每日卡路里进度和 TDEE 概览。

## 文件
```
Views/
├── HomeView.swift          # 主视图：活动等级 + 三环 + 统计
└── Components/             # (可选) 可复用组件

ViewModels/
└── DashboardViewModel.swift # TDEE 计算、营养统计、Live Activity 控制
```

## 核心功能
1. **活动等级显示** - 可点击切换（低/中/高）
2. **三环进度可视化** - 卡路里(橙)、蛋白质(绿)、脂肪(粉)
3. **剩余营养统计** - 今日剩余可摄入量
4. **个人资料入口** - 点击三环打开 Profile

## 依赖
- `Core.Models` - FoodEntry, UserProfile
- `Core.Services` - CalorieService, LiveActivityService
- `Core.DesignSystem` - Font+PaceRounded
- `Features.Settings` - ProfileView

## 数据流
```
FoodEntry (SwiftData) 
    ↓
DashboardViewModel.todaysEntries() → 过滤今日记录
    ↓
consumedCalories/protein/fat → 计算剩余量
    ↓
DashboardRingsView + statsRow 展示
```

## 注意事项
- 使用 `@Query` 自动同步 SwiftData 变化
- 入场动画使用 `hasAppeared` 状态控制
- 三环颜色：#FF4400 (Cal), #33AD60 (Protein), #FE8FA9 (Fat)
