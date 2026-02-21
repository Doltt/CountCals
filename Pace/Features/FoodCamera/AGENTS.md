# FoodCamera Feature Module

## 职责
AI 食物识别相机功能：拍照 → 识别 → 保存。

## 文件
```
Views/
├── AddFoodView.swift           # 入口：直接跳转 FoodCameraView
├── FoodCameraView.swift        # 相机界面 + 扫描动画
├── CustomCameraPreview.swift   # 相机预览层
├── ScanningOverlayView.swift   # 扫描框动画
└── FoodStickerResultView.swift # 识别结果展示

ViewModels/
└── FoodCameraViewModel.swift   # 相机控制 + 识别流程管理
```

## 核心功能
1. **实时相机预览** - 使用 AVFoundation
2. **AI 食物识别** - 调用阿里云 qwen-vl API
3. **图像裁切** - VisionKit 提取食物主体
4. **结果确认** - 展示识别的营养信息，可编辑后保存

## 依赖
- `Core.Models` - FoodEntry
- `Core.Services` - FoodRecognitionService, ImageCutoutService
- `Core.DesignSystem` - Font+PaceRounded

## 数据流
```
FoodCameraView
    ↓ 拍照
capturePhoto()
    ↓
ImageCutoutService.cutout() → 提取食物主体
    ↓
FoodRecognitionService.recognizeFood() → AI 识别
    ↓
FoodStickerResultView 展示结果
    ↓
保存到 SwiftData (FoodEntry)
```

## 注意事项
- API Key 硬编码在 FoodRecognitionService（仅开发，需替换为代理服务器）
- 图像处理全程内存中，不保存到相册
- 识别失败时允许手动输入
