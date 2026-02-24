# DailyFoodLog 模块

## 模块职责

负责显示每日食物日志，包括：
- 周历日期选择器
- 当日营养摄入统计（卡路里、蛋白质、脂肪、碳水化合物）
- 食物记录列表
- 添加/删除食物记录

## 技术栈

- **UI**: SwiftUI
- **数据**: SwiftData (FoodEntry)
- **架构**: MVVM

## 文件结构

```
DailyFoodLog/
├── Views/
│   └── DailyFoodLogView.swift          # 主视图
├── ViewModels/
│   └── DailyFoodLogViewModel.swift     # 业务逻辑
└── AGENTS.md                           # 本文档
```

## 依赖关系

```
DailyFoodLogView
    ├── DailyFoodLogViewModel
    ├── Core/Models/FoodEntry
    ├── Core/Services/AppSettingsManager
    └── Core/Services/LiveActivityService
```

## 关键功能

### 周历选择器
- 支持左右滑动切换周
- 点击日期查看该日记录
- 选中日期高亮显示

### 营养统计
- 实时计算已摄入/剩余营养
- 进度条可视化
- 基于用户资料的每日目标

### 食物记录
- 列表展示当日记录
- 点击进入详情
- 左滑删除

## 注意事项

- 该模块独立管理自己的 ViewModel，不再依赖 Home 模块
- 使用 AppSettingsManager 处理多语言和主题
- Live Activity 更新通过 ViewModel 触发
