# Pikmin Mushroom Alarm 蘑菇鬧鐘

一個給 Pikmin Bloom 玩家的 iOS App。截圖 → OCR 自動辨識剩餘時間 → 排程通知 → 鎖屏 Live Activity / Dynamic Island / Home Screen Widget 一條龍。

```
Pikmin Bloom 截圖
   ↓ Share
蘑菇鬧鐘
   ↓ Vision OCR
自動建立倒數
   ↓
通知 + Live Activity + Widget
```

## 為什麼做這個

打 Pikmin Bloom 蘑菇場景時要記每朵蘑菇的刷新時間，手動很煩、容易忘記。這個 App 把 *截圖 → 倒數 → 提醒* 全自動化。

完整產品設計請看 [`proposal.md`](./proposal.md)。

## 功能

- **OCR 自動辨識** — Apple Vision Framework 離線辨識 Pikmin Bloom 截圖裡的「剩下 X 小時 Y 分 Z 秒」
- **多蘑菇管理** — 平行追蹤多個地點，首頁 Carousel 切換
- **遞增式通知** — T+0、T+3:00、T+4:00、T+4:30、T+4:50、T+5:00 越接近刷新提醒越密
- **Share Extension** — 從相簿 / Pikmin Bloom 直接分享截圖，自動建立鬧鐘
- **Live Activity + Dynamic Island** — 鎖屏即時倒數，iPhone 14 Pro 以上有靈動島
- **Home Screen Widget** — Small / Medium 兩種尺寸顯示下一朵刷新的蘑菇
- **Apple Watch 通知** — 配對 Watch 後自動接收，有「打開 Pikmin」「再延 1 分鐘」按鈕

## 技術棧

| 層 | 技術 |
|---|---|
| UI | SwiftUI |
| 持久化 | SwiftData（共享 App Group） |
| OCR | Apple Vision Framework |
| 通知 | UNUserNotificationCenter |
| 即時倒數 | ActivityKit + WidgetKit |
| 後端 | 無（全本機） |

最低 iOS 17。Dynamic Island 需 iPhone 14 Pro / 15 Pro / 16 Pro。

## 專案結構

```
PikminMushroomAlarm/        # 主 App target
├── Models/                 # SwiftData @Model、ActivityAttributes
├── Services/               # OCR、通知排程、SwiftData 容器、Live Activity manager
├── Views/                  # SwiftUI views (HomeView / HeroCard / Carousel / Sheets)
├── Resources/              # Info.plist、entitlements
└── PikminMushroomAlarmApp.swift

ShareExtension/             # Share Extension target — 接收分享進來的截圖
├── ShareViewController.swift
├── Info.plist
└── ShareExtension.entitlements

PikminWidgets/              # Widget Extension target
├── PikminWidgetsBundle.swift
├── MushroomLiveActivity.swift   # 鎖屏 + Dynamic Island
├── MushroomWidget.swift         # Home Screen widget
├── Info.plist
└── PikminWidgets.entitlements

proposal.md                 # 產品規劃
pikmin_alarm_mockup.jsx     # 原始 React UI mockup
SETUP_MAC.md                # Mac 端 Xcode 設定步驟
CLAUDE.md                   # Claude Code 工作指引
```

## 開發工作流

這個 repo 是 **Windows 寫 code，Mac 跑 build** 的工作流：

1. Windows 端編輯 `.swift` 純文字檔
2. Mac 端用 Xcode 開 project，把這些檔案掛上對應 target
3. Mac 端 Build & Run

repo 內 **沒有 `.xcodeproj`** — Xcode project 由你在 Mac 端建立。詳細步驟見 [`SETUP_MAC.md`](./SETUP_MAC.md)。

### Mac 端首次設定（簡版）

```bash
# 在 Mac
git clone https://github.com/DaYi-TW/Pikmin-Mushroom-Alarm.git
cd Pikmin-Mushroom-Alarm
```

1. Xcode → New Project → iOS App → `PikminMushroomAlarm`，最低 iOS 17，SwiftUI
2. 把 `PikminMushroomAlarm/` 底下所有 `.swift` 拖進 project
3. New Target → **Share Extension** → 掛 `ShareExtension/` 底下的檔案
4. New Target → **Widget Extension**（勾 Include Live Activity）→ 掛 `PikminWidgets/` 底下的檔案
5. 三個 target 都加同一個 **App Group**，把 `AppGroup.swift` 跟三個 `.entitlements` 裡的 identifier 改成你的
6. ⌘R

完整逐步指令見 [`SETUP_MAC.md`](./SETUP_MAC.md)。

## OCR 範例

輸入截圖：
```
功夫壁畫
一般 輝煌蘑菇
剩下 1 小時 0 分 13 秒
```

`OCRService.parseRemainingSeconds` 解析出：
```swift
OCRResult(
    location: "功夫壁畫",
    type: "一般 輝煌蘑菇",
    remainingSeconds: 3613
)
```

若 Pikmin Bloom 之後改了 UI 文字，調整 `OCRService.swift` 裡那個 regex 就好。

## 通知節奏

| 時間點 | 訊息 |
|---|---|
| T + 0:00 | 蘑菇結束 |
| T + 3:00 | 倒數 2 分鐘 — 新蘑菇快出現 |
| T + 4:00 | 倒數 1 分鐘 — 準備打開 Pikmin |
| T + 4:30 | 倒數 30 秒 — 提醒變頻繁 |
| T + 4:50 | 倒數 10 秒 — 最後提醒（time-sensitive）|
| T + 5:00 | 刷新時間 — 新蘑菇可能出現了（time-sensitive）|

## License

私人專案，目前未授權公開散布。

## Roadmap

- [x] OCR 截圖辨識
- [x] 多蘑菇倒數
- [x] 本地通知
- [x] Share Extension
- [x] Live Activity + Dynamic Island
- [x] Home Screen Widget
- [x] Apple Watch 通知（轉發 + 動作按鈕）
- [ ] 獨立 watchOS App + 錶面 Complication
- [ ] iCloud 同步（多裝置）
- [ ] AI 蘑菇分類（GPT/Claude Vision）
