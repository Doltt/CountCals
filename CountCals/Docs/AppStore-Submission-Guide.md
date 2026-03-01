# CountCals App Store 上架指引

> 面向 SEO 与转化优化的上架清单与填写指南。适用于 iOS 应用（countCals）首次上架与后续版本更新。

---

## 信息状态说明

| 类型 | 说明 |
|------|------|
| **已从项目填入** | 已根据当前代码/配置填写，可直接对照使用；若你改过 Xcode 配置请以 Xcode 为准。 |
| **需你执行** | 必须由你在 App Store Connect 或本地完成的步骤，文档中已用 **【需你执行】** 标出。 |

---

## 一、上架前准备清单

### 1. 开发者账号与证书

| 项目 | 说明 |
|------|------|
| **Apple Developer Program** | 年费 $99，[developer.apple.com](https://developer.apple.com) 注册。**【需你执行】** 若未加入需先注册。 |
| **Bundle ID** | **已从项目填入：** 主应用 `com.tree.countCals`，小组件 `com.tree.countCals.Widgets`。在 [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) 中确认已创建且与 Xcode 一致。 |
| **签名与描述文件** | App Store Distribution 证书 + App Store 类型 Provisioning Profile。**【需你执行】** 在 Xcode 或开发者后台创建并绑定到上述 Bundle ID。 |
| **Xcode 版本** | 使用与当前 iOS 版本匹配的 Xcode，确保能 Archive 并上传。本项目 **最低部署目标 iOS 26.2**（见 `project.pbxproj`）。 |

### 2. 应用内必须就绪的内容

| 项目 | 本应用对应 |
|------|------------|
| **隐私政策 URL** | 必须可公网访问。内容见 `Docs/Privacy-Policy.md`；可发布到 Notion 后取公开链接。**【需你执行】** 填写 URL 到 App Store Connect 及应用内（若有入口）。 |
| **支持 URL** | 用户反馈/帮助页面或邮箱。**【需你执行】** 在 App Store Connect「App 信息」中填写支持 URL（或 mailto 链接）。 |
| **账号删除/数据管理** | 本应用无账号：可注明「仅本地数据、卸载即清除」。无需提供账号删除流程。 |
| **相机/相册权限说明** | **已从项目填入：** Info.plist 中已配置。`NSCameraUsageDescription`：`需要相机权限来拍摄食物照片`；`NSPhotoLibraryAddUsageDescription`：`保存食物贴纸到相册`。与 App 隐私问卷描述保持一致即可。 |

### 3. 素材与元数据（SEO 与展示用）

| 类型 | 规格与数量 | 用途 |
|------|------------|------|
| **App 图标** | 1024×1024 px，无透明、无圆角 | 商店展示。**【需你执行】** 准备 1024×1024 图标并上传至 App Store Connect。 |
| **截图** | 6.7"、6.5"、5.5" 至少各一组；最多 10 张/尺寸 | 主展示。**【需你执行】** 在真机或模拟器截取并上传。 |
| **预览视频（可选）** | 15–30 秒，同截图尺寸 | 提高转化。 |
| **副标题 (Subtitle)** | 最多 30 字符 | **ASO/SEO 核心**（下文有可直接使用的建议）。 |
| **推广文本 (Promotional Text)** | 最多 170 字符，可随时改 | 活动/卖点；可选填。 |
| **描述 (Description)** | 最多 4000 字符 | 搜索与说服（下文有中英示例）。 |
| **关键词 (Keywords)** | 最多 100 字符，逗号分隔无空格 | **ASO 核心**（下文有建议）。 |

---

## 二、App Store Connect 填写指南

### 1. 应用信息（App Information）

- **名称 (Name)**  
  - **已从项目填入：** 当前 Info.plist 显示名为 `countCals`。在 Connect 中可填 **countCals** 或 **Count Cals**（按你最终品牌名）。
- **副标题 (Subtitle)** — **SEO/ASO 重点**  
  - 限制：30 字符（英文）/ 约 15 个汉字。  
  - 可直接使用（按语言选其一）：  
    - 英文：`AI Calorie Counter & Food Tracker`（30 字符）  
    - 中文：`AI 卡路里计算与饮食记录`  
  - 避免堆砌关键词，保持可读性。

- **类别 (Primary / Secondary)**  
  - 主类别：**健康健美 (Health & Fitness)**。  
  - 次类别：**生活 (Lifestyle)** 或 **美食佳饮 (Food & Drink)**（选更贴近你目标用户的）。**【需你执行】** 在 Connect 中勾选。

### 2. 定价与销售范围

- 选 **免费** 或 **付费**；若含内购需在 App 内购买一栏配置。**【需你执行】** 在 Connect 中设置价格与销售国家/地区。
- 销售范围：勾选要上架的国家/地区。

### 3. 隐私 (Privacy)

- **隐私政策 URL**：必填，且需与 App 内、审核备注一致。**【需你执行】** 将 `Docs/Privacy-Policy.md` 发布到 Notion 或其它可公网访问的 URL 后填入。
- **App 隐私 (App Privacy)**：  
  - 数据收集：若仅本地存储、不上传，在问卷里选「不收集数据」或按实际勾选（如「不与身份关联的使用数据」等）。  
  - 若使用相机/相册仅做本地识别，在描述中写清「照片仅用于本地 AI 识别，不上传」。

### 4. 版本信息（每个版本必填）

- **版本号**：**已从项目填入：** 与 Xcode `MARKETING_VERSION` 一致，当前为 **1.0**。  
- **Build 号**：与 `CURRENT_PROJECT_VERSION` 一致，当前为 **1**（每次上传新包需递增）。  
- **版权**：如 `2025 Your Name` 或 `2025 Your Company`。**【需你执行】** 填写你的名字或公司名。
- **推广文本 (Promotional Text)**  
  - 170 字符内，可随时更新，不随版本锁死。可直接使用：  
  - 「拍照记卡路里，三环进度一目了然。支持 Live Activity 与灵动岛。」

#### 描述 (Description) — **SEO 与转化重点**

- 前 2–3 行最重要（部分场景下会被折叠）。  
- 建议结构：  
  1. 一句话价值主张（含核心关键词）。  
  2. 3–5 个核心功能要点（可带 emoji）。  
  3. 技术/体验亮点（AI、Live Activity、隐私等）。  
  4. 适用人群与使用场景。

**示例（英文，便于 ASO）：**

```text
CountCals helps you hit your daily calorie and nutrition goals with AI. Snap your food—get instant calorie, protein, and fat estimates. No manual logging.

• AI food recognition — take a photo, get nutrition info
• Three-ring dashboard — calories, protein, fat at a glance
• Live Activity & Dynamic Island — see daily progress from lock screen
• Smart TDEE — goals adapt to your activity level
• Works offline — data stays on your device

Designed for anyone tracking calories or macros. Light/dark theme, Chinese & English. Your photos are used only for on-device recognition and are not stored or uploaded.
```

**示例（中文）：**

```text
countCals 用 AI 帮你轻松达成每日卡路里与营养目标。拍食物即可获得卡路里、蛋白质与脂肪估算，无需手动输入。

• AI 食物识别 — 拍照即得营养信息
• 三环仪表盘 — 卡路里、蛋白质、脂肪一目了然
• 实时活动与灵动岛 — 锁屏也能看每日进度
• 智能 TDEE — 根据活动量自动调整目标
• 数据本地存储 — 照片仅用于识别，不上传

支持浅色/深色主题与中英文，适合需要控制饮食、减脂或增肌的用户。
```

可按需替换为你的实际功能表述，保持前几句强相关、可搜索。

#### 关键词 (Keywords)

- 最多 **100 字符**，逗号分隔，**不要加空格**。  
- 不要重复副标题和名称里已有的词（如 countCals、AI、calorie、tracker 已在名称/副标题中出现，关键词中可少用或不用）。  
- **可直接使用（英文，100 字符内）：**  
  `diet,macros,weight,TDEE,food log,nutrition,weight loss,meal,carb,fat,protein,offline`  
- **中文本地化关键词建议：**  
  `饮食记录,减肥,营养,增肌,控制饮食,热量,蛋白质,脂肪`

### 5. 截图与预览视频

- **顺序**：第一张最重要，建议放「拍照→出结果」或「三环仪表盘」等高转化画面。  
- **文案**：图上可加简短文案（如「拍食物，算卡路里」「三环进度」），与副标题/描述关键词呼应。  
- **尺寸**：至少提供 6.7"（如 iPhone 15 Pro Max）和 6.5"（如 iPhone 11 Pro Max），以覆盖主流展示位。

### 6. 审核备注 (Notes for Review)

- 本应用无登录，无需提供测试账号。  
- **可直接粘贴使用：**  
  `无需登录。相机仅用于本地 AI 食物识别，照片不保存、不上传。数据全部存储在设备本地。支持 URL Scheme：countcals://add-food（从 Live Activity 跳转添加食物）。`  
- 若使用 TestFlight 已测过的 build，可追加一句：「已在 TestFlight 验证。」

---

## 三、提交流程（简要）

1. **Xcode**  
   - 打开项目：`Pace-main/countCals.xcodeproj`，Scheme 选 **countCals**。  
   - 目标设备选 **Any iOS Device**（勿选模拟器），菜单 **Product → Archive**。  
   - 在 Organizer 中 **Distribute App** → **App Store Connect** → **Upload**，按提示选择签名与选项。  
   - 若 Archive 灰显：先在 Signing & Capabilities 中选好 Team 与 Distribution 描述文件。

2. **App Store Connect**  
   - 进入对应 App（Bundle ID：`com.tree.countCals`）→ **TestFlight** 确认 build 已出现（处理需几分钟到几十分钟）。  
   - 在 **App Store** 页签下，选对应版本（如 1.0），勾选刚上传的 build，填写上述所有必填项。  
   - 提交审核（**Submit for Review**）。

3. **审核**  
   - 通常 24–48 小时内会有结果；若被拒，根据 Resolution Center 反馈修改后重新提交。

---

## 四、SEO/ASO 速查

| 位置 | 建议 |
|------|------|
| **副标题** | 30 字符内，含「AI / 卡路里 / 饮食 / 记录」等核心词，且成句可读。 |
| **描述前 2 行** | 包含主关键词 + 价值主张，避免空洞形容词堆砌。 |
| **关键词** | 100 字符，逗号无空格，不重复名称/副标题，覆盖同义与长尾词。 |
| **截图标题/文案** | 与关键词一致，突出「拍照记卡路里」「三环」「Live Activity」等。 |
| **本地化** | 至少做英文 + 中文，副标题/描述/关键词分别优化。 |

---

## 五、本应用（CountCals）检查清单

- [ ] Apple Developer 账号；在开发者后台确认 Bundle ID `com.tree.countCals` 与 Distribution 描述文件 **【需你执行】**
- [ ] 隐私政策 URL：将 `Docs/Privacy-Policy.md` 发布后填入 Connect **【需你执行】**
- [ ] 支持 URL（或 mailto）在 App Store Connect 中填写 **【需你执行】**
- [ ] 1024×1024 图标；至少 2 组尺寸的截图（6.7" + 6.5"）**【需你执行】**
- [ ] 副标题、描述、关键词（上文已提供可直接使用的中英示例）
- [ ] Info.plist 权限文案已就绪（见第二节表格）；与 App 隐私问卷描述一致即可
- [ ] Xcode 选 scheme **countCals**、Any iOS Device → Archive → Upload
- [ ] 审核备注粘贴「无需登录。相机仅用于本地…」（见 二.6）
- [ ] 版本/版权：版本 1.0、Build 1；版权 **【需你执行】** 填你的名字或公司

---

## 六、需你执行汇总（必做项）

以下必须由你在本地或 App Store Connect 中完成，文档无法代填：

| 序号 | 项 | 说明 |
|------|----|------|
| 1 | Apple Developer 账号 | 若未加入，需注册并缴费。 |
| 2 | 隐私政策 URL | 将 `Docs/Privacy-Policy.md` 发到 Notion（或其它）并取得公网链接，填入 Connect「隐私政策 URL」；隐私政策内的「最后更新」日期、联系邮箱与支持 URL 也需你在 `Privacy-Policy.md` 中填写。 |
| 3 | 支持 URL | 在 App Store Connect「App 信息」中填写（或 mailto）。 |
| 4 | 版权 (Copyright) | 在版本信息中填写，如 `2025 你的名字` 或 `2025 公司名`。 |
| 5 | 1024×1024 App 图标 | 制作并上传至 Connect。 |
| 6 | 截图 | 至少 6.7"、6.5" 各一组，上传至对应版本。 |
| 7 | 定价与销售范围 | 在 Connect 中设置免费/付费及上架国家/地区。 |
| 8 | 类别 | 主类别选 Health & Fitness，次类别选 Lifestyle 或 Food & Drink。 |

其余（副标题、描述、关键词、推广文本、审核备注）文档中已给出可直接使用或微调的内容。

---

## 七、参考链接

- [App Store Connect 帮助](https://help.apple.com/app-store-connect/)
- [App 审核指南](https://developer.apple.com/app-store/review/guidelines/)
- [App 隐私详情](https://developer.apple.com/app-store/app-privacy-details/)

---

**文档版本：** 1.1  
**已从项目填入的取值：** Bundle ID `com.tree.countCals`、版本 1.0、Build 1、显示名 countCals、URL Scheme countcals、最低 iOS 26.2、Scheme countCals、Info.plist 权限文案、项目路径 `Pace-main/countCals.xcodeproj`。  
**适用于：** CountCals 首次上架与后续版本更新。
