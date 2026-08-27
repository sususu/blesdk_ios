# BleSdkDemo (iOS)

UIKit demo app for HuaWo wearable Bluetooth SDKs. It shows how to scan and connect a watch, bind/unbind, sync health data, configure goals and reminders, push music/album/AGPS packages over the Sifli channel, and run Sifli NAND firmware OTA.

**Requirements:** iOS 14+, Xcode with CocoaPods, a physical iPhone (Bluetooth LE features do not work on the Simulator).

---

## Open the project

```bash
cd /path/to/sdkdemo
pod install
open BleSdkDemo.xcworkspace
```

Use **BleSdkDemo.xcworkspace** (not the `.xcodeproj`). Select your signing Team for device builds.

---

## Architecture

| Layer | Role |
|-------|------|
| `BleSdkDemo/Sources/UI/` | Feature screens (scan, bind, home, music, album, AGPS, OTA, …) |
| `BleRepository` | Facade over `HwBluetoothSDK` + `SifliWatchfaceSDK` / `SFOTAManager` |
| `BoundDeviceStore` | Persists the last bound device (MAC, name, firmware metadata) |
| `Vendor/` | Local pod: `HwBluetoothSDK` (prebuilt static `.a`) |

SDK init happens once in `AppDelegate` via `BleRepository.shared.initSDK()` (HwBluetoothSDK, SifliWatchfaceSDK, Sifli OTA warm-up). Connection and reconnect events are surfaced to the home screen through `ConnectionEvent`.

Exclusive file transfers (music, album, AGPS, OTA) share one lock so concurrent pushes are rejected.

---

## Dependencies (`Podfile`)

