# Mac 端 Xcode 設定

Windows 端只能寫 `.swift` / `.plist` / `.entitlements` 純文字檔。Xcode project、target、code signing 都得在 Mac 上做。下面是把這個 repo 變成可 build 的 iOS app 的最小步驟。

## 1. 建立 Xcode Project

1. 把整個 repo 複製或 clone 到 Mac。
2. Xcode → **File → New → Project → iOS → App**
   - Product Name: `PikminMushroomAlarm`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**（如果選項裡有；沒有也沒關係）
   - Minimum Deployment: **iOS 17.0**
3. 存到 repo 根目錄旁邊，或乾脆存進 repo 根目錄（會生出 `PikminMushroomAlarm.xcodeproj`）。

## 2. 把 Windows 端寫好的檔案掛進 project

Xcode 預設會幫你生 `PikminMushroomAlarmApp.swift` 和 `ContentView.swift` —— 把它們**刪掉**（選 Move to Trash），然後把我們這邊的檔案拖進去。

從 Finder 拖以下檔案到 Xcode 左側 navigator 的 `PikminMushroomAlarm` group 裡，勾選 **Copy items if needed** 並把 target 設成 `PikminMushroomAlarm`：

```
PikminMushroomAlarm/PikminMushroomAlarmApp.swift
PikminMushroomAlarm/Models/Mushroom.swift
PikminMushroomAlarm/Models/NotificationOffset.swift
PikminMushroomAlarm/Models/AppGroup.swift
PikminMushroomAlarm/Services/OCRService.swift
PikminMushroomAlarm/Services/NotificationScheduler.swift
PikminMushroomAlarm/Services/MushroomStore.swift
PikminMushroomAlarm/Services/TimeFormatting.swift
PikminMushroomAlarm/Views/HomeView.swift
PikminMushroomAlarm/Views/HeroCardView.swift
PikminMushroomAlarm/Views/MushroomCardView.swift
PikminMushroomAlarm/Views/AddMushroomSheet.swift
PikminMushroomAlarm/Views/DeleteConfirmSheet.swift
PikminMushroomAlarm/Views/LaunchScreenView.swift
```

**Asset Catalog**: Xcode 新建 App 時會自帶一個 `Assets.xcassets`。**刪掉它**，改把 `PikminMushroomAlarm/Resources/Assets.xcassets/` 整個資料夾拖進 project（勾 main app target），裡面已經有 `LaunchBackground` 色票供 launch screen 引用。之後 App Icon 也會放這裡。

Info.plist 不要拖（Xcode 自己會管），改用我們 `Resources/Info.plist` 裡的 key 去 target 的 Info 頁手動補：
- `NSPhotoLibraryUsageDescription`
- `NSUserNotificationsUsageDescription`
- `CFBundleDevelopmentRegion` → `zh_TW`
- `CFBundleDisplayName` → `蘑菇鬧鐘`

## 3. 加上 Capabilities

選擇 main target → **Signing & Capabilities** → `+ Capability`：

1. **App Groups** — 點 `+` 加一個新 group。命名建議：`group.com.<your-team-id>.pikminmushroomalarm`。
   把 `AppGroup.swift` 裡的 `identifier` 改成你實際建立的字串。
   把 `Resources/PikminMushroomAlarm.entitlements` 裡的字串也改成一樣。
2. **Push Notifications**（如果之後要用）—— Phase 1 用本地通知不需要。
3. **Background Modes** → 勾 `Remote notifications`（同上，可暫不加）。

## 4. 加 Share Extension target

1. Xcode → **File → New → Target → iOS → Share Extension**
   - Product Name: `ShareExtension`
2. 同樣刪掉 Xcode 生的範本 `ShareViewController.swift` 和 `MainInterface.storyboard` 裡多餘內容，把這幾個檔案掛上 `ShareExtension` target：
   ```
   ShareExtension/ShareViewController.swift
   ShareExtension/Info.plist  (替換 Xcode 生的)
   ShareExtension/ShareExtension.entitlements
   ```
3. 還要把這些 **同時加 ShareExtension 為 target membership**（在檔案 inspector 勾第二個 target）：
   ```
   Mushroom.swift
   NotificationOffset.swift
   AppGroup.swift
   OCRService.swift
   NotificationScheduler.swift
   MushroomStore.swift
   ```
