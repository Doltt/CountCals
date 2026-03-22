# App Store 上架字段与 SEO 填写指南

> **用途**：从 SEO/ASO 角度，列出 App Store Connect 各字段的推荐填写内容及对应位置，便于复制粘贴与搜索优化。  
> **配合**：流程与检查清单见 [AppStore-Submission-Guide.md](AppStore-Submission-Guide.md)。

---

## 一、字段与位置对照总表

| App Store Connect 位置 | 字段英文名 | 字符限制 | 是否必填 | SEO 权重 |
|------------------------|------------|----------|----------|----------|
| 创建 App 时（应用信息） | SKU | 无硬性限制 | 否 | 无 |
| App 信息 | Name | 30 | 是 | 高 |
| App 信息 | Subtitle | 30 | 是 | **极高** |
| App 信息 | Primary Category | - | 是 | 高 |
| App 信息 | Secondary Category | - | 否 | 中 |
| 版本信息 | Promotional Text | 170 | 否 | 中 |
| 版本信息 | Description | 4000 | 是 | **极高** |
| 版本信息 | Keywords | 100 | 是 | **极高** |
| 版本信息 | What's New | 4000 | 否 | 低 |
| 截图/预览 | 截图标题 + 图上文案 | 视尺寸 | 是 | 高 |
| 审核 | Notes for Review | - | 建议 | 无 |

---

## 二、按字段的推荐填写与 SEO 说明

### 0. SKU（库存单位）

| 项目 | 说明 |
|------|------|
| **填写时机** | 在 App Store Connect 中**创建新 App** 时填写，创建后**不可修改**。 |
| **是否必填** | 否（可选）。 |
| **可见性** | 仅你方可见，**不展示给用户**，**不参与搜索/SEO**。 |
| **推荐填写** | 用于内部标识（如财务、多端区分）。可直接用：`baguettekcal-ios-1`，或与 Bundle ID 一致：`com.tree.countCals`。 |
| **注意** | 一旦保存无法更改，建议用简短、唯一的英文/数字组合。 |

---

### 1. Name（应用名称）

App 名称在 App Store 内**不可与已有应用重复**。以下为推荐及备选，**须在 Connect 创建时逐一验证可用再填**。

| 语言 | 推荐填写 | 字符数 | 说明 |
|------|----------|--------|------|
| 英文 | `BaguetteKcal` | ≤30 | 品牌词 + kcal 词根，降低重名概率，且可与副标题/关键词协同做搜索覆盖。 |
| 中文 | `BaguetteKcal`（推荐）或「法棍热量」 | ≤30 | 中文可直接沿用英文品牌名；如需本地化可用「法棍热量」。 |

**备选名称（若前一个已被占用，可依次尝试）**：

| 序号 | 名称 | 说明 / SEO 联想 |
|------|------|------------------|
| 1 | **BaguetteKcal** | 品牌主名：Baguette（法棍）+ Kcal，识别度高、重名概率更低。 |
| 2 | **BaguetteKcal AI** | 保留品牌 + 加 “AI” 提示（如主名被占用可尝试）。 |
| 3 | **LeBaguetteKcal** | 加法语冠词增强独特性（仍保留 kcal 词根）。 |
| 4 | **BaguetteMacros** | 更偏健身/宏量营养定位（macros 可搜）。 |
| 5 | **BaguetteFoodLog** | 强调记录（log）心智，更偏长期追踪。 |
| 6 | **BaguetteRings** | 呼应三环仪表盘特色，差异化强。 |
| 7 | **BaguetteTracker** | 直白表意（tracker），但仍有品牌词降低撞名。 |
| 8 | **BaguetteTDEE** | 强调 TDEE 计算卖点，偏进阶用户。 |
| 9 | **BaguetteFuel** | “Fuel” 强调饮食/能量管理，品牌感更强。 |
| 10 | **BaguetKcal** | 缩写拼写，进一步降低重名概率（读音保持接近）。 |

**SEO 注意**：名称参与搜索，但不宜堆砌关键词；副标题和关键词补足搜索量。选定名称后，描述/推广文案中的产品名需统一（如全文用 BaguetteKcal）。

---

### 2. Subtitle（副标题）— **ASO 核心**

| 语言 | 推荐填写 | 字符数 | 说明 |
|------|----------|--------|------|
| 英文 | `AI Calorie Counter & Food Tracker` | 30 | 含核心词：AI、Calorie、Food、Tracker；成句可读。 |
| 中文 | `AI 卡路里计算与饮食记录` | 约 12 字 | 核心词：AI、卡路里、饮食、记录。 |

**SEO 注意**：
- 副标题在搜索结果中展示，**权重高**，且字数少，每个词都要有用。
- 避免与 Name 完全重复；可与 Keywords 错开，避免同一词在副标题与关键词中重复占用。

**备选（英文，30 字符内）**：
- `Snap Food, Get Calories — AI Tracker`
- `AI Diet & Calorie Tracker`

---

### 3. Primary / Secondary Category（主/次类别）

| 字段 | 推荐选择 | SEO/展示说明 |
|------|----------|----------------|
| Primary | **Health & Fitness（健康健美）** | 与卡路里/营养追踪最相关，搜索流量大。 |
| Secondary | **Lifestyle（生活）** 或 **Food & Drink（美食佳饮）** | 生活类覆盖更广；美食类更垂直，按目标用户选择。 |

---

### 4. Promotional Text（推广文本）

| 语言 | 推荐填写 | 说明 |
|------|----------|------|
| 中文 | `拍照记卡路里，三环进度一目了然。支持 Live Activity 与灵动岛。` | 可随时在 Connect 中修改，不随版本锁死。 |
| 英文 | `Snap food, track calories. Three-ring dashboard, Live Activity & Dynamic Island.` | 与副标题/描述关键词呼应。 |

