# Core Module

## 职责
提供全应用共享的基础能力：数据模型、业务服务、设计系统。

## 子模块

### Models/
数据模型和配置管理。

| 文件 | 职责 |
|------|------|
| `FoodEntry.swift` | 食物记录模型 (SwiftData) |
| `UserProfile.swift` | 用户身体数据 + TDEE 计算 |
| `AppSettings.swift` | 主题/语言设置 + 本地化 |
| `PaceActivityAttributes.swift` | Live Activity 数据定义 |

### Services/
业务逻辑服务。

| 文件 | 职责 |
|------|------|
| `CalorieService.swift` | BMR/TDEE 计算 (Mifflin-St Jeor 公式) |
| `FoodRecognitionService.swift` | AI 食物识别 API 调用 |
| `ImageCutoutService.swift` | VisionKit 图像分割 |
| `LiveActivityService.swift` | 实时活动管理 |

### DesignSystem/
UI 设计系统和通用组件。

| 文件 | 职责 |
|------|------|
| `Extensions/Font+PaceRounded.swift` | SF Pro Rounded 字体扩展 |
| `Components/UIComponents.swift` | 通用 UI 组件 |

## 设计规范

### 颜色
```swift
Color(red: 1, green: 0.267, blue: 0)      // 主橙色 #FF4400
Color(red: 0.2, green: 0.68, blue: 0.38)  // 蛋白质绿 #33AD60
Color(red: 0.996, green: 0.56, blue: 0.66) // 脂肪粉 #FE8FA9
```

### 字体
```swift
.font(.paceRounded(.body))           // 正文
.font(.paceRounded(size: 20))        // 自定义大小
.font(.paceRounded(.title, weight: .bold)) // 加粗标题
```

### 营养比例（地中海饮食）
- 碳水: 45% (4 kcal/g)
- 蛋白质: 25% (4 kcal/g) 
- 脂肪: 30% (9 kcal/g)
