# Settings Feature Module

## 职责
应用设置和个人资料管理。

## 文件
```
Views/
├── SettingsView.swift    # 设置主页：语言、主题、身体数据
└── ProfileView.swift     # 个人资料：年龄/性别/身高/体重/TDEE

ViewModels/
└── (使用 DashboardViewModel 共享数据)
```

## 核心功能
1. **语言设置** - 中文/英文切换
2. **主题设置** - 浅色/深色/跟随系统
3. **身体数据** - 管理身高体重，自动重新计算 TDEE
4. **反馈入口** - 跳转 App Store 评价

## 依赖
- `Core.Models` - AppSettingsManager, UserProfile
- `Core.Services` - CalorieService
- `Features.Home` - DashboardViewModel (共享)

## 数据流
```
ProfileView
    ↓
DashboardViewModel.updateProfile() → 更新 UserProfile + 重新计算 TDEE
    ↓
UserProfile.save() → UserDefaults
```

## 注意事项
- SettingsView 使用 `AppSettingsManager.shared` 单例
- ProfileView 接收外部 viewModel 保持数据同步
- 所有变更即时保存到 UserDefaults