| Pod | Source | Purpose |
|-----|--------|---------|
| `HwBluetoothSDK` | `Vendor/HwBluetoothSDK` | Scan, connect, bind, health, goals, alarms, notify, contacts |
| `WatchfaceSDK` | [HWdan/WatchfaceSDK](https://github.com/HWdan/WatchfaceSDK.git) `main` | Sifli music / album / AGPS / watchface push + OTA frameworks |
| `AiSDK` | [HWdan/HwAiSDK](https://github.com/HWdan/HwAiSDK.git) `main` | AI watchface pipeline (AFlash + Sifli install) |
| `AFNetworking` | CocoaPods | AiSDK HTTP dependency |
| `Zip` / `SSZipArchive` | Transitive (WatchfaceSDK) | Zip packaging — do not vendor locally |
| `JLBmpConvertKit` | Vendored by AiSDK | JieLi image encode |

BleSdkDemo uses **dynamic** `use_frameworks!` (same as AiSDK Example) so Zip and SSZipArchive keep separate minizip symbols.

```ruby
pod 'AiSDK', :git => 'https://github.com/HWdan/HwAiSDK.git', :branch => 'main'
pod 'WatchfaceSDK', :git => 'https://github.com/HWdan/WatchfaceSDK.git', :branch => 'main'
```

---

## Features

### Scan & connect

- Scan nearby BLE devices (timeout, RSSI-sorted list).
- Connect from a scan result or by MAC (`connectWithDevice` / `connectWithMac`).
- Manual disconnect disables auto-reconnect.

### Bind

Step UI driven by `BindFlowViewController`:

1. `startBindDevice` (confirm on the watch)
2. `setDeviceTime` / `setUserInfo` / metric units / language
3. `getDeviceInfo`
4. `endBind`
5. Pairing query (`getPairState` / `requestDeviceToPair` when needed)

On success the app stores a `BoundDeviceRecord` and turns on auto-reconnect.

### Unbind

`UnbindFlowViewController`:

1. `unbindDevice`
2. Disconnect
3. `removeConnectionCache`
4. Clear local bound record and disable auto-reconnect

iOS has no system `removeBond` API. After unbind, the demo prompts the user to **Settings → Bluetooth → Forget This Device**.

### Auto-reconnect

Enabled after a successful bind; disabled on manual disconnect or unbind.

- On disconnect (foreground + Bluetooth on): reconnect immediately, then retry every **0.5 s** on failure (per-attempt connect timeout **13 s**).
- No reconnect loop while the app is in the background.
- Reconnect again when returning to foreground or when Bluetooth becomes available.
- Prefer `getLastConnectedDevice()` when available; otherwise reconnect by stored MAC.

### Health sync

1. Query on-device counts (`getActivityNum` / related APIs)
2. Pull activities, heart rates, and sleeps
3. Delete each non-empty category from the device after a successful pull
4. Show a summary (counts + step sum) on the home log

### Goals

Read goals; write a fixed demo set (steps, calories, distance, sleep, duration).

### Alarms & reminders

- Alarm list / add demo weekday alarm / delete all
- Demo sedentary, drink-water, and hand-wash reminders

### Notifications & contacts

Social-app notification switches and contact list APIs exposed on the Notify feature screen.

### Music (Sifli)

1. Query music storage
2. Pick MP3 files
3. Stage under a temp tree `…/selectTemp/music/mp3/`
4. Push with `SifliWatchfaceSDK.setMusicFiles`
5. Progress UI, cancel via transfer lock / `stop()`

### Album (Sifli)

1. Query album slot IDs
2. Pick photos; center-crop / resize (editable width × height, default **466×466**)
3. Push with `SifliWatchfaceSDK.setPictures` (`QjsAlbumModel`s named by slot)

### AGPS

1. Download five `.pgl` ephemeris files
2. Append a 16-byte trailer per file
3. Zip as `music/gps/agps/…`
4. Push with `SifliWatchfaceSDK.syncZipFile` (`type: 3`, `byteAlign: true`)
5. Show AGPS validity window from device GPS status when available

### Firmware OTA (Sifli NAND only)

Screen: `OtaUpgradeViewController`. Push path: `SifliOtaPusher` → `SFOTAManager.startOTANand`.

1. **Refresh** — device MAC / firmware / product type / device id  
2. **Check update** — `POST https://test.huawo-wear.com/api/v1/devices/upgrades`  
3. **Start** — battery ≥ 30% (soft if query fails), upgrade status `none` when available  
4. Download & unzip the platform package; map bins (`hcpu` / `lcpu` / `patch*` / `ctrl` / `diff_ctrl` / `outdyn` / `outroot`)  
5. Diff packages also download the resource / picture package  
6. DFU over BLE (`tryResume: true`); progress roughly **0–40%** prepare, **40–100%** push  

For full packages, `resourcePath` is omitted (`nil`). An empty `file://` URL must not be passed (it fails immediately with `LoadResourceZipFailed`). Before DFU, the demo stops the Watchface transfer channel and waits until the OTA BLE core is `poweredOn`.

JL / Realtek OTA paths are not implemented in this demo.

### Watchface (Sifli)

Screen: `WatchfaceHostViewController` with three tabs.

| Tab | Behavior |
|-----|----------|
| **Online** | `GET …/api/v1/products/{deviceType}/watchfaces` → install: check installed names → switch if match, else download+MD5 → `setOnlineWatchface` (`type=5`, `byteAlign=false`) |
| **Custom** | Build `SlifiCustomWatchface` (bg / thumbnail / Time+widgets) → `setCustomWatchface` |
| **AI** | `AiSDK` lifecycle (`startWorking` + `AiDeviceInfo`); generation runs on the watch; App shows result/preview/install progress |

During install, back navigation and tab switching are locked.

---

## Localization

- `BleSdkDemo/Resources/en.lproj/Localizable.strings`
- `BleSdkDemo/Resources/zh-Hans.lproj/Localizable.strings`

Language can be switched from the home navigation bar (System / 中文 / English) via `LocaleHelper`.

---

## Permissions & capabilities

Declared in `BleSdkDemo/Supporting/Info.plist`:

| Key | Use |
|-----|-----|
| `NSBluetoothAlwaysUsageDescription` / `NSBluetoothPeripheralUsageDescription` | Scan, connect, sync |
| `NSPhotoLibraryUsageDescription` | Album image picker |
| `NSLocationWhenInUseUsageDescription` | AGPS / location-related helpers |
| `UIBackgroundModes` → `bluetooth-central` | BLE central in background |
| ATS exception for `starcourse.rx-networks.cn` | HTTP AGPS ephemeris download |

---

## Project layout

```
sdkdemo/
├── BleSdkDemo.xcworkspace          # Open this
├── BleSdkDemo.xcodeproj
├── Podfile / Podfile.lock
├── README.md
├── SDK_iOS.md                      # HwBluetoothSDK reference
├── BleSdkDemo/
│   ├── Sources/
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   ├── Models/
│   │   ├── Services/               # BleRepository, AGPS builder, OTA, locale
│   │   └── UI/                     # Home, Scan, Bind, Unbind, Features
│   ├── Resources/                  # en / zh-Hans strings
│   └── Supporting/                 # Info.plist, bridging header
├── Vendor/
│   └── HwBluetoothSDK/             # Prebuilt static Bluetooth SDK
└── Pods/                           # Generated by CocoaPods (AiSDK, WatchfaceSDK, Zip, …)
```

---

## Notes

- Run on a **real device** with Bluetooth enabled and the watch nearby / already paired as needed.
- Music / album / AGPS / OTA should not run at the same time (shared transfer lock).
- After unbind, forget the device in iOS Bluetooth settings before rebinding if pairing sticks.
- OTA uses the **test** upgrade host (`test.huawo-wear.com`). Point `OtaFirmwareApi` at another environment if needed.
- Broader SDK API documentation: root `SDK_iOS.md`.