**SEO 注意**：展示在描述上方，可带活动/卖点，建议含 1～2 个核心关键词。

---

### 5. Description（描述）— **SEO 与转化核心**

**原则**：前 2～3 行（约 170 字符内）在部分场景会被折叠，必须包含**主关键词 + 清晰价值主张**。

#### 英文（可直接粘贴）

```text
BaguetteKcal helps you hit your daily calorie and nutrition goals with AI. Snap your food—get instant calorie, protein, and fat estimates. No manual logging.

• AI food recognition — take a photo, get nutrition info
• Three-ring dashboard — calories, protein, fat at a glance
• Live Activity & Dynamic Island — see daily progress from lock screen
• Smart TDEE — goals adapt to your activity level
• Works offline — data stays on your device

Designed for anyone tracking calories or macros. Light/dark theme, Chinese & English. Your photos are used only for on-device recognition and are not stored or uploaded.
```

#### 中文（可直接粘贴）

```text
BaguetteKcal 用 AI 帮你轻松达成每日卡路里与营养目标。拍食物即可获得卡路里、蛋白质与脂肪估算，无需手动输入。

• AI 食物识别 — 拍照即得营养信息
• 三环仪表盘 — 卡路里、蛋白质、脂肪一目了然
• 实时活动与灵动岛 — 锁屏也能看每日进度
• 智能 TDEE — 根据活动量自动调整目标
• 数据本地存储 — 照片仅用于识别，不上传

支持浅色/深色主题与中英文，适合需要控制饮食、减脂或增肌的用户。
```

**SEO 注意**：
- 首句包含「calorie / 卡路里」「AI」「nutrition / 营养」等主关键词。
- 要点列表可带 emoji，但前两句保持简洁、可被搜索索引。
- 末尾补充隐私/数据说明，有利于信任与审核。

---

### 6. Keywords（关键词）— **ASO 核心**

- **规则**：最多 100 字符，**逗号分隔、无空格**；与 Name/Subtitle 中已出现的词尽量不重复，以扩展同义与长尾词为主。

| 语言 | 推荐填写（100 字符内） |
|------|------------------------|
| 英文 | `diet,macros,weight,TDEE,food log,nutrition,weight loss,meal,carb,fat,protein,offline` |
| 中文 | `饮食记录,减肥,营养,增肌,控制饮食,热量,蛋白质,脂肪` |

**SEO 注意**：
- 英文中已避免重复 Subtitle 里的 calorie、AI、tracker、food。
- 可随运营阶段 A/B 测试替换 2～3 个词（如加入 keto、BMR、macro counter 等）。

---

### 7. 截图与预览视频（文案与顺序）

| 顺序 | 建议画面 | 图上/标题文案建议（与 SEO 一致） |
|------|----------|----------------------------------|
| 1 | 拍照→识别结果 或 三环仪表盘 | 「BaguetteKcal｜拍食物，算卡路里」/ “BaguetteKcal — Snap food, get calories” |
| 2 | 三环进度 | 「卡路里·蛋白质·脂肪 一目了然」/ “Three-ring dashboard” |
| 3 | 每日饮食列表/记录 | 「饮食记录」/ “Food log” |
| 4 | Live Activity / 锁屏 | 「锁屏看进度」/ “Live Activity” |
| 5+ | 设置/个人资料/主题 | 按需，可强调 TDEE、目标、隐私等 |

**SEO 注意**：截图标题与图上文字会参与展示与用户心智，与副标题、描述中的核心词保持一致可强化品牌与搜索联想。

---

### 8. Notes for Review（审核备注）

以下可直接粘贴，保证审核通过且与隐私描述一致：

```text
无需登录。相机仅用于本地 AI 食物识别，照片不保存、不上传。数据全部存储在设备本地。支持 URL Scheme：countcals://add-food（从 Live Activity 跳转添加食物）。
```

---

## 三、项目内已确认的取值（供对照）

| 项目 | 取值 | 来源 |
|------|------|------|
| SKU（可选，创建后不可改） | 推荐 `baguettekcal-ios-1` 或 `com.tree.countCals` | 自定 |
| Bundle ID（主应用） | `com.tree.countCals` | project.pbxproj |
| Bundle ID（小组件） | `com.tree.countCals.Widgets` | project.pbxproj |
| 版本号 (MARKETING_VERSION) | `1.0` | project.pbxproj |
| Build (CURRENT_PROJECT_VERSION) | `1` | project.pbxproj |
| 最低 iOS | 26.2 | project.pbxproj |
| Scheme | countCals | Xcode |
| URL Scheme | countcals | 用于 add-food 等 |

---

## 四、SEO 优先级速查

| 优先级 | 字段 | 建议动作 |
|--------|------|----------|
| P0 | Subtitle, Description 前 2 行, Keywords | 必须含核心关键词，不堆砌、可读；关键词与副标题错开。 |
| P1 | Name, 截图顺序与首图文案 | 名称一致、首图高转化+关键词呼应。 |
| P2 | Promotional Text, 描述其余段落 | 卖点清晰、与 P0 关键词一致。 |
| P3 | 本地化（至少英文+中文） | 副标题/描述/关键词均做对应语言版本。 |

---

## 五、参考

- 流程与完整检查清单：[AppStore-Submission-Guide.md](AppStore-Submission-Guide.md)
- 隐私政策内容：[Privacy-Policy.md](Privacy-Policy.md)
- [App Store Connect 帮助](https://help.apple.com/app-store-connect/)
- [App 审核指南](https://developer.apple.com/app-store/review/guidelines/)

---

**文档版本**：1.0  
**适用**：CountCals 首次上架与后续版本 ASO 优化。