4. 對 ShareExtension target 開啟同一個 **App Group**。

## 5. 加 Widget Extension target（Live Activity + 動態島 + Home Screen Widget）

1. Xcode → **File → New → Target → iOS → Widget Extension**
   - Product Name: `PikminWidgets`
   - 勾 **Include Live Activity**（重要 — 沒勾的話之後 ActivityKit 那段會無法編譯）
   - Configuration Intent 不用勾
2. 刪除 Xcode 生的範本檔，把這幾個檔案掛到 `PikminWidgets` target：
   ```
   PikminWidgets/PikminWidgetsBundle.swift   (取代 Xcode 生的 @main)
   PikminWidgets/MushroomLiveActivity.swift
   PikminWidgets/MushroomWidget.swift
   PikminWidgets/Info.plist                  (取代 Xcode 生的)
   PikminWidgets/PikminWidgets.entitlements
   ```
3. 把這幾個檔案的 **target membership** 同時勾上 `PikminWidgets`（widget 跟主 app 共用）：
   ```
   Mushroom.swift
   NotificationOffset.swift
   AppGroup.swift
   MushroomActivityAttributes.swift
   ```
   注意 widget extension **不要** 勾 `OCRService` / `NotificationScheduler` / `MushroomStore` / 任何 View — widget 自己用 inline 的 ModelContainer 讀資料（見 `MushroomWidget.swift`）。
4. `PikminWidgets` target → **Signing & Capabilities** → 加同一個 **App Group**。
5. 主 app Info.plist 確認有這兩個 key（檔案裡已經加好）：
   - `NSSupportsLiveActivities = YES`
   - `NSSupportsLiveActivitiesFrequentUpdates = YES`

## 6. Build & Run

1. 選 iOS 17+ Simulator（iPhone 15 之類）→ Run。
2. 第一次跑會問通知權限，允許。
3. 點 `+` → 選相簿裡的測試截圖（你之後可以放幾張 Pikmin Bloom 截圖到模擬器相簿做測試）。
4. 真機測試 Share Extension：iPhone 上開 Pikmin Bloom 截圖 → 分享 → 應該會看到「蘑菇鬧鐘」。

## 7. 常見問題

- **OCR 抓不到剩餘時間** → 看 `OCRService.parseRemainingSeconds` 的 regex。如果 Pikmin Bloom 在英文 locale 顯示成 `1h 0m 13s` 之類，要在 `OCRService` 加新的 parser。先在 Vision 拿到的 `rawLines` debug 一下實際內容。
- **通知沒響** → 模擬器某些版本 time-sensitive 通知不會出現，用真機測。
- **Share Extension 看不到 mushroom 變化** → App Group identifier 兩邊一定要一字不差，否則寫入的是各自獨立的 sandbox。
- **動態島沒出現** → 只有 iPhone 14 Pro 以上、iOS 16.1+ 才有 Dynamic Island。模擬器要選對機型；真機要在 設定 → 蘑菇鬧鐘 → 即時動態 開啟。
- **Live Activity 從 Share Extension 沒啟動** → ActivityKit 不允許 extension 啟動 activity。主 app 下次進前景時會在 `reconcileLiveActivities()` 補上。
- **Widget 倒數凍住不動** → `Text(timerInterval:)` 才有自動 ticking；如果你改成 `Text(formatted)` 就會每分鐘才更新一次。
- **Apple Watch 收不到通知** →
  1. iPhone 跟 Watch 配對狀態 OK 嗎（Watch App 裡看）
  2. Watch App → 蘑菇鬧鐘 → 「通知」要設成 *鏡像 iPhone* 或 *自訂* 並允許通知
  3. iPhone 螢幕亮著的時候通知預設只在 iPhone 顯示；鎖屏或螢幕關掉時才會轉發到 Watch
- **「打開 Pikmin Bloom」按鈕沒反應** → 確認 Pikmin Bloom 已安裝；如果 Pikmin Bloom 改了 URL scheme，更新 `NotificationActionHandler.pikminBloomURL` 跟 Info.plist 的 `LSApplicationQueriesSchemes`。
