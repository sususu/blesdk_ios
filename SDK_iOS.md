# HwBluetoothSDK 使用文档（iOS）

**版本**：`3.2.17`（源码头文件宏 `HwBluetoothSDK_Version`；以运行时 `[[HwBluetoothSDK sharedInstance] version]` 为准）<br>
**入口类**：`HwBluetoothSDK`（单例门面）  
**最低 iOS 版本**：当前本地 Pod 声明 `13.0`；本 Demo 为 `14.0`<br>
**文档分工**：[README.md](README.md) 介绍 Demo 的运行与操作；本文介绍客户 App 的 SDK 集成和接口调用。

**说明**：本 SDK 通过 BLE 与华沃系智能手表/手环通信。对外统一通过 `[HwBluetoothSDK sharedInstance]` 调用，结果以 Block 异步返回。

> **调用约定**  
> - 业务 API（除扫描/连接相关状态查询外）需在 BLE 已连接后使用；多数产品还需完成绑定。  
> - **必须使用** `[HwBluetoothSDK sharedInstance]`，不要自行 `alloc` 新实例。  
> - 底层也可直接使用 `[HwBluetoothCenter sharedInstance]`（Demo 部分模块如此），优先使用门面类及其持有的 Service；门面未暴露的能力再按对应章节使用 Center。

---

## 目录

1. [集成方式（CocoaPods / Framework）](#1-集成方式cocoapods--framework)
2. [权限与 Info.plist 配置](#2-权限与-infoplist-配置)
3. [快速开始](#3-快速开始)
4. [回调约定与错误码](#4-回调约定与错误码)
5. [扫描 / 连接 / 断开 / 重连](#5-扫描--连接--断开--重连)
6. [配对与绑定](#6-配对与绑定)
7. [设备信息与环境同步](#7-设备信息与环境同步)
8. [目标设置](#8-目标设置)
9. [健康数据同步](#9-健康数据同步)
10. [运动 Workout](#10-运动-workout)
11. [闹钟与提醒](#11-闹钟与提醒)
12. [通知 / 通讯录](#12-通知--通讯录)
13. [表盘](#13-表盘)
14. [音乐与相册推送](#14-音乐与相册推送)
15. [天气](#15-天气)
16. [查找设备 / 遥控拍照](#16-查找设备--遥控拍照)
17. [OTA 固件升级](#17-ota-固件升级)
18. [GPS / 地图](#18-gps--地图)
19. [其他常用设置](#19-其他常用设置)
20. [全局监听器](#20-全局监听器)
21. [协议分支说明](#21-协议分支说明)
22. [推荐集成流程](#22-推荐集成流程)
23. [AiSDK 与 App 主动分析](#23-aisdk-与-app-主动分析)

---

## 1. 集成方式（CocoaPods / Framework）

当前仓库交付的是 **本地静态蓝牙库与头文件**，推荐通过随包提供的 Pod 集成。先运行 Demo 的步骤见 [README.md](README.md)。

### 1.1 CocoaPods（当前交付包推荐）

将本仓库的整个 `Vendor/HwBluetoothSDK` 目录复制到客户工程根目录，保留其中的 `.a`、framework 头文件、`include` 和 podspec，然后配置：

```ruby
platform :ios, '14.0' # 与 Demo 一致；仅蓝牙本地 Pod 的最低版本为 13.0
use_frameworks!

target 'YourApp' do
  pod 'HwBluetoothSDK', :path => 'Vendor/HwBluetoothSDK'
end
```

执行安装后打开客户工程生成的 `.xcworkspace`：

```bash
pod install
```

Objective-C 引入：

```objc
#import <HwBluetoothSDK/HwBluetoothSDK.h>
```

Swift 引入：

```swift
import HwBluetoothSDK
```

当前本地 Pod 版本为 `3.2.17`；对外记录版本时以运行时 `version` 为准。本地 Pod 不要求私有 Specs，也无需访问内网源码仓库。若收到其它交付形式，使用随包提供的版本和安装说明。

基础蓝牙能力无需 AiSDK / WatchfaceSDK；需要思澈传输或 AI 时，再加入对应依赖。复用完整 Demo 依赖时，请同时参考 [Podfile](Podfile) 中的动态 `use_frameworks!` 和 `post_install` 配置，避免遗漏模块及头文件搜索路径。

### 1.2 本地 Framework 方式

当前包请优先使用 §1.1 的本地 Pod；其中蓝牙二进制为静态库，**不要 Embed & Sign**。以下仅适用于另行收到可独立集成的 framework 时，具体链接方式以该交付包为准：

```text
YourApp/
  Frameworks/
    HwBluetoothSDK.framework
    # 按产品按需：RTK / 杰理等三方 OTA 库（以交付包为准）
```

Xcode 配置要点：

1. **General → Frameworks, Libraries, and Embedded Content**：`Embed & Sign`（动态库）或按交付说明设置为 `Do Not Embed`（静态）。  
2. **Build Settings → Framework Search Paths** 指向 framework 所在目录。  
3. **Other Linker Flags** 若交付说明要求 `-ObjC`，请加上。  
4. Swift / Mixed 工程确认 **Defines Module**。

### 1.3 按能力可选的额外依赖

| 能力 | 是否包含在 HwBluetoothSDK | 额外说明 |
|------|---------------------------|----------|
| BLE 扫描连接、健康数据、闹钟、天气、通用/差分 OTA | **是** | 通常只需集成本 SDK |
| 杰理多文件传输（音乐/相册/在线表盘） | **是**（`HwMultipleFileTransferService`） | 见 [§13](#13-表盘) / [§14](#14-音乐与相册推送) |
| 杰理自定义表盘配置下发 | **是**（`+JLWatchFace`） | `updateJLCustomWatceFace:` |
| 杰理 JL OTA V2 固件升级 | **是**（`HwOtaV2Service`） | 见 [§17.4](#174-方案-b杰理-jl-ota-v2生产主路径) |
| 瑞昱 / 阿波罗通用固件 OTA | **是**（`+Ota`） | 见 [§17.3](#173-方案-a通用-otahwotadatamodel) |
| 文件差分 OTA（备选） | **是**（`+FileDifferenceOta`） | 见 [§17.5](#175-方案-c文件差分-fdota备选通道) |
| 思澈固件 DFU | **否** | 需额外 `SifliOTAManagerSDK`（`SFOTAManager`），见 [§17.6](#176-方案-d思澈-sifli-dfu额外依赖) |
| 杰理图片像素转换 | **否** | 相册/自定义表盘推送前，产品侧常用 `JLBmpConvert`（随杰理交付包） |
| 思澈音乐 / 相册 / QJS 表盘 ZIP 推送 | **否** | 需额外 `SifliWatchfaceSDK`（及配套资源库），见 §13.4 / §14 |
| 瑞昱等经典表盘资源 OTA | **是**（`+Ota` / `+WatchFace`） | `HwOtaTypePicture`，见 §13.5 |

### 1.4 架构

- 真机：`arm64`（主流）  
- 模拟器：多数 BLE 场景无法完整验证；若含静态 framework，需按交付排除不支持的模拟器 arch。

### 1.5 Bitcode / 混淆

- Bitcode：按 Xcode / 苹果政策处理；近期交付一般关闭 Bitcode。  
- 无 Android 侧 ProGuard；Release 可开 Strip，业务侧无需额外 keep 规则。

---

## 2. 权限与 Info.plist 配置

### 2.1 Info.plist 必填 / 建议项

在 **App** 的 `Info.plist` 中声明（参考本仓库 [Info.plist](BleSdkDemo/Supporting/Info.plist)；除蓝牙用途说明外，其他权限按实际访问的系统能力添加）：

```xml
<!-- 蓝牙（iOS 13+ 必填 Always） -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>App 访问蓝牙是为了连接手表设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>App 访问蓝牙是为了连接手表设备</string>

<!-- 运动轨迹 / 天气定位 / AGPS 时建议配置 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>用于运动轨迹与位置相关功能</string>
<!-- 若需后台定位再增加 Always 文案 -->

<!-- 遥控拍照 / 扫码绑定 -->
<key>NSCameraUsageDescription</key>
<string>用于扫码绑定与遥控拍照</string>

<!-- 自定义表盘选图 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>用于自定义表盘与相册相关功能</string>

<!-- 读取系统日历（旧版 iOS）；仅下发自行组装的日程不需要日历权限 -->
<key>NSCalendarsUsageDescription</key>
<string>用于读取日历并同步日程到手表</string>
<!-- iOS 17+ 读取系统日历时使用完整访问权限 -->
<key>NSCalendarsFullAccessUsageDescription</key>
<string>用于读取日历并同步日程到手表</string>

<!-- 使用语音录音时；仅生成健康分析报告不需要 -->
<key>NSMicrophoneUsageDescription</key>
<string>用于语音输入</string>
```

### 2.2 后台模式（建议）

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <!-- 按产品需要再开 audio / fetch 等 -->
</array>
```

用于后台 BLE Central 通信，不代表 App 可无限执行或持续重连。重连由 App 管理；本 Demo 在前台且自动重连已开启时执行重连。

### 2.3 运行时申请

| 场景 | 系统行为 |
|------|----------|
| 首次扫描/连接 | 系统弹出蓝牙隐私授权（由 `NSBluetoothAlwaysUsageDescription` 文案驱动） |
| 定位相关业务 | 自行申请 `CLLocationManager` 授权 |
| 相册 / 相机 / 日历 | 对应系统权限面板 |

查询蓝牙是否可用：

```objc
HwBluetoothSDK *sdk = [HwBluetoothSDK sharedInstance];
if (sdk.powerOn) {
    // 可扫描 / 连接
} else {
    // 引导用户打开手机蓝牙
}
```

---

## 3. 快速开始

先完成 §1 的依赖与 §2 的权限配置。文档中含 `...`、占位变量或 App 自定义方法的代码是流程示例，需要补齐业务实现；具体接口签名以当前交付包头文件为准。

### 3.1 初始化

在 App 启动时初始化一次（例如 `AppDelegate`）；不要在每个页面或每个 Scene 重复初始化：

```objc
#import "HwBluetoothSDK.h"

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[HwBluetoothSDK sharedInstance] initSDK];
    // Demo 可打开日志：[[HwBluetoothLogger sharedInstance] setLogOn:YES];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[HwBluetoothSDK sharedInstance] destroySDK];
}
```

| API | 说明 |
|-----|------|
| `initSDK` | 初始化内部参数、监听蓝牙状态 |
| `destroySDK` | 释放资源、停止监听 |
| `version` | 返回 SDK 版本字符串，如 `3.2.17` |

> 与 Android `init(Application, maxMTU)` 不同：iOS **无 maxMTU 入参**（由系统与设备协商决定）。

### 3.2 最小闭环流程

```text
initSDK → 蓝牙授权 → scan → connect → startBind* → 同步时间/用户/单位/语言 → endBind
        → 业务 API → disconnect → destroySDK
```

---

## 4. 回调约定与错误码

### 4.1 回调模式

iOS 以 **Block** 为主，失败信息在 `NSError *`（`error.code` 即 `HwBCCode`）：

| 回调类型 | 典型签名 | 成功含义 |
|----------|----------|----------|
| `HwBoolCallback` | `(BOOL b, NSError *error)` | `b == YES` 且 `error == nil` |
| `HwBCIntegerCallback` | `(NSInteger n, NSError *error)` | 返回整型 |
| `HwStringCallback` | `(NSString *str, NSError *error)` | 返回字符串 |
| `HwConnectCallback` | `(NSError *error)` | `error == nil` 表示连接/断开成功 |
| `HwSearchDevicesCallback` | `(NSArray<HwBluetoothDevice *> *devices, NSError *error)` | 扫描结果（可能多次回调） |
| 各类业务回调 | 如 `HwActivitiesCallback`、`HwDeviceInfoCallback` | 见对应 `.h` |

通用定义见 `HwCommonDefines.h`；错误域与码见 `HwBluetoothError.h`。返回对象或数值的回调先检查 `error` 和必要的非空条件；布尔回调同时检查成功标志。SDK 原始回调不要假定在主线程，更新 UIKit 前用 `dispatch_async(dispatch_get_main_queue(), ^{ ... });`。

示例：

```objc
[[HwBluetoothSDK sharedInstance] getBatteryWithCallback:^(NSInteger n, NSError *error) {
    if (error) {
        NSLog(@"fail code=%ld", (long)error.code);
        return;
    }
    // n: 0~100
}];
```

### 4.2 常用错误码（`HwBCCode`）

| 常量 | 值 | 含义 | Android 近似 |
|------|----|------|--------------|
| `HwBCCodeBLEUnavailable` | 9 | 手机蓝牙不可用 | `BLUETOOTH_OFF` |
| `HwBCCodeBLEException` | 11 | 系统 BLE 异常 | — |
| `HwBCCodeBLEConnecting` | 12 | 正在连接中 | `ALREADY_CONNECTING` |
| `HwBCCodeBLEDisconnected` | 13 | BLE 已断开 | `DISCONNECTED` |
| `HwBCCodeRequestTimeout` | 14 | 任务超时 | `TASK_TIME_OUT` |
| `HwBCCodeRequestFailed` | 15 | 请求失败 | `DEVICE_CAN_NOT_BE_SCANNED` 等视场景 |
| `HwBCCodeConnectTimeout` | 20 | 连接超时 | `CONNECT_TIMEOUT` |
| `HwBCCodeSearchTimeout` | 21 | 扫描超时 | — |
| `HwBCCodeDisconnectTimeout` | 22 | 断连超时 | — |
| `HwBCCodeBindCancelByUserError` | 60 | 用户取消绑定 | `BIND_CANCELED_BY_USER` |
| `HwBCCodeBindDeviceBindedError` | 61 | 设备已被绑定 | — |
| `HwBCCodeWorkoutAlreadyStarted` | 64 | 已在运动中 | — |
| `HwBCCodeDeviceIsCharging` | 65 | 充电中不可开运动 | — |
| `HwBCCodePowerLowError` | 80 | 电量过低 | `POWER_LOW` |
| `HwBCCodeOtaError` | 90 | OTA 失败 | OTA 相关错误 |
| `HwBCCodeDeviceUnsuport` | 256 | 设备不支持 | — |

完整列表见 `HwBluetoothError.h`。也可为目标错误码注册统一处理：

```objc
[[HwBluetoothSDK sharedInstance] setHandler:^(HwBluetoothData *dataModel) {
    // 业务侧统一处理
} forErrorCode:HwBCCodeBLEDisconnected];
```

---

## 5. 扫描 / 连接 / 断开 / 重连

### 5.1 扫描

```objc
HwBluetoothSDK *sdk = [HwBluetoothSDK sharedInstance];

[sdk scanWithCallback:^(NSArray<HwBluetoothDevice *> *devices, NSError *error) {
    if (error) { /* 显示扫描错误 */ return; }
    for (HwBluetoothDevice *d in devices) {
        NSString *name = d.name;
        NSString *mac = d.macAddress;   // 可能为空（部分已系统配对外设）
        // 切到主线程更新设备列表；保留扫描返回的设备对象供用户选择连接
    }
} stopAfter:8.0 stopCallback:^{
    // 扫描超时结束
}];

// 用户选定设备或离开扫描页时调用 [sdk stopScan]；不要在启动扫描后立即停止。
```

设备模型：`HwBluetoothDevice`（包装 `CBPeripheral`，含 name / macAddress / uuid / rssi 等）。

### 5.2 连接

```objc
// 方式一：扫描到的设备
[sdk connectWithDevice:device callback:^(NSError *error) {
    if (!error) { /* 已连接 */ }
}];

// 方式二：蓝牙名
[sdk connectWithBleName:@"MyWatch" callback:^(NSError *error) { }];

// 方式三：MAC（已绑定设备重连常用）
[sdk connectWithMac:@"AA:BB:CC:DD:EE:FF"
            timeout:30
           callback:^(NSError *error) { }];
```

状态查询：

```objc
BOOL connected = sdk.connected;
BOOL connecting = sdk.connecting;
HwBluetoothDevice *cur = sdk.connectedDevice;
HwBluetoothDevice *last = [sdk getLastConnectedDevice];
NSArray *phoneConnected = [sdk getPhoneConnectedDevices]; // 手机系统已连接的外设
```

**iOS 注意：MAC 缓存**

当手表已在「系统蓝牙设置」里连接时，广播里可能拿不到 MAC。连接成功后建议：

```objc
[sdk getDeviceMacAddressWithCallback:^(NSString *mac, NSError *error) {
    if (mac.length) {
        [sdk updateMacAddressIfNeedWithMac:mac]; // 便于下次按 MAC 重连
    }
}];
```

### 5.3 断开 / 状态监听

```objc
[sdk disconnectWithCallback:^(NSError *error) { }];

// 清除本地连接缓存（解绑/换表时常用）
[sdk removeConnectionCache];

[sdk addBluetoothConnectionStateChangedCallback:^(HwBluetoothConnectionState state) {
    // Connecting / Connected / Disconnected
}];
[sdk addBluetoothStateChangedCallback:^(HwBluetoothState state) {
    // Disable / Unauthorized / Available
}];
```

> Android 的 `reconnect(mac)` 在 iOS 侧对应再次调用 `connectWithMac:`（或 `connectWithBleName:`）。可结合 `getLastConnectedDevice` 做业务层重连策略。

---

## 6. 配对与绑定

### 6.1 经典蓝牙配对（iOS 与 Android 差异大）

Android 有显式 `createBond` / `removeBond`。iOS 上系统负责配对弹窗与钥匙串；SDK 侧提供：

```objc
// 查询是否已配对
[sdk getPairStateWithCallback:^(BOOL b, NSError *error) { }];

// 请求设备发起/配合配对流程（按产品 SOP）
[sdk requestDeviceToPairWithCallback:^(BOOL b, NSError *error) { }];

// 查询 BT（经典蓝牙媒体通道）连接状态
[sdk getBtConnectionStateWithCallback:^(BOOL b, NSError *error) { }];

// 打开/关闭手表 BT 开关（通知固件侧）
[sdk setBtSwitch:YES callback:^(BOOL b, NSError *error) { }];
[sdk setBtSwitch:YES autoConnect:YES callback:^(BOOL b, NSError *error) { }];
```

配对完成通知（手机发起配对时）：

```objc
[sdk addDevicePairStateCallback:^(NSInteger pairState) { /* 见设备配对状态 */ }];
```

> Android 的 `createBond` / `removeBond` 在 iOS 无直接对等 API；经典蓝牙配对由系统处理，或通过本节 `requestDeviceToPair` / `getPairState` 配合产品 SOP。

### 6.2 设备绑定

标准绑定：

```objc
[sdk startBindDeviceWithCallback:^(BOOL b, NSError *error) {
    if (!b || error) return;
    // App 实现见 §22：串行同步环境，并在全部成功后调用 endBindDevice。
    [self syncEnvironmentAndEndBind];
}];

[sdk getBindStateWithCallback:^(HwBindState bindState, NSError *error) {
    // HwBindStateNone / HwBindStateDone / 另有 OTA 相关态（如 0x81）按固件
}];
```

思澈 / QJS：

```objc
[sdk startBindSifliDeviceWithCallback:^(BOOL b, NSError *error) { }];
// 无需表端确认：
[sdk startBindDeviceNoConfirmWithCallback:^(BOOL b, NSError *error) { }];
```

扫码绑定：

```objc
[sdk startQRBindDeviceWithCallback:^(BOOL b, NSError *error) { }];
```

LS16 多阶段绑定（专用）：

```objc
[sdk startLS16BindWithUserInfo:userInfo
                   isNewDevice:YES
         deviceBindingCallback:^(BOOL bindedBefore, NSError *error) { }
       deviceConfirmedCallback:^{ }
       deviceBindAgainCallback:^{ }
                finishCallback:^{ }
                failedCallback:^(NSInteger code) {
                    // 60：用户在表上点取消
                }];
```

解绑：

```objc
// App 先关闭自己的自动重连，再执行解绑。
[sdk unbindDeviceWithCallback:^(BOOL success, NSError *error) {
    if (!success || error) { /* 显示错误，决定是否重试 */ return; }
    [sdk disconnectWithCallback:^(NSError *disconnectError) {
        if (disconnectError) { /* 显示断开失败，保留重试入口 */ return; }
        [sdk removeConnectionCache];
        // 清除 App 保存的绑定记录，再提示用户到系统蓝牙设置中“忽略此设备”。
    }];
}];
```

---

## 7. 设备信息与环境同步

连接成功后建议先拉设备信息，再下发环境。

### 7.1 设备信息 / 电量

```objc
[sdk getDeviceInfoWithCallback:^(HwDeviceInfo *info, NSError *error) {
    // Objective-C: Id / type / firmwareVersion / battery / protocolVersion 等
    // Swift 中 Id 映射为 id；设备特征单独调用 getDeviceFeaturesWithCallback。
    // protocolVersion 较大时通常为 WL 一类新协议（与 Android ≥100 同源思路，以产品文档为准）
}];

[sdk getBatteryWithCallback:^(NSInteger n, NSError *error) { /* 0~100 */ }];
[sdk getBatteryStateWithCallback:^(NSInteger battery, BOOL charging, BOOL savingMode, NSError *error) { }];
[sdk getFirmwareVersionWithCallback:^(NSString *str, NSError *error) { }];
[sdk getDeviceTypeWithCallback:^(NSString *str, NSError *error) { }];
[sdk getDeviceIdWithCallback:^(NSString *str, NSError *error) { }];
[sdk getDeviceMacAddressWithCallback:^(NSString *str, NSError *error) { }];
[sdk getDeviceProtocolVersionWithCallback:^(NSInteger n, NSError *error) { }];
[sdk getDeviceFeaturesWithCallback:^(NSData *data, NSError *error) { }];
```

电量变化：

```objc
[sdk addBatteryStateChangedListener:^(NSInteger battery, BOOL charging, BOOL savingMode) { }];
```

### 7.2 用户信息 / 时间 / 单位 / 语言

```objc
HwUserInfo *user = [HwUserInfo new];
user.gender = HwSexMale; // HwSexMale / HwSexFemale
user.age = 28;
user.height = 175;        // cm
user.weight = 700;        // 0.1kg → 70.0kg
// id / birthday 等字段见 HwUserInfo.h

[sdk setUserInfo:user callback:^(BOOL b, NSError *error) { }];
[sdk getUserInfoWithCallback:^(HwUserInfo *userInfo, NSError *error) { }];

[sdk setDeviceTime:[NSDate date] is24H:YES callback:^(BOOL b, NSError *error) { }];
[sdk setTimeFormat:HwTimeFormat24H callback:^(BOOL b, NSError *error) { }];

[sdk setUnit:HwUnitMetric callback:^(BOOL b, NSError *error) { }];
[sdk getUnitWithCallback:^(HwUnit unit, NSError *error) { }];

[sdk setLanguage:HwLanguageChineseSimplified callback:^(BOOL b, NSError *error) { }];
[sdk getLanguageWithCallback:^(HwLanguage language, NSError *error) { }];
[sdk getDeviceSupportedLanguages:^(NSArray *langs, NSError *error) { }];
```

---

## 8. 目标设置

```objc
// HwGoalType：步数 / 卡路里 / 距离 / 睡眠 / 运动时长等，见枚举定义
[sdk setGoalWithType:HwGoalTypeStep
                goal:8000
            callback:^(BOOL b, NSError *error) { }];

[sdk getGoalWithCallback:^(HwGoal *goal, NSError *error) { }];

[sdk addGoalUpdatedListener:^(HwGoalType type, NSInteger value) { }];
[sdk addGoalsUpdatedListener:^(NSArray<HwGoalValue *> *values) { }];
```

---

## 9. 健康数据同步

### 9.1 计数 + 分批拉取（推荐主路径）

```objc
[sdk getHealthDataCountWithCallback:^(NSUInteger activityCount,
                                      NSUInteger sleepPointCount,
                                      NSUInteger heartrateCount,
                                      NSUInteger hrfCount,
                                      NSError *error) {
    if (error) return;

    if (activityCount > 0) {
        [sdk getActivities:activityCount callback:^(NSArray<HwActivity *> *list, NSError *error) {
            if (error || !list) { /* 读取失败：不要删除 */ return; }
            // App 可靠保存成功后，再在保存完成回调中调用 deleteActivitiesWithCallback:。
        }];
    }
    if (sleepPointCount > 0) {
        [sdk getSleeps:sleepPointCount callback:^(NSArray<HwSleep *> *list, NSError *error) {
            if (error || !list) { return; }
            // 可靠保存成功后，再调用 deleteSleepsWithCallback:。
        }];
    }
    if (heartrateCount > 0) {
        [sdk getHeartrates:heartrateCount callback:^(NSArray<HwHeartRate *> *list, NSError *error) {
            if (error || !list) { return; }
            // 可靠保存成功后，再调用 deleteHeartratesWithCallback:。
        }];
    }
}];
```

其它类型：

```objc
[sdk getBpsWithCallback:^(NSArray *list, NSError *error) { }];
[sdk delBpsWithCallback:^(BOOL b, NSError *error) { }];

[sdk getPAIsWithCallback:^(NSArray<HwPAI *> *list, NSError *error) { }];
[sdk delPAIsWithCallback:^(BOOL b, NSError *error) { }];

[sdk getVO2maxsWithCallback:^(NSArray *list, NSError *error) { }];
[sdk delVO2maxsWithCallback:^(BOOL b, NSError *error) { }];

[sdk deleteStressWithCallback:^(BOOL b, NSError *error) { }];
[sdk deleteBloodOxygenWithCallback:^(BOOL b, NSError *error) { }];
```

读取失败或落库失败时保留设备数据供重试；不要将空结果或同步完成提示当作删除条件。通用数据读取在 SDK 内按请求处理，App 应串行安排同步批次，避免与传输任务并发。

### 9.2 LS / BigData 路径

LS16 按时间窗：

```objc
[sdk getHealthDataForLSWithStartTime:start
                              endTime:end
                   activitiesCallback:...
                      activesCallback:...
                       sleepsCallback:...
                   heartratesCallback:...
                        spo2sCallback:...
                       stressCallback:...];
```

大数据批量（`HwBluetoothCenter+BigDataSport`）：

```objc
// 经由 HwBluetoothCenter category，门面若未透出则用 Center：
[[HwBluetoothCenter sharedInstance] getHeartRateBigDataWithCallback:...];
[[HwBluetoothCenter sharedInstance] getSleepBigDataWithCallback:...];
[[HwBluetoothCenter sharedInstance] getStressBigDataWithCallback:...];
[[HwBluetoothCenter sharedInstance] getBloodOxygenBigDataWithCallback:...];
[[HwBluetoothCenter sharedInstance] getSportDetailBigDataWithCallback:...];
[[HwBluetoothCenter sharedInstance] getWorkoutsBigDataWithCallback:...];
```

> Android 的 `getActivityData` / `getActivityDataV2` 在 iOS 拆为「计数拉取」或「BigData / ForLS」路径，按产品协议选择。

### 9.3 监测开关与告警

```objc
[sdk setHeartrateMonitoringInterval:10 callback:^(BOOL b, NSError *error) { }]; // 分钟；0=关
[sdk getHeartrateMonitoringIntervalWithCallback:^(NSInteger n, NSError *error) { }];

HwHeartrateAlarm *alarm = [HwHeartrateAlarm new];
// 填充高低阈值、开关等
[sdk setHeartrateAlarm:alarm callback:^(BOOL b, NSError *error) { }];
[sdk getHeartrateAlarmWithCallback:^(HwHeartrateAlarm *hrAlarm, NSError *error) { }];

[sdk setSpO2MonitorEnable:YES callback:^(BOOL b, NSError *error) { }];
[sdk setStressMonitorEnable:YES callback:^(BOOL b, NSError *error) { }];
[sdk setBloodOxygenAlertWithSpan:90 callback:^(BOOL b, NSError *error) { }];

[sdk startSpO2MonitoringWithCallback:^(BOOL b, NSError *error) { }];
[sdk stopSpO2MonitoringWithCallback:^(BOOL b, NSError *error) { }];

[sdk addHeartrateValueChangedListener:^(NSInteger bpm) { }];
[sdk addSpo2ValueChangedListener:^(NSInteger spo2, long time) { }];
[sdk addStressValueChangedListener:^(NSInteger stress) { }];
```

健康数据主动变更：

```objc
[sdk addHealthDataUpdatedListener:^(HwHealthData *data) {
    // 见 §9.4.11 HwHealthData
}];
```

### 9.4 健康数据模型详解

除非特别说明：

- `time` / `startTime` / `endTime` 为 **Unix 时间戳，单位秒**（`NSTimeInterval`）。  
- `index` / `hIndex` **不能当作业务唯一键**，仅便于调试/日志；入库请用时间戳 + 业务规则。  
- 拉取入库后建议调用对应 `delete*`，避免手表堆积与下次重复同步。

#### 9.4.1 `HwActivity`（活动 / 步数详情）

对应 `getActivities:` / BigData 运动详情等。头文件：`HwActivity.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `NSUInteger` | 调试索引，非唯一 ID |
| `time` | `NSTimeInterval` | 该条数据产生时间，**秒** |
| `step` | `NSUInteger` | 步数 |
| `calorie` | `NSUInteger` | 卡路里（活动相关；具体量纲以固件/产品约定为准，常见为 kcal 或固件内部单位） |
| `staticCalorie` | `NSUInteger` | 静态 / 基础卡路里 |
| `distance` | `NSUInteger` | 距离，单位 **米** |
| `duration` | `NSUInteger` | 活动时长，单位 **分钟** |
| `avgBpm` | `NSUInteger` | 该时段平均心率（bpm）；无数据时可能为 0 |

#### 9.4.2 `HwActive`（活跃状态点，LS 等）

对应 LS 路径 `activesCallback` 等。头文件：`HwActive.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `NSUInteger` | 调试索引 |
| `time` | `NSTimeInterval` | 采样时间，**秒** |
| `state` | `HwActiveState` | 活跃状态，见下表 |

`HwActiveState`：

| 枚举 | 值 | 含义 |
|------|----|------|
| `HwActiveStateOffHand` | 0x00 | 离手 |
| `HwActiveStateActive` | 0x01 | 活跃 |
| `HwActiveStateInactive` | 0x02 | 不活跃 |

#### 9.4.3 `HwSleep`（整段睡眠）与 `HwSleepPoint`（睡眠点）

`getSleeps:` 等返回的是已汇总的 **`HwSleep`**；设备侧原始粒度常为睡眠点，`getHealthDataCount` 里的 `sleepPointCount` 对应点数量。头文件：`HwSleep.h` / `HwSleepPoint.h`。

**`HwSleep`**

| 属性 | 类型 | 说明 |
|------|------|------|
| `startTime` | `NSTimeInterval` | 入睡开始，**秒** |
| `endTime` | `NSTimeInterval` | 睡眠结束，**秒** |
| `awakeDuration` | `NSUInteger` | 整段中清醒总时长，**秒** |
| `lightDuration` | `NSUInteger` | 浅睡总时长，**秒** |
| `deepDuration` | `NSUInteger` | 深睡总时长，**秒** |
| `remDuration` | `NSUInteger` | REM 总时长，**秒** |
| `totalDuration` | `NSUInteger` | 睡眠总时长，**秒** |
| `awakeCount` | `NSUInteger` | 醒来次数 |
| `sleepPoints` | `NSArray<HwSleepPoint *>` | 分段详情 |

工具方法：

- `+ fromSleepPoints:`：由睡眠点列表聚合为 `HwSleep` 数组。  
- `+ merge:timeInterval:`：合并相近睡眠段；思澈平台常用间隔 `2 * 3600`，其它老项目常用 `1 * 3600`（秒）。  
- `+ mergeNighttime:timeInterval:timezone:`：按时区合并夜间睡眠。

**`HwSleepPoint`**

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `NSUInteger` | 调试索引 |
| `time` | `NSTimeInterval` | 状态点时间，**秒** |
| `status` | `HwSleepStatus` | 睡眠状态 |

`HwSleepStatus`：

| 枚举 | 值 | 含义 |
|------|----|------|
| `HwSleepStatusDeep` | 0 | 深睡 |
| `HwSleepStatusLight` | 1 | 浅睡 |
| `HwSleepStatusAwake` | 2 | 清醒 |
| `HwSleepStatusPrepare` | 3 | 准备入睡 |
| `HwSleepStatusREM` | 5 | 快速眼动 |
| `HwSleepStatusEnterNapSleep` / `EnterSleepMode` | 0x10 | 进入小睡 / 睡眠模式 |
| `HwSleepStatusExitSleepMode1` | 0x11 | 退出睡眠（非预设） |
| `HwSleepStatusExitSleepMode2` | 0x12 | 退出睡眠（预设） |

#### 9.4.4 `HwHeartRate`（心率）

对应 `getHeartrates:` / `getNewestHeartrateWithCallback:` 等。头文件：`HwHeartRate.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `NSUInteger` | 调试索引 |
| `time` | `NSTimeInterval` | 采样时间，**秒** |
| `bmp` | `NSUInteger` | 心率值（bpm）。字段名历史拼写为 `bmp`，语义即 bpm |

#### 9.4.5 `HwHeartrateFatigue`（HRV / 压力 / 血氧合一协议）

对应 `getHealthDataCount` 的 `hrfCount` 与 `getHeartrateFatigues:`。头文件：`HwHeartrateFatigue.h`。

> 固件将心率变异相关、压力、血氧合在同一协议里，用三个字段区分类型：**同一对象上通常只有一个非 0**。

| 属性 | 类型 | 说明 |
|------|------|------|
| `hIndex` | `NSInteger` | 调试索引 |
| `time` | `long` | 产生时间，单位 **毫秒**（与其它健康模型「秒」不同，入库时注意换算） |
| `fatigue` | `NSInteger` | 预留 / 当前不可用 |
| `stress` | `NSInteger` | ≠0 表示本条为**压力**数据 |
| `bloodOxygen` | `NSInteger` | ≠0 表示本条为 **SpO2** 数据 |

新协议机型也可用独立模型 `HwStress` / `HwSpo2`（见下）。

#### 9.4.6 `HwStress`（压力）

对应压力 BigData / LS `stressCallback` / `deleteStressWithCallback:` 等。头文件：`HwStress.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `NSUInteger` | 调试索引 |
| `time` | `NSTimeInterval` | 采样时间，**秒** |
| `stress` | `NSInteger` | 压力值（量纲与有效范围以固件为准） |

#### 9.4.7 `HwSpo2`（血氧）

对应血氧 BigData / LS `spo2sCallback` / `deleteBloodOxygenWithCallback:` 等。头文件：`HwSpo2.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `NSUInteger` | 调试索引 |
| `time` | `NSTimeInterval` | 采样时间，**秒** |
| `spo2` | `NSInteger` | 血氧饱和度，一般为 **0~100**（%） |

#### 9.4.8 `HwBloodPressure`（血压）

对应 `getBpsWithCallback:` / `delBpsWithCallback:`。头文件：`HwBloodPressure.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `NSUInteger` | 调试索引 |
| `time` | `NSTimeInterval` | 测量时间，**秒** |
| `systolic` | `NSInteger` | 收缩压（高压），单位 mmHg |
| `diastolic` | `NSInteger` | 舒张压（低压），单位 mmHg |

#### 9.4.9 `HwPAI`（个人活性指数）

对应 `getPAIsWithCallback:` / `delPAIsWithCallback:`。头文件：`HwPAI.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `time` | `NSTimeInterval` | 数据时间，**秒** |
| `totalValue` | `NSInteger` | PAI 总值 |
| `lowValue` | `NSInteger` | 低强度对应 PAI |
| `medialValue` | `NSInteger` | 中强度对应 PAI |
| `highValue` | `NSInteger` | 高强度对应 PAI |
| `lowDuration` | `NSInteger` | 低强度时长（量纲以固件为准，常见为分钟） |
| `medialDuration` | `NSInteger` | 中强度时长 |
| `highDuration` | `NSInteger` | 高强度时长 |

#### 9.4.10 `HwVO2max`（最大摄氧量）

对应 `getVO2maxsWithCallback:` / `delVO2maxsWithCallback:`。头文件：`HwVO2max.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `time` | `NSTimeInterval` | 数据时间，**秒** |
| `value` | `NSInteger` | VO₂max 数值（单位与精度以固件/产品约定为准） |

#### 9.4.11 `HwHealthData` / `HwHealthDailyData`（汇总日报，监听推送）

用于 `addHealthDataUpdatedListener:` 等「表端推送汇总」场景，不是 `getActivities:` 的明细列表。头文件：`HwHealthData.h`。

**`HwHealthData`**

| 属性 | 类型 | 说明 |
|------|------|------|
| `gender` / `age` / `weight` / `height` | `NSInteger` | 用户体征快照（与下发用户信息对应） |
| `unit` | `NSInteger` | 单位制 |
| `dailyDataList` | `NSArray<HwHealthDailyData *>` | 按日汇总列表 |

**`HwHealthDailyData`**

| 属性 | 类型 | 说明 |
|------|------|------|
| `day` | `NSInteger` | 日期标识（编码方式以固件为准） |
| `step` | `NSInteger` | 日步数 |
| `minHr` / `maxHr` / `avgHr` | `NSInteger` | 日心率最小 / 最大 / 平均 |
| `minSpO2` / `maxSpO2` / `avgSpO2` | `NSInteger` | 日血氧最小 / 最大 / 平均 |
| `minStress` / `maxStress` / `avgStress` | `NSInteger` | 日压力最小 / 最大 / 平均 |
| `minBP` / `maxBP` / `avgBP` | `HwBloodPressure *` | 日血压极值 / 均值对象 |
| `sleep` | `NSInteger` | 日睡眠相关汇总 |
| `PAI` | `NSInteger` | 日 PAI |

#### 9.4.12 `HwHeartrateAlarm`（心率告警配置，非历史数据）

配置项，对应 `getHeartrateAlarmWithCallback:` / `setHeartrateAlarm:`。头文件：`HwHeartrateAlarm.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `on` | `BOOL` | 是否开启心率告警 |
| `upperLimit` | `NSUInteger` | 心率上限（bpm），达到后表端提醒 |
| `lowerLimit` | `NSUInteger` | 心率下限（bpm） |

#### 9.4.13 拉取 API ↔ 模型速查

| 数据 | 主要模型 | 典型拉取 | 典型删除 |
|------|----------|----------|----------|
| 活动 / 步数 | `HwActivity` | `getActivities:` | `deleteActivitiesWithCallback:` |
| 活跃状态 | `HwActive` | LS `getActiveForLS…` | — |
| 睡眠 | `HwSleep` / `HwSleepPoint` | `getSleeps:` | `deleteSleepsWithCallback:` |
| 心率 | `HwHeartRate` | `getHeartrates:` | `deleteHeartratesWithCallback:` |
| HRV 合一包 | `HwHeartrateFatigue` | `getHeartrateFatigues:` | `deleteHeartrateFatiguesWithCallback:` |
| 压力 | `HwStress` | BigData / LS stress | `deleteStressWithCallback:` |
| 血氧 | `HwSpo2` | BigData / LS spo2 | `deleteBloodOxygenWithCallback:` |
| 血压 | `HwBloodPressure` | `getBpsWithCallback:` | `delBpsWithCallback:` |
| PAI | `HwPAI` | `getPAIsWithCallback:` | `delPAIsWithCallback:` |
| VO₂max | `HwVO2max` | `getVO2maxsWithCallback:` | `delVO2maxsWithCallback:` |
| 日报汇总 | `HwHealthData` | 监听推送 | — |

---

### 9.5 杰理皮肤温度与呼吸频率

Demo 入口：**首页 → 健康数据 → 同步数据（杰理）**，实现见 `JieliHealthRepository` / `JieliHealthSyncViewController`。

| 数据 | 读取（HwBluetoothCenter） | 模型／数值单位 | 手动删除 |
| --- | --- | --- | --- |
| 皮肤温度 | `getSkinTemperatureBigDataWithCallback:` | `HwTemperature.temperature`，摄氏度浮点数 | `delSkinTemperatureBigDataWithCallback:` |
| 呼吸频率 | `getBreathsBigDataWithCallback:` | `HwBreaths.rpmVal`，次／分钟 | `delBreathsBigDataWithCallback:` |

两种模型的 `time` 均为 Unix **秒**，显示时直接构造 `Date(timeIntervalSince1970:)`；不要按 `HwWorkout` 的毫秒时间戳处理。结果按最新时间排序，空列表是正常结果。Demo 读取后不会自动删除，删除需用户确认。

### 9.6 杰理手动测量与自动监测

手动测量入口：**首页 → 健康数据 → 手动测量（杰理）**。

```swift
let sdk = HwBluetoothSDK.sharedInstance()
sdk.startMonitoring(with: .skinTemperature) { success, error in
    // 写入操作须同时检查 success 和 error。
}
sdk.stopMonitoring(with: .skinTemperature, callback: nil)
```

| 类型（HwMonitorDataType） | 实时监听／对应移除方法 |
| --- | --- |
| `.heartRate` | `addHeartrateValueChangedListener` / `removeHeartrateValueChangedListener` |
| `.HRV` | `addRealtimeHRVUpdateListener` / `removeRealtimeHRVUpdateListener` |
| `.spO2` | `addSpo2ValueChangedListener` / `removeSpo2ValueChangedListener` |
| `.stress` | `addStressValueChangedListener` / `removeStressValueChangedListener` |
| `.skinTemperature` | `addRealtimeSkinTemperatureUpdateListener` / `removeRealtimeSkinTemperatureUpdateListener` |
| `.respiratoryRate` | `addRealtimeRPMUpdateListener` / `removeRealtimeRPMUpdateListener` |

先注册监听再启动；保留 Block 引用，以对应的 remove 方法移除本页监听，不要调用 removeAll 影响其他模块。还需处理 `addNotProperlyWornCallback`、`addMonitorStateChangedCallback`、断连及 `addTimedMeasureListener`；后者的 `time` 为**毫秒**。SDK 回调更新 UIKit 前切到主线程。

Demo 测量期间禁止切换类型，60 秒无结束通知时主动停止；退出页面、进入后台时移除监听并停止设备测量。停止失败保留重试入口，旧会话回调不更新新会话。

自动监测入口：**首页 → 健康数据 → 自动监测（杰理）**，实现见 `JieliAutoMonitorViewController`。

| 数据 | Swift 读取接口 | Swift 写入接口 | 本 Demo 的开启／关闭值 |
| --- | --- | --- | --- |
| 心率 | `sdk.getHeartrateMonitoringInterval(callback:)` | `sdk.setHeartrateMonitoringInterval(_:callback:)` | 5／0 分钟 |
| HRV（Center） | `center.getAutoTrackHRV(callback:)` | `center.setAutoHRVWithStatus(_:callback:)` | 1／0 |
| 血氧 | `sdk.getSpO2MonitorEnable(callback:)` | `sdk.setSpO2MonitorEnable(_:callback:)` | true／false |
| 压力 | `sdk.getStressMonitorEnable(callback:)` | `sdk.setStressMonitorEnable(_:callback:)` | true／false |
| 皮肤温度 | `sdk.getSkinTemperatureMonitorInterval(callback:)` | `sdk.setSkinTemperatureMonitorInterval(_:callback:)` | 60／0 分钟 |
| 呼吸频率 | `sdk.getRespiratoryRateMonitorInterval(callback:)` | `sdk.setRespiratoryRateMonitorInterval(_:callback:)` | 60／0 分钟 |

间隔是 Demo 策略，不代表所有产品固定使用该值；皮肤温度、呼吸频率沿用当前 hawofit 的 60 分钟设置。进入页面顺序读取设备实际状态，读取失败的项目禁用开关，可刷新重试；保存失败回滚，断连或更换设备时丢弃旧结果。读取布尔值 false 且没有 error 表示“关闭”，不表示读取失败。具体功能是否支持由机型／固件决定。

---

## 10. 运动 Workout

### 10.1 同步历史运动

```objc
[sdk getWorkoutsWithCallback:^(NSArray<HwWorkout *> *list, NSError *error) {
    // 轨迹点等可能需额外接口，见 +Workout / +WorkoutTrack
    if (error || !list) { return; }
    // App 可靠保存成功后，再在保存完成回调中调用 deleteWorkoutsWithCallback:。
}];

// LS 时间窗
[sdk getWorkoutsForLSWithStartTime:start endTime:end callback:^(NSArray *list, NSError *error) { }];
```

### 10.2 App 控制运动

```objc
[sdk startWorkoutWithType:HwWorkoutTypeOutdoorRunning callback:^(BOOL b, NSError *error) { }];
[sdk suspendWorkoutWithCallback:^(BOOL b, NSError *error) { }];
[sdk resumeWorkoutWithCallback:^(BOOL b, NSError *error) { }];
[sdk stopWorkoutWithCallback:^(BOOL b, NSError *error) { }];

[sdk getWorkoutStateWithCallback:^(NSInteger state, NSError *error) { }]; // 1 运动中 / 0 否

[sdk addWorkoutRealtimeDataUpdateListener:^(HwWorkoutRealtimeData *data) {
    // 步数 / 距离 / 心率 / GPS 等
}];
[sdk addWorkoutStateUpdatedCallback:^(BOOL stopped) { }];

// App 向手表推送实时数据（手机主 GPS 运动等场景）
[sdk setWorkoutRealtimeData:realtimeData callback:^(BOOL b, NSError *error) { }];
```

运动中下发 GPS：

```objc
[sdk setDeviceGpsLocationWithLongitude:lng latitude:lat time:ts callback:^(BOOL b, NSError *error) { }];
```

### 10.3 运动数据模型详解

除非特别说明：

- **`HwWorkout.startTime` / `endTime`、采样点 `time`、实时数据 `time` 多为毫秒级时间戳**（与健康数据「秒」不同，入库时注意换算）。  
- `index` 仅便于调试，勿作业务唯一键。  
- 无效/无此指标的采样点字段常见填 **-255**（见 `HwWorkoutPoint`）。  
- 历史数据成功读取且可靠保存后，才按业务策略调用 `deleteWorkoutsWithCallback:`。

#### 10.3.1 `HwWorkoutType`（运动类型）

定义于 `HwWorkout.h`，取值很多（户外跑、骑行、游泳、瑜伽及大量扩展类型；含十六进制段及 LS 专用值）。App 控制运动时传入枚举，例如：

| 常用枚举 | 值 | 含义 |
|----------|----|------|
| `HwWorkoutTypeOutdoorWalking` | 1 | 户外健走 |
| `HwWorkoutTypeOutdoorRunning` | 2 | 户外跑步 |
| `HwWorkoutTypeSwimming` | 4 | 游泳 |
| `HwWorkoutTypeOutdoorCycling` | 5 | 户外骑行 |
| `HwWorkoutTypeIndoorWalking` | 13 | 室内健走 |
| `HwWorkoutTypeIndoorRunning` | 14 | 室内跑步 |
| `HwWorkoutTypeYoga` | 15 | 瑜伽 |
| `HwWorkoutTypeHIIT` | 109 | 高强度间歇训练 |
| `HwWorkoutTypeIndoorSwimming` | 145 | 室内游泳 |
| `HwWorkoutTypeOutdoorSwimming` | 146 | 室外游泳 |

完整列表以 `HwWorkout.h` 中 `HwWorkoutType` 为准；机型实际支持类型以固件能力为准。

#### 10.3.2 `HwWorkout`（历史运动记录）

对应 `getWorkoutsWithCallback:` / LS / BigData workouts。头文件：`HwWorkout.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `NSUInteger` | 调试索引 |
| `startTime` | `long` | 开始时间，**毫秒** |
| `endTime` | `long` | 结束时间，**毫秒** |
| `pausedTimeSections` | `NSArray *` | 暂停区间；元素一般为 `HwTimeSection`（含起止时间） |
| `type` | `HwWorkoutType` | 运动类型 |
| `step` | `NSUInteger` | 步数 |
| `calorie` | `NSUInteger` | 卡路里 |
| `distance` | `NSUInteger` | 距离，单位 **米** |
| `duration` | `NSUInteger` | 运动时长（固件侧整型时长；展示前按产品换算为秒/分） |
| `bpm` | `NSUInteger` | 平均心率 |
| `maxBpm` / `minBpm` | `NSUInteger` | 最高 / 最低心率 |
| `pace` | `NSUInteger` | 配速，**秒/千米** |
| `speed` | `NSUInteger` | 速度，**千米/小时** |
| `lapDuration` | `NSUInteger` | 圈时相关（约「一圈多少分钟」，按固件） |
| `cadence` | `NSUInteger` | 步频，**步/分钟** |
| `warmUpDuration` 等 | `NSUInteger` | 多运动心率区间时长：热身 / 燃脂 / 有氧 / 无氧 / 极限 / 静息 |
| `elevationGain` / `elevationLoss` / `elevationNow` | `NSInteger` | 爬升 / 下降 / 当前海拔相关 |
| `actionCount` | `NSUInteger` | 动作次数（游泳划次等，视类型） |
| `swolf` | `NSUInteger` | SWOLF |
| `actionPosture` | `NSUInteger` | 动作姿势 |
| `laps` | `NSUInteger` | 圈数 |
| `actionRate` | `NSUInteger` | 动作频率 |
| `maxConsecutiveActionCount` | `NSUInteger` | 最大连续动作次数 |
| `interruptActionCount` | `NSUInteger` | 中断动作次数 |
| `actualDuration1` / `actualDuration2` | `double` | 拉桨 / 回桨时长，秒，可含小数 |
| `actualDuration3` | `NSUInteger` | 第三段时长，按产品约定 |
| `aerobicTrainingEffect` / `anaerobicTrainingEffect` | `NSUInteger` | 有氧 / 无氧训练效果 |
| `strike` | `NSUInteger` | 步幅，单位 **0.01 米** |
| `recoveryTime` | `NSUInteger` | 锻炼恢复时间 |
| `poolLength` | `NSUInteger` | 泳池长度 |
| `vo2max` | `NSUInteger` | 本次相关最大摄氧量 |
| `maxPressure` / `minPressure` | `NSInteger` | 最大 / 最小气压 |
| `supportedNav` | `BOOL` | 是否支持导航相关能力 |
| `workoutPoints` | `NSArray<HwWorkoutPoint *>` | 过程采样点 |
| `workoutGpsPoints` | `NSArray<HwWorkoutGpsPoint *>` | GPS 轨迹点 |

`HwTimeSection`（暂停区间元素，`HwTimeSection.h`）：

| 属性 | 说明 |
|------|------|
| `startTime` / `endTime` | 暂停段起止时间（量纲与固件解析一致，接入时按产品确认） |

部分字段仅特定运动类型或高版本固件有值，其它为 0。

#### 10.3.3 `HwWorkoutPoint`（运动过程采样点）

挂在 `HwWorkout.workoutPoints` 上；亦可由轨迹相关接口另行拉取。头文件：`HwWorkoutPoint.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `time` | `long` | 绝对时间，**毫秒** |
| `offsetTime` | `long` | 相对运动开始的偏移时间 |
| `step` | `NSInteger` | 步数；无数据为 **-255** |
| `calories` | `NSInteger` | 卡路里；无 **-255** |
| `distance` | `NSInteger` | 距离，米；无 **-255** |
| `duration` | `NSInteger` | 时长相关，分钟量级（见注释）；无 **-255** |
| `bpm` | `NSInteger` | 心率；无 **-255** |
| `speed` | `NSInteger` | 速度，**km/h**；无 **-255** |
| `pace` | `NSInteger` | 配速，**秒/km**；无 **-255** |
| `actionPosture` / `currentSwolf` / `actionCount` 等 | `NSInteger` | 游泳等动作/效率相关瞬时值 |
| `avgActionRate` / `maxActionRate` | `NSInteger` | 平均 / 最大动作频率 |
| `currentAvgPace` | `NSInteger` | 当前平均配速 |
| `consecutiveActionCount` | `NSInteger` | 连续动作次数 |
| `state` | `NSInteger` | 过程状态：**1 开始 / 2 暂停 / 3 继续 / 4 结束** |

辅助：`isSuspended` / `isSuspendedEnd` 判断暂停相关状态。

#### 10.3.4 `HwWorkoutGpsPoint`（GPS 轨迹点）

挂在 `HwWorkout.workoutGpsPoints`。头文件：`HwWorkoutGpsPoint.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `time` | `long` | 绝对时间，**毫秒** |
| `offsetTime` | `long` | 相对偏移 |
| `valid` | `bool` | 点是否有效（getter：`isValid`） |
| `longtitude` | `double` | 经度（字段拼写为 `longtitude`） |
| `latitude` | `double` | 纬度 |
| `speed` | `double` | GPS 速度 |
| `accuracy` | `float` | 精度 |
| `altitude` | `double` | 海拔 |
| `suspended` | `bool` | 是否处于暂停段 |
| `turnBack` | `bool` | 折返标记 |

另：`+WorkoutTrack` 提供设备侧轨迹查询模型 `HwGPSTrack` / `HwWKGPSLocation`（经纬度常以 **/1000000** 存整型，另有南/北纬、东/西经标志），用于老 GPS 轨迹协议，详见 `HwBluetoothCenter+WorkoutTrack.h`。

#### 10.3.5 `HwWorkoutRealtimeData`（实时运动数据）

对应 `addWorkoutRealtimeDataUpdateListener:` / `setWorkoutRealtimeData:` / `getWorkoutRealtimeDataWithCallback:`。头文件：`HwWorkoutRealtimeData.h`。

| 属性 | 类型 | 说明 |
|------|------|------|
| `time` | `long` | **毫秒** |
| `state` | `HwWorkoutState` | 实时状态，见下表 |
| `type` | `HwWorkoutType` | 运动类型 |
| `step` | `NSInteger` | 步数 |
| `calories` | `NSInteger` | 卡路里 |
| `distance` | `NSInteger` | 距离，**米** |
| `duration` | `NSInteger` | 时长，**秒** |
| `pace` | `NSInteger` | 配速，**秒/千米** |
| `speed` | `NSInteger` | 速度，单位 **0.01 km/h**（注意与历史记录 `HwWorkout.speed` 的「km/h」量纲可能不同） |
| `lapDuration` | `NSInteger` | 圈时；部分机型无值 |
| `bpm` | `NSInteger` | 心率 |
| `alertBpm` | `NSInteger` | 心率告警阈值值 |
| `bpmAlertOn` | `BOOL` | 是否开启心率告警 |
| `poolLength` | `NSInteger` | 泳池长度 |
| `longtitude` / `latitude` / `gpsSpeed` / `accuracy` / `altitude` | — | GPS 位置与速度等 |
| `suspended` / `turnBack` | `bool` | 暂停 / 折返 |
| `laps` / `actionCount` / `consecutiveActionCount` / `interruptActionCount` | `NSUInteger` | 圈数与动作统计 |
| `actionRate` | `NSUInteger` | 动作频率，**次/分** |
| `actionPosture` / `swolf` | `NSUInteger` | 姿势 / SWOLF |
| `actualDuration1/2/3` | `NSUInteger` | 分段时长 |
| `elevation` / `elevationGain` / `elevationLoss` | `NSInteger` | 海拔与爬升/下降 |
| `strike` | `NSUInteger` | 步幅 |
| `cadence` | `NSUInteger` | 步频 |
| `pressure` | `NSInteger` | 气压 |

`HwWorkoutState`：

| 枚举 | 值 | 含义 |
|------|----|------|
| `HwWorkoutStateNone` | 0x00 | 无 / 空闲 |
| `HwWorkoutStateStarted` | 0x01 | 已开始 |
| `HwWorkoutStateSuspended` | 0x02 | 已暂停 |
| `HwWorkoutStateStopped` | 0x03 | 已结束 |
| `HwWorkoutStateResumed` | 0x04 | 已继续 |
| `HwWorkoutStateDataUpdated` | 0x05 | 数据更新 |

`HwWorkoutAction`（底层控制指令，对应 start/suspend/resume/stop）：

| 枚举 | 值 | 含义 |
|------|----|------|
| `HwWorkoutActionStart` | 0x01 | 开始 |
| `HwWorkoutActionSuspend` | 0x02 | 暂停 |
| `HwWorkoutActionStop` | 0x03 | 结束 |
| `HwWorkoutActionResume` | 0x04 | 继续 |

门面 `startWorkoutWithType:` 等内部会映射到对应 `HwWorkoutAction`。

#### 10.3.6 API ↔ 模型速查

| 场景 | 主要模型 / 枚举 | 典型 API |
|------|-----------------|----------|
| 历史列表 | `HwWorkout` | `getWorkoutsWithCallback:` / `getWorkoutsForLS…` / BigData |
| 过程明细 | `HwWorkoutPoint` | 挂在 `workoutPoints`；或 Center 轨迹点接口 |
| GPS 轨迹 | `HwWorkoutGpsPoint` / `HwGPSTrack` | `workoutGpsPoints`；`+WorkoutTrack` |
| App 控制 | `HwWorkoutType` / `HwWorkoutAction` | `start/suspend/resume/stopWorkout…` |
| 实时联动 | `HwWorkoutRealtimeData` / `HwWorkoutState` | `addWorkoutRealtimeDataUpdateListener:` / `setWorkoutRealtimeData:` |
| 删历史 | — | `deleteWorkoutsWithCallback:` |

---

## 11. 闹钟与提醒

### 11.1 闹钟

```objc
HwAlarm *alarm = [HwAlarm new];
// 时间 / 重复周 / 开关 / 文案等见 HwAlarm.h

[sdk getAvailableAlarmIdWithCallback:^(NSInteger Id, NSError *error) {
    alarm.Id = Id; // 若 API 要求先取可用 ID
    [sdk addAlarm:alarm callback:^(BOOL b, NSError *error) { }];
}];

[sdk getAlarmsWithCallback:^(NSArray<HwAlarm *> *list, NSError *error) { }];
[sdk setAlarms:list callback:^(BOOL b, NSError *error) { }]; // 批量覆盖
[sdk updateAlarm:alarm callback:^(BOOL b, NSError *error) { }];
[sdk deleteAlarmByID:alarmId callback:^(BOOL b, NSError *error) { }];
[sdk deleteAlarmsWithCallback:^(BOOL b, NSError *error) { }];
```

> Android 的 `addAlarm` / `addAlarmV2` 对应 iOS 的 `HwAlarm` / `HwReminder` 能力，按固件协议选择接口。

### 11.2 久坐 / 喝水 / 洗手 / 站立

```objc
HwSedentaryReminder *sedentary = [HwSedentaryReminder new];
[sdk setSedentaryReminder:sedentary callback:^(BOOL b, NSError *error) { }];
[sdk getSedentaryReminderWithCallback:^(HwSedentaryReminder *r, NSError *error) { }];

// LS16 变体
[sdk setSedentaryReminderForLS16:reminder callback:^(BOOL b, NSError *error) { }];

HwDrinkWaterConfig *drink = [HwDrinkWaterConfig new];
[sdk setDrinkWaterConfig:drink callback:^(BOOL b, NSError *error) { }];
[sdk getDrinkWaterConfigWithCallback:^(HwDrinkWaterConfig *c, NSError *error) { }];

HwHandwashingConfig *wash = [HwHandwashingConfig new];
[sdk setHandwashingConfig:wash callback:^(BOOL b, NSError *error) { }];

HwStandingSetting *standing = [HwStandingSetting new];
[sdk setStandingSetting:standing callback:^(BOOL b, NSError *error) { }];
```

喝水记录 CRUD 见 `+DrinkWater` / `HwBluetoothDeviceRequestManager+DrinkWaterRecords`。

### 11.3 一般提醒

```objc
[sdk getAvailableReminderIdWithCallback:^(NSInteger Id, NSError *error) { }];
[sdk addReminder:reminder callback:^(BOOL b, NSError *error) { }];
[sdk updateReminder:reminder callback:^(BOOL b, NSError *error) { }];
[sdk deleteReminderByID:Id callback:^(BOOL b, NSError *error) { }];
[sdk getRemindersWithCallback:^(NSArray<HwReminder *> *list, NSError *error) { }];

// 按类型批量
[sdk setReminderEvents:list type:HwReminderTypeDrinkWater callback:^(BOOL b, NSError *error) { }];
[sdk getAllReminderEvents:type callback:^(NSArray *list, NSError *error) { }];
[sdk delAllReminderEvents:type callback:^(BOOL b, NSError *error) { }];
```

### 11.4 手机日程同步

将手机日历中的日程批量同步到手表。接口为**全量覆盖式同步**：传入的 `events` 即为本次要下发的完整列表（空数组表示清空表端日程，具体表端行为以固件为准）。

```objc
[[HwBluetoothSDK sharedInstance] syncPhoneSchedules:events
                                           callback:^(BOOL b, NSError *error) { }];
```

> SDK 只下发 App 提供的模型，不读取系统日历；仅同步自行组装的数据不需要日历权限。若 App 读取系统日历，iOS 17+ 使用 `NSCalendarsFullAccessUsageDescription` 和 `requestFullAccessToEventsWithCompletion:`；旧版按 `NSCalendarsUsageDescription` 和对应 EventKit 授权接口处理。获得授权后再组装模型。单次最多 **`[HwPhoneScheduleEvent maxCount]` = 30** 条，超出将回调参数错误（`HwBCCodeParamsError`）。

#### `HwPhoneScheduleEvent` 字段说明

头文件：`HwPhoneScheduleEvent.h`

| 属性 | 类型 | 说明 |
|------|------|------|
| `eventId` | `NSInteger` | 日程唯一 ID，由 App 分配；建议与手机日历事件稳定对应，便于覆盖同步 |
| `allDay` | `BOOL` | 是否全天事件；`YES` 时起止时分仍需填（可按固件约定填 0:00 等） |
| `startYear` / `startMonth` / `startDay` | `NSInteger` | 开始日期（公历）；月 1~12，日 1~31 |
| `startHour` / `startMinute` | `NSInteger` | 开始时间；时 0~23，分 0~59 |
| `endYear` / `endMonth` / `endDay` | `NSInteger` | 结束日期 |
| `endHour` / `endMinute` | `NSInteger` | 结束时间 |
| `reminderEnabled` | `BOOL` | 是否开启提醒；通过 `setReminders:` 写入非空列表时会自动置为 `YES`，`clearReminders` 置为 `NO` |
| `title` | `NSString *` | 标题；UTF-8 编码后最长 **60** 字节，超出截断 |
| `notes` | `NSString *` | 备注；UTF-8 编码后最长 **180** 字节，超出截断 |

相关方法：

| 方法 | 说明 |
|------|------|
| `+ maxCount` | 单次同步上限，返回 `30` |
| `- setReminders:` | 设置提醒列表；非空则 `reminderEnabled = YES` |
| `- reminders` | 当前提醒列表的拷贝 |
| `- clearReminders` | 清空提醒并关闭 `reminderEnabled` |

#### 提醒子模型 `HwPhoneScheduleReminder`

头文件：`HwPhoneScheduleReminder.h` / `HwPhoneScheduleReminderUnit.h`

| 属性 | 类型 | 说明 |
|------|------|------|
| `value` | `NSInteger` | 提前提醒的数值（配合 `unit`） |
| `unit` | `HwPhoneScheduleReminderUnit` | 时间单位，见下表 |
| `hour` | `NSInteger` | 定时提醒的小时（0~23）；相对提醒场景可填 0 |
| `minute` | `NSInteger` | 定时提醒的分钟（0~59）；相对提醒场景可填 0 |

`HwPhoneScheduleReminderUnit`：

| 枚举 | 值 | 含义 |
|------|----|------|
| `HwPhoneScheduleReminderUnitMinute` | 0x00 | 分钟 |
| `HwPhoneScheduleReminderUnitHour` | 0x01 | 小时 |
| `HwPhoneScheduleReminderUnitDay` | 0x02 | 天 |
| `HwPhoneScheduleReminderUnitWeek` | 0x03 | 周 |
| `HwPhoneScheduleReminderUnitUnknown` | 0xff | 未知 / 未识别 |

推荐用初始化方法：

```objc
[[HwPhoneScheduleReminder alloc] initWithValue:15
                                          unit:HwPhoneScheduleReminderUnitMinute
                                          hour:0
                                        minute:0];  // 提前 15 分钟
```

一条日程可挂多个提醒；下发时若 `reminderEnabled == YES` 会逐条编码。无提醒时调用 `clearReminders` 或不调用 `setReminders:`（默认关闭）。

#### 组装示例

```objc
HwPhoneScheduleEvent *event = [HwPhoneScheduleEvent new];
event.eventId = 10001;
event.allDay = NO;
event.startYear = 2026; event.startMonth = 7; event.startDay = 15;
event.startHour = 14;   event.startMinute = 30;
event.endYear = 2026;   event.endMonth = 7;   event.endDay = 15;
event.endHour = 15;     event.endMinute = 30;
event.title = @"产品评审";
event.notes = @"会议室 A";

HwPhoneScheduleReminder *r = [[HwPhoneScheduleReminder alloc]
                              initWithValue:15
                                       unit:HwPhoneScheduleReminderUnitMinute
                                       hour:0
                                     minute:0];
[event setReminders:@[r]];

NSArray<HwPhoneScheduleEvent *> *events = @[event];
if (events.count > [HwPhoneScheduleEvent maxCount]) {
    // 全量覆盖接口：按业务选择最多 30 条，不能分页追加；此处先终止。
    return;
}
[[HwBluetoothSDK sharedInstance] syncPhoneSchedules:events
                                           callback:^(BOOL b, NSError *error) {
    if (!b || error) { /* 处理失败 */ return; }
}];
```

#### 实现注意

1. **全量同步**：每次调用按传入列表打包发送（start → 分帧 sync → end）；请传当前需要展示在表端的完整集合。  
2. **数量上限 30**；标题 / 备注按 UTF-8 字节截断（中文约 20 / 60 字量级，视编码而定）。  
3. 起止时间须合法且一般满足结束 ≥ 开始（跨天日程填完整 end 日期）。  
4. 传输过程会按 MTU 自动拆帧，调用方无需关心分包；保持 BLE 连接直至回调成功。  
5. 机型是否支持日程同步，以产品能力 / `getDeviceFeatures` 为准。

---

### 11.5 杰理低电量、震动与自动识别锻炼

Demo 入口：**首页 → 提醒与日常 → 闹钟／提醒（杰理）**。

- 低电量提醒：`getLowBatteryReminderSwitchWithCallback:` / `setLowBatteryReminderSwitch:callback:`。
- 震动：`getVibrationSettingsWithCallback:` / `setVibrationSettings:callback:`；模型 `HwVibrationSettings` 含 `on`（Swift 为 `isOn`）与 `intensity`。弱／中／强分别为 33／66／99；关闭时保留原强度。
- 自动识别锻炼：沿用 hawofit 的 **App 本地提示开关**，不是设备检测开关。用 `addWorkoutTypeRecognitionCallback:` 接收类别，配对 `removeWorkoutTypeRecognitionCallback:` 移除本模块回调。

识别类别：1 步行、2 跑步、3 骑行、4 椭圆机、5 划船机；未知类别忽略。Demo 在首页或闹钟／提醒页显示提示，可忽略、今天不再提示或关闭；本地设置在解绑后清除。该入口不启动运动记录。

---

## 12. 通知 / 通讯录

### 12.1 通知开关

```objc
[sdk getSocialSwitchesWithCallback:^(NSArray<HwSocialSwitch *> *list, NSError *error) { }];
[sdk setSocialSwitchWithType:HwSocialSwitchTypeWechat S:YES callback:^(BOOL b, NSError *error) { }];
[sdk setSocialSwitches:list callback:^(BOOL b, NSError *error) { }];

// 部分机型：下发社交 App 图标包等
[sdk setSocialApps:apps
  progressCallback:^(float f, NSError *error) { }
    finishCallback:^(BOOL b, NSError *error) { }];
[sdk getSocialAppsWithCallback:^(NSArray<HwSocialApp *> *apps, NSError *error) { }];
```

### 12.2 通讯录 / 紧急联系人

```objc
[sdk setContacts:contacts callback:^(BOOL b, NSError *error) { }];
[sdk setContactsV2:contacts callback:^(BOOL b, NSError *error) { }]; // 新协议机型
[sdk getContactsWithCallback:^(NSArray<HwContact *> *contacts, NSError *error) { }];

[sdk setSosName:name phoneNumber:number callback:^(BOOL b, NSError *error) { }];
```

电子名片（二维码卡片）：

```objc
[sdk getQrcodeCardsWithCallback:^(NSArray *cards, NSError *error) { }];
[sdk addQrcodeCard:card callback:^(BOOL b, NSError *error) { }];
[sdk editQrcodeCard:card callback:^(BOOL b, NSError *error) { }];
[sdk delQrcodeCardById:Id callback:^(BOOL b, NSError *error) { }];
```

---

## 13. 表盘

表盘能力分四类：**切换已有表盘**、**安装在线表盘**、**安装自定义表盘**、**监听表端切换**。  
通道按产品芯片/协议区分（与健康数据类似，接入前向厂商确认协议类型）：

| 产品线 | 典型判断 | 在线表盘 | 自定义表盘 | 切换系统/已安装 |
|--------|----------|----------|------------|-----------------|
| **杰理（JL）** | 杰理协议机型 | `MultipleFileTransferTypeOnlineDial` | MFT `CustomDialImage` → `updateJLCustomWatceFace:` | `setSifliDisplayingWatchfaceName:` |
| **思澈（Sifli/QJS）** | 思澈机型 | 额外库 `SifliWatchfaceSDK setOnlineWatchface` | 额外库 `syncZipFile(..., type:5)` | 同上按名称切换 |
| **经典 / WL（瑞昱等）** | 非上述两种 | `getWatchFaceOtaAddressForID` + `HwOtaTypePicture` OTA | `setFreeWidgets` + Picture OTA；或 `otaHR04CustomWatchface:` | `setWatchfaceWithId:` / `setTimeFaceStyleWithModel:` |

通用前置建议：

```text
BLE 已连接且已绑定
  →（思澈）getDeviceUpgradeStatus == None，或旧固件 getBindState != Ota
  → 下载/组包表盘资源
  → 按上表选通道推送
  → ready → progress(0~1) → finish
```

```objc
// 升级态（思澈推送前强烈建议检查，避免与固件 OTA 冲突）
[[HwBluetoothCenter sharedInstance] getDeviceUpgradeStatusWithCallback:^(HwDeviceUpgradeState state, NSError *error) {
    if (error || state != HwDeviceUpgradeStateNone) { /* 设备忙，勿开推送 */ return; }
    // 继续安装
}];
```

### 13.1 查询 / 切换已有表盘

```objc
HwBluetoothSDK *sdk = [HwBluetoothSDK sharedInstance];

// 按 ID（经典主路径）
[sdk getWatchfaceIdWithCallback:^(NSInteger Id, NSError *error) { }];
[sdk setWatchfaceWithId:Id callback:^(BOOL b, NSError *error) { }];
[sdk setCurrentWatchfaceByIndex:index callback:^(BOOL b, NSError *error) { }];

// 按名称（思澈 / 部分杰理「已安装列表」）
[sdk getSifliInstalledWatchfaceNamesWithCallback:^(NSArray *names, NSError *error) { }];
[sdk getSifliDisplayingWatchfaceNameWithCallback:^(NSString *name, NSError *error) { }];
[sdk setSifliDisplayingWatchfaceName:name callback:^(BOOL b, NSError *error) { }];
[sdk delWatchfaceByWatchfaceName:name callback:^(BOOL b, NSError *error) { }];

// 表端用户手动切换时通知 App
[sdk addWatchfaceIdChangedListener:^(NSInteger Id) { }];
[sdk addWatchfaceNameChangedCallback:^(NSString *name) { }];
```

若本地已安装同名在线表盘，只需 `setSifliDisplayingWatchfaceName:` 切换显示，无需再次传输文件。

### 13.2 杰理：在线表盘安装

1. App 侧下载在线表盘 **bin**（服务器包格式以产品为准）。  
2. 组装 `HwMultipleFileTransferModel`，启动方法的 `transferType` 参数传 `MultipleFileTransferTypeOnlineDial`。
3. 调用 `multipleFileTransferService` 的 `startWithFileModels:transferType:readyCallback:progressCallback:finishCallback:`。

```objc
HwMultipleFileTransferModel *model = [HwMultipleFileTransferModel new];
model.fileData = binData;                 // 下载好的表盘二进制
model.fileName = @"WatchfaceName";        // 与设备侧名称约定一致

[[HwBluetoothSDK sharedInstance].multipleFileTransferService startWithFileModels:@[model]
                                                 transferType:MultipleFileTransferTypeOnlineDial
                                                readyCallback:^(BOOL b, NSError *error) {
    // ready：可开始刷进度 UI
} progressCallback:^(float f, NSError *error) {
    // f: 0.0 ~ 1.0
} finishCallback:^(BOOL b, NSError *error) {
    if (!b || error) { /* 显示安装失败 */ return; }
    // 成功后建议本地缓存已安装表盘信息
}];
```

### 13.3 杰理：自定义表盘安装

流程分两段：**先传图片文件，再下发组件配置**。

1. 将背景图（可多张）与缩略图按产品分辨率裁剪。  
2. 像素格式转换（现网常用杰理 `JLBmpConvert`，类型如 `707N_ARGB`；转换工具随杰理交付包，非本 SDK）。  
3. 每张图一个 `HwMultipleFileTransferModel`：  
   - 背景：`fileName = @"bg1"` / `@"bg2"` …  
   - 缩略图：`fileName = @"pw"`  
4. `multipleFileTransferService` 的 `startWithFileModels:… transferType:MultipleFileTransferTypeCustomDialImage`。
5. 传输成功后调用 `updateJLCustomWatceFace:` 写入显示模式、封面下标、组件坐标等。

```objc
#import <HwBluetoothSDK/HwBluetoothCenter+JLWatchFace.h>

// fileModelArr: bg1..bgN + pw
[[HwBluetoothSDK sharedInstance].multipleFileTransferService startWithFileModels:fileModelArr
                                                 transferType:MultipleFileTransferTypeCustomDialImage
                                                readyCallback:^(BOOL b, NSError *error) { }
                                             progressCallback:^(float f, NSError *error) { }
                                               finishCallback:^(BOOL ok, NSError *error) {
    if (!ok || error) { /* 失败 */ return; }

    HwJLWatchFaceConfigModel *config = [HwJLWatchFaceConfigModel new];
    config.displayModeType = HwJLWatchFaceDisplayModeType_SingleImage; // 单图 / 队列 / 随机
    config.coverImageIndex = 0;
    config.imageCount = (int)bgCount;
    config.pointerStyle = 0;
    config.rgbColorStr = @"#FFFFFF";
    config.compentArr = componentList; // HwJLWatchFaceConfigCompentModel：类型 + position

    [[HwBluetoothCenter sharedInstance] updateJLCustomWatceFace:config
                                                       callback:^(BOOL b, NSError *error) { }];
}];
```

`HwJLWatchFaceConfigModel` 字段见 `HwJLWatchFaceConfigModel.h`（显示模式、封面索引、指针风格、文字颜色、组件列表等）。

### 13.4 思澈：在线 / 自定义表盘（额外依赖）

需集成厂商交付的 **`SifliWatchfaceSDK`**（及配套资源/工具库）。设备标识一般用已连接外设的 `UUIDString`：

```objc
NSString *devId = [HwBluetoothSDK sharedInstance].connectedDevice.peripheral.identifier.UUIDString;

// 在线表盘：本地 zip 路径
[[SifliWatchfaceSDK getInstance] setOnlineWatchfaceWithDevIdentifier:devId
                                                            filePath:zipPath
                                                    progressCallback:^(NSInteger p) { /* 0~100 */ }
                                                      finishCallback:^(BOOL b, NSString *errInfo, NSInteger errType, NSNumber *n) {
    [[SifliWatchfaceSDK getInstance] stop];
}];

// 自定义表盘：打包后的 zip；type=5 表示表盘；byteAlign 按产品要求
[[SifliWatchfaceSDK getInstance] syncZipFileWithDevIdentifier:devId
                                                     filePath:zipPath
                                                         type:5
                                                    byteAlign:YES
                                             /* progress/finish 同上 */];
```

API 精确签名以交付的 `SifliWatchfaceSDK` 头文件为准。取消推送调用 `[SifliWatchfaceSDK getInstance] stop`。  
空间不足常见：`errInfo` 含 `:37`；设备忙常见 `errType == 190`。

### 13.5 经典 / WL：在线表盘（Picture OTA）

本 SDK 内完整链路（无需杰理 MFT / 思澈库）：

```objc
HwBluetoothCenter *center = [HwBluetoothCenter sharedInstance];

// 1) 计算 CRC，生成表盘 ID（现网常用 CRC 生成整型 ID）
NSData *crc = [HwBluetoothCenter crcDataFromData:binData total:2];
NSInteger faceId = /* 由 crc 生成，与业务约定一致 */;

// 2) 向设备申请 OTA 写入地址
[center getWatchFaceOtaAddressForID:faceId callback:^(NSData *otaAddress, BOOL needOTA, NSError *error) {
    if (error) { return; }
    // needOTA == NO 时表示设备已有该图，可跳过传输（按产品策略）

    // 3) 组装 OTA 包：地址头 + 图片数据
    NSData *otaData = [HwBluetoothCenter createOnlineWatchFaceDataAddress:otaAddress picData:binData];
    HwOtaDataModel *model = [HwOtaDataModel dataModelWithType:HwOtaTypePicture data:otaData];

    // 4) 启动 OTA（otaDeviceName 一般用当前已连接设备名）
    NSString *otaName = center.connectedDevice.name;
    [center startOtaWithOtaDeviceName:otaName
                        needResumeOta:NO
                            otaModels:@[model]
                        readyCallback:^(BOOL b, NSError *error) { }
                     progressCallback:^(float f, NSError *error) { /* 0~1 */ }
                       finishCallback:^(BOOL b, NSError *error) { }];
}];
```

门面也提供封装接口（内部走同类能力，按产品选用）：

```objc
[[HwBluetoothSDK sharedInstance] otaOnlineWatchface:binData
                                   progressCallback:^(float f) { }
                                     finishCallback:^(BOOL b, NSError *error) { }];
// 或指定 ID：
[[HwBluetoothSDK sharedInstance] otaOnlineWatchfaceWithID:faceId
                                                  binData:binData
                                         progressCallback:^(float f) { }
                                           finishCallback:^(BOOL b, NSError *error) { }];
```

### 13.6 经典：自定义表盘

**普通自定义（控件 + 背景 OTA）：**

```objc
// 1) 可选：先下发自由布局控件
[center setFreeWidgets:widgets forWatchFaceID:faceId callback:^(BOOL b, NSError *error) { }];

// 2) 背景 + 缩略图数据拼包（格式以产品 RGB565 等约定为准）
NSData *picData = /* bg + thumbnail */;
NSData *crc = [HwBluetoothCenter crcDataFromData:picData total:2];

[center getWatchFaceOtaAddressForID:faceId callback:^(NSData *otaAddress, BOOL needOTA, NSError *error) {
    NSData *otaData = [HwBluetoothCenter createWatchFaceOtaDataWithIndex:faceId
                                                                 address:otaAddress
                                                                 picData:picData
                                                                 crcData:crc];
    HwOtaDataModel *model = [HwOtaDataModel dataModelWithType:HwOtaTypePicture data:otaData];
    [center startOtaWithOtaDeviceName:otaName needResumeOta:NO otaModels:@[model]
                        readyCallback:... progressCallback:... finishCallback:...];
}];
```

**HR04 等机型封装：**

```objc
HwCustomWatchface *wf = [HwCustomWatchface new];
// backgroundImage / thumbnailImage / size / widgets ...
[[HwBluetoothSDK sharedInstance] otaHR04CustomWatchface:wf
                                       progressCallback:^(float f) { }
                                         finishCallback:^(BOOL b, NSError *error) { }];
```

另有 `otaCustomWatchface:` / `otaSimpleCustomWatchface:`，适用机型以厂商说明为准。

**系统内置表盘切换（经典）：** 亦可使用 `setTimeFaceStyleWithModel:`（`HwBluetoothCenter`），将样式模型的 `backgroundStyle` 设为表盘 ID。

### 13.7 实现注意

1. **勿与音乐/相册/固件 OTA 并发。**  
2. 推送过程建议亮屏，保持手机靠近手表。  
3. `progressCallback` 中 `float` 为 **0.0~1.0**（思澈库多为 0~100，注意换算）。  
4. 杰理图片必须先转成设备识别的像素格式，再放入 `fileData`。  
5. 思澈取消用 `SifliWatchfaceSDK stop`；杰理多文件传输取消用 `sdk.multipleFileTransferService.stop`；经典 Picture OTA 用 `stopOtaWithCallback:`。确认会话结束后再重试。

---

## 14. 音乐与相册推送

将本地 **音乐文件 / 相册图片** 同步到手表。与「把手机正在播放的曲目信息显示到表端」不是同一能力。

### 14.1 通道选择

| 产品线 | 音乐 | 相册 | 依赖 |
|--------|------|------|------|
| **杰理** | `multipleFileTransferService.startWithFileModels` + `MultipleFileTransferTypeMusic` | 同上 + `MultipleFileTransferTypePhoto` | 仅本 SDK（图片转换可用杰理工具库） |
| **思澈** | `SifliWatchfaceSDK setMusicFiles…` | `SifliWatchfaceSDK setPictures…` | **额外** `SifliWatchfaceSDK` |

```text
BLE 已连接且已绑定
  → 杰理：直接组 HwMultipleFileTransferModel 推送
  → 思澈：先查升级态（见下）→ SifliWatchfaceSDK 推送 → finish 后 stop
```

推送前（尤其思澈）建议检查：

```objc
[[HwBluetoothCenter sharedInstance] getDeviceUpgradeStatusWithCallback:^(HwDeviceUpgradeState state, NSError *error) {
    if (error || state != HwDeviceUpgradeStateNone) { /* 设备忙 */ return; }
    // 开始推送
}];
// 旧固件亦可：getBindState，若为 HwBindStateOta 则禁止推送
```

### 14.2 多文件传输模型（杰理主路径）

头文件：`HwMultipleFileTransferModel.h` / `HwMultipleFileTransferService.h`。

| `MultipleFileTransferType` | 值 | 用途 |
|----------------------------|----|------|
| `Music` | 0x01 | 音乐 |
| `Photo` | 0x02 | 相册 |
| `AIDialPreview` | 0x03 | AI 表盘预览 |
| `OnlineDial` | 0x04 | 在线表盘（见 §13.2） |
| `CustomDialImage` | 0x05 | 自定义表盘图（见 §13.3） |
| `AIDialImage` | 0x06 | AI 表盘图 |

模型字段：

| 属性 | 音乐 | 相册 |
|------|------|------|
| `fileData` | mp3 二进制 | 转换后的图片二进制 |
| `fileName` | 如 `歌曲名.mp3` | 如 `pic1.jpg` |
| `musicType` | `MultipleFileTransferMusicTypeMP3` / `WAV` | — |
| `photoType` | — | `MultipleFileTransferPhotoTypeJPG` / `PNG` |

```objc
[[HwBluetoothSDK sharedInstance].multipleFileTransferService startWithFileModels:models
                                                 transferType:/* Music 或 Photo */
                                                readyCallback:^(BOOL b, NSError *error) { }
                                             progressCallback:^(float f, NSError *error) { /* 0~1 */ }
                                               finishCallback:^(BOOL b, NSError *error) { }];
```

Service 由 `HwBluetoothSDK` 创建并持有，使用前先 `initSDK`，不要自行 `alloc/new`。取消使用 `[[HwBluetoothSDK sharedInstance].multipleFileTransferService stop]`，运行状态可查询 `isRunning`。

亦可使用文件夹便捷接口：`multipleFileTransferService` 的 `startWithFilePath:transferType:readyCallback:progressCallback:finishCallback:`。
调试日志：`multipleFileTransferService.logBlock`。

### 14.3 音乐推送

#### 14.3.1 查询存储空间（推荐）

推送前查询，避免表端空间不足：

```objc
[[HwBluetoothSDK sharedInstance] getMusicAvailableStorageWithCallback:^(NSInteger available, NSInteger total, NSError *error) {
    // 单位：KB（与现网展示一致）
    // used ≈ total - available
}];

[[HwBluetoothSDK sharedInstance] addDeviceMusicStorageChangedListener:^(NSInteger available, NSInteger total) { }];
```

推送成功后建议再调一次刷新 UI。部分产品型号可能不支持该查询。

#### 14.3.2 杰理：音乐文件传输

```objc
NSMutableArray<HwMultipleFileTransferModel *> *arr = [NSMutableArray new];
for (/* 每首选中的曲目 */) {
    HwMultipleFileTransferModel *m = [HwMultipleFileTransferModel new];
    m.fileName = [NSString stringWithFormat:@"%@.mp3", title];
    m.fileData = [NSData dataWithContentsOfFile:mp3Path];
    m.musicType = MultipleFileTransferMusicTypeMP3;
    [arr addObject:m];
}

[[HwBluetoothSDK sharedInstance].multipleFileTransferService startWithFileModels:arr
                                                 transferType:MultipleFileTransferTypeMusic
                                                readyCallback:^(BOOL b, NSError *error) { }
                                             progressCallback:^(float f, NSError *error) {
    // 更新进度条 f
} finishCallback:^(BOOL b, NSError *error) {
    if (b && !error) {
        [[HwBluetoothSDK sharedInstance] getMusicAvailableStorageWithCallback:...];
    }
}];
```

建议传输前校验文件确为合法 mp3（损坏文件表端可能无法识别）。

#### 14.3.3 思澈：音乐文件传输（额外依赖）

```objc
NSString *devId = [HwBluetoothSDK sharedInstance].connectedDevice.peripheral.identifier.UUIDString;
NSURL *folderURL = [NSURL fileURLWithPath:selectedMp3Directory]; // 待推送 mp3 所在目录

[[SifliWatchfaceSDK getInstance] setMusicFilesWithDevIdentifier:devId
                                                  musicFilePath:folderURL
                                               compressCallback:^(BOOL ok) { /* 压缩完成后再刷进度 */ }
                                              progressCallback:^(NSInteger p) { /* 0~100 */ }
                                                finishCallback:^(BOOL b, NSString *errInfo, NSInteger errType, NSNumber *n) {
    [[SifliWatchfaceSDK getInstance] stop];
    // :37 → 空间不足；errType 190 → 设备忙；4/1/:38/:6 → 断连/超时
}];
```

取消：`[[SifliWatchfaceSDK getInstance] stop]`。

### 14.4 相册推送

#### 14.4.1 列表 / 删除（两端通用）

```objc
HwBluetoothSDK *sdk = [HwBluetoothSDK sharedInstance];

// 查询表端已有相册文件 ID（推送前可用来生成不冲突文件名）
[sdk getAlbumFilesIdListWithCallback:^(NSArray *ids, NSError *error) { }];
[sdk getAlbumFilesCountWithCallback:^(NSInteger n, NSError *error) { }];

// 删除
[sdk delAlbumFiles:idList callback:^(BOOL b, NSError *error) { }];
[sdk delAllAlbumFilesWithCallback:^(BOOL b, NSError *error) { }];
```

App 侧选图时建议：按产品分辨率裁剪 → 控制张数上限（现网常见 ≤ 50）→ 文件名与表端 ID 不冲突。

#### 14.4.2 杰理：相册传输

```objc
NSMutableArray<HwMultipleFileTransferModel *> *fileModelArr = [NSMutableArray new];
[images enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
    // 1) 裁剪到产品分辨率
    // 2) JPEG → JLBmpConvert（如 707N_ARGB）得到 outFileData
    HwMultipleFileTransferModel *m = [HwMultipleFileTransferModel new];
    m.photoType = MultipleFileTransferPhotoTypeJPG;
    m.fileData = convertedData;
    m.fileName = [NSString stringWithFormat:@"pic%lu.jpg", (unsigned long)(idx + 1)];
    [fileModelArr addObject:m];
}];

[[HwBluetoothSDK sharedInstance].multipleFileTransferService startWithFileModels:fileModelArr
                                                 transferType:MultipleFileTransferTypePhoto
                                                readyCallback:^(BOOL b, NSError *error) { }
                                             progressCallback:^(float f, NSError *error) { }
                                               finishCallback:^(BOOL b, NSError *error) { }];
```

#### 14.4.3 思澈：相册传输（额外依赖）

```objc
NSString *devId = [HwBluetoothSDK sharedInstance].connectedDevice.peripheral.identifier.UUIDString;
// QjsAlbumModel：name + image（类型名以 SifliWatchfaceSDK 为准）
[SifliWatchfaceSDK getInstance].width = productWidth;
[SifliWatchfaceSDK getInstance].height = productHeight;

[[SifliWatchfaceSDK getInstance] setPicturesWithDevIdentifier:devId
                                     compressSuccessCallback:^(BOOL ok) { }
                                                      albums:albumModels
                                            progressCallback:^(NSInteger p) { /* 0~100 */ }
                                              finishCallback:^(BOOL b, NSString *errInfo, NSInteger errType, NSNumber *n) {
    [[SifliWatchfaceSDK getInstance] stop];
}];
```

### 14.5 实现注意

1. **推送前**建议：已连接、未在固件 OTA、未与表盘/其它大文件传输并发。  
2. **音乐**推送前查 `getMusicAvailableStorage`；相册空间不足多在回调错误里体现（思澈 `:37`）。  
3. 杰理进度 `float` 为 **0~1**；思澈进度多为 **0~100**。  
4. 思澈结束或取消务必 `stop`，避免会话残留。  
5. 按实际访问方式配置权限：直接读取相册才申请相册权限；文件选择器导入 MP3 不需要相册或 Apple Music 权限。使用文件副本时读取沙盒内文件；外部 security-scoped URL 则成对调用 `startAccessingSecurityScopedResource` / `stopAccessingSecurityScopedResource`。
6. 其它存储查询（按产品）：`getOfflineMapAvailableStorageWithCallback:`、`getCoustomInterfaceAvailableStorageWithCallback:`。

---


## 15. 天气

```objc
HwWeatherInfo *today = ...;
NSArray<HwWeatherInfo *> *forecast = ...;

[sdk setWeatherInfoWithCity:@"深圳"
                weatherInfo:today
                   forecast:forecast
                   callback:^(BOOL b, NSError *error) { }];

[sdk setWeatherUnit:HwWeatherUnitC callback:^(BOOL b, NSError *error) { }];
[sdk getWeatherUnitWithCallback:^(HwWeatherUnit unit, NSError *error) { }];

[sdk addCurrentWeatherUnitChangedCallback:^(HwWeatherUnit unit) { }];
```

手表主动索要天气时，通过设备事件 listener（§20）回填。

---

## 16. 查找设备 / 遥控拍照

```objc
// App 找手表
[sdk findDeviceWithCallback:^(BOOL b, NSError *error) { }];

// 手表找手机
[sdk addFindMyPhoneCallback:^{
    // App 响铃/震动后：
    [sdk acceptedFindMyPhoneRequest];
}];

// 遥控拍照
[sdk enterCameraWithCallback:^(BOOL b, NSError *error) { }];
[sdk exitCameraWithCallback:^(BOOL b, NSError *error) { }];
[sdk addCameraEventCallback:^(HwCameraEvent event) { }];
[sdk addCameraDelayEventCallback:^(HwCameraEvent event, NSInteger delay, NSInteger photoNum) { }];
```

---

## 17. OTA 固件升级

> SDK / 三方 DFU **只负责把已准备好的固件写入设备**。固件列表拉取、下载、MD5、版本比较、UI 与互斥业务均由 App 完成。

### 17.1 推荐总体流程

```text
① 预检：已绑定 + BLE 已连接 + 蓝牙授权
② 电量 ≥ 30%（App 调 getBattery；建议保持亮屏、靠近手表）
③ 业务互斥：勿与 AGPS / 表盘推送 / 音乐相册传输 / 思澈表盘 SDK 工作中并发
④ 向服务器查询可升级固件列表 → 下载到本地（进度与传输进度分开展示）
⑤ 按产品线选通道启动 OTA（见 §17.2）
⑥ ready → progress(0~1) → finish
⑦ 成功：提示「手表将重启」→ 延时 → 重连 → getDeviceInfo 校验版本
```

预检示例：

```objc
HwBluetoothSDK *sdk = [HwBluetoothSDK sharedInstance];

if (!sdk.connected) { /* 引导连接 */ return; }

[sdk getBatteryWithCallback:^(NSInteger battery, NSError *error) {
    if (error || battery < 30) { /* 电量不足 */ return; }
    // 开始下载 / 组装 / 选通道 OTA
}];
```

辅助 API（按产品选用）：

```objc
// 升级态（部分产品；思澈表盘/音乐路径常用；固件流程可按需增加）
[sdk getDeviceUpgradeStatusWithCallback:^(HwDeviceUpgradeState state, NSError *error) { }];

// 思澈：绑定态为 OTA（如 0x81）表示设备处于升级中断态，适合「续升」而不是新开业务
[sdk getBindStateWithCallback:^(HwBindState bindState, NSError *error) {
    // bindState == HwBindStateOta → 引导继续 OTA
}];

// 强制退出设备 OTA 模式（异常恢复时可调用）
[[HwBluetoothCenter sharedInstance] forceOutOTADeviceWithCallback:^(BOOL b, NSError *error) { }];

// 通用 OTA 状态 / 停止（经典通道）
[[HwBluetoothCenter sharedInstance] getOtaStatusWithCallback:^(NSUInteger allSize, NSData *crcData, NSUInteger recvSize, NSError *error) { }];
[[HwBluetoothCenter sharedInstance] stopOtaWithCallback:^(BOOL b, NSError *error) { }];
```

### 17.2 通道选择（按产品配置）

```text
固件文件已下载、校验完整，且已按产品配置确认芯片方案
        │
        ├─ 思澈产品（MCU = sifli）──────────► 方案 D：SifliOTAManagerSDK.startOTANand
        │
        ├─ 厂商确认的杰理机型
        │   （不可仅凭 protocolVersion ≥ 100）───► 方案 B：otaV2Service.startWithBinData
        │
        └─ 其它（瑞昱 / 阿波罗等）──────────► 方案 A：otaWithDataModels
```

| 方案 | API | 是否在 HwBluetoothSDK 内 | 数据包形态 |
|------|-----|--------------------------|------------|
| **A. 通用 OTA** | `otaWithDataModels:` / 门面同名接口 | **是** | 每个文件一份 `HwOtaDataModel`；bin **前 4 字节为写入地址** |
| **B. 杰理 JL OTA V2** | `otaV2Service.startWithBinData:readyCallback:progressCallback:finishCallback:` | **是** | 多文件 **按序拼接成一个** `NSData` |
| **C. 文件差分 fdOta** | `fdOtaStartWithFileData:` | **是**（备选） | 同样拼接成一个 `NSData`；按产品启用 |
| **D. 思澈 DFU** | `SFOTAManager startOTANand:…` | **否，额外 SDK** | 主包 ZIP 解压后按文件名前缀映射镜像 |

> **勿与表盘 / 音乐 / 相册大文件传输并发。** 杰理 OTA 过程中建议暂停其它蓝牙业务指令。

### 17.3 方案 A：通用 OTA（`HwOtaDataModel`）

适用于 **瑞昱（Realtek）/ 阿波罗** 等与经典 OTA 同路径的产品。

#### 17.3.1 固件包格式

服务器下发的每个 bin 建议已包含：

```text
[0..3]  写入地址（4 字节）
[4..]   固件本体
```

使用工厂方法组装时，SDK 会自动剥离前 4 字节为地址、剩余为 payload，并计算 CRC、按约 **2048** 字节分区发送：

```objc
HwOtaDataModel *model = [HwOtaDataModel dataModelWithType:HwOtaTypePlatform data:fileData];
// model.otaAddressData = 前 4 字节
// model.otaData        = 第 5 字节起
```

`HwOtaType`（见 `HwBluetoothCenter+Ota.h`）：

| 枚举 | 说明 |
|------|------|
| `HwOtaTypePlatform` | 主固件 |
| `HwOtaTypeTP` | 触控 |
| `HwOtaTypeHeart` | 心率 |
| `HwOtaTypePicture` | 图片资源（亦用于经典表盘，见 §13） |
| `HwOtaTypeAGPS` | AGPS |
| `HwOtaTypeWatchFace` | 表盘 |
| `HwOtaTypeWatchPatch` (0x0A) | 瑞昱 Patch |
| `HwOtaTypeWatchFsbl` (0x0B) | 瑞昱 FSBL |

一包升级可包含多个 `HwOtaDataModel`（按服务器下发的 type 列表组装）。

#### 17.3.2 启动传输

门面（现网常用，`needResumeOta` 默认走 NO）：

```objc
NSString *otaDeviceName = sdk.connectedDevice.name; // 产品约定的 OTA 广播名；多数等于当前连接名

[sdk otaWithDataModels:otaModels
         otaDeviceName:otaDeviceName
         readyCallback:^(BOOL ready, NSError *error) {
             // ready == NO 或 error != nil：设备拒绝进入 OTA / 异常
             // 注意：此时通常不会再回调 finishCallback
         }
      progressCallback:^(float f, NSError *error) {
             // f: 0.0 ~ 1.0 → UI 可用 (int)(f * 100)
         }
        finishCallback:^(BOOL b, NSError *error) {
             // 成功后设备将重启，建议延时数秒再提示用户 / 重连
        }];
```

等价底层接口（可显式控制断点续传、是否由 SDK 判电量）：

```objc
[[HwBluetoothCenter sharedInstance] otaWithDataModels:otaModels
                                        otaDeviceName:otaDeviceName
                                        needResumeOta:NO
                                     needJudgeBattery:NO   // 电量已在 App 预检时，可关
                                        readyCallback:...
                                     progressCallback:...
                                       finishCallback:...];
```

带 SDK 内电量门槛的重载：

```objc
[sdk otaWithDataModels:otaModels
          batteryLimit:30
         readyCallback:...
      progressCallback:...
        finishCallback:...];
```

不经「询问能否 OTA」、直接进入传输（高级用法）：

```objc
[[HwBluetoothCenter sharedInstance] startOtaWithOtaDeviceName:otaName
                                                needResumeOta:NO
                                                    otaModels:otaModels
                                                readyCallback:...
                                             progressCallback:...
                                               finishCallback:...];
```

停止经典 OTA：

```objc
[[HwBluetoothCenter sharedInstance] stopOtaWithCallback:^(BOOL b, NSError *error) { }];
```

### 17.4 方案 B：杰理 JL OTA V2（生产主路径）

适用于厂商确认的 **杰理协议** 机型。协议号 `>= 100` 只是 Demo 的兜底判断，客户应以机型与 MCU 配置选择通道。

#### 17.4.1 组装数据

将服务器下发的所有固件文件 **按列表顺序拼接** 成单一 `NSData`（不拆 `HwOtaDataModel`、不剥离地址头）：

```objc
NSMutableData *binData = [NSMutableData data];
for (NSString *path in localFirmwarePaths) {
    NSData *part = [NSData dataWithContentsOfFile:path];
    if (!part.length) { NSLog(@"固件文件读取失败：%@", path); return; }
    [binData appendData:part];
}
```

#### 17.4.2 启动 / 停止

```objc
HwOtaV2Service *service = [HwBluetoothSDK sharedInstance].otaV2Service;
if (!service) { /* SDK 未就绪：提示错误，不进入升级 */ return; }
service.logLevel = HwOtaLogLevelDebug; // 可选

[service startWithBinData:binData
           readyCallback:^(BOOL ready, NSError *error) {
               if (!ready || error) { /* 启动失败 */ }
           }
        progressCallback:^(float progress, NSError *error) {
               // progress: 0.0 ~ 1.0
           }
          finishCallback:^(BOOL success, NSError *error) {
               if (!success || error) { /* 显示失败 */ return; }
               // 等待设备重启，再重连并核对版本。
           }];

// 用户取消或离开升级流程时调用；勿紧接启动后立即执行。
// [service stop];
```

OTA 进行中请避免对其它模块发指令；取消调用 `service.stop`，确认结束后再重试。Service 由 SDK 持有，不要自行创建。

### 17.5 方案 C：文件差分 fdOta（备选通道）

本 SDK 提供 `+FileDifferenceOta`。部分产品或测试场景使用；**是否作为某机型默认通道以厂商交付说明为准**（现网杰理主路径优先走 §17.4）。

```objc
HwBluetoothCenter *center = [HwBluetoothCenter sharedInstance];

[center setFdOtaLogBlock:^(NSString *logMessage) {
    // 可选：落盘 / 上报
}];
// [center setUseFixedErrorCrc:YES]; // 仅调试用途，生产勿随意打开

NSMutableData *fileData = /* 同 JL：多文件按序拼接 */;
[center fdOtaStartWithFileData:fileData
                 readyCallback:^(BOOL b, NSError *error) { }
              progressCallback:^(float f, NSError *error) { /* 0~1 */ }
                finishCallback:^(BOOL b, NSError *error) { }];
```

文件过短（例如总长度不足协议头）会被 SDK 直接拒绝，请保证固件包完整。

### 17.6 方案 D：思澈 Sifli DFU（额外依赖）

需集成厂商交付的 **`SifliOTAManagerSDK`**（类名以交付包为准，现网为 `SFOTAManager` / `SFOTALogManager`）。  
**仅思澈 MCU 产品需要**；瑞昱 / 杰理不必集成。

#### 17.6.1 包结构与解压

1. 服务器下发主固件一般为 **ZIP**（platform 类型），可选另附 picture/resource 包。  
2. App 解压 ZIP，按文件名前缀映射镜像：

| 文件名前缀 | 含义（镜像 ID） |
|------------|-----------------|
| `hcpu*.bin` | HCPU |
| `lcpu*.bin` | LCPU |
| `patch_lcpu*.bin`（或产品约定的 patch） | LCPU_PATCH |
| `diff_ctrl*.bin` | 差分控制（优先于全量 ctrl） |
| `ctrl*.bin` | 全量控制 |
| `outdyn*.bin` | DYN（常见于全量模式追加） |
| `outroot*.bin` | RES（常见于全量模式追加） |

组装规则（与现网一致）：

- 存在 `diff_ctrl*` → **差分模式**：控制文件用 `diff_ctrl`；镜像列表含已扫到的 hcpu/lcpu/patch 等。  
- 否则用 `ctrl*` → **全量模式**，并可追加 `outdyn` / `outroot`。

#### 17.6.2 启动 DFU

```objc
NSString *devId = [HwBluetoothSDK sharedInstance].connectedDevice.peripheral.identifier.UUIDString;

// 伪代码：类型名以 SifliOTAManagerSDK 头文件为准
SFOTAManager *manager = [SFOTAManager share];
manager.delegate = self; // 实现进度 / 完成 / 错误回调

[manager startOTANandWithTargetDeviceIdentifier:devId
                                   resourcePath:pictureOrResourceURL  // 无资源包时传 nil，不要传空 file:// URL
                            controlImageFilePath:ctrlOrDiffCtrlURL
                                  imageFileInfos:nandImageInfoArray
                                       tryResume:YES];   // 支持中断后续传

// 离开页面或取消：
[manager stop];
```

思澈设备若 `getBindState == HwBindStateOta`，表示上次升级未完成，应引导用户 **继续 OTA**（`tryResume:YES`），避免并发其它大业务。

### 17.7 进度与 UI 建议

| 阶段 | 建议 |
|------|------|
| HTTP 下载固件 | App 自建 0~100% 进度，与传输进度分开展示 |
| SDK / DFU 传输 | 通用 / JL / fdOta：`float` **0.0~1.0**；思澈多为字节完成度，自行换算 |
| 进行中 | 保持亮屏；禁用返回或二次确认；提示勿远离手表 |
| 互斥 | 禁止同时推音乐/相册/表盘；杰理期间暂停其它写指令 |
| 成功 | 提示设备重启；经典路径可延时约数秒～十余秒再重连；然后 `getDeviceInfo` / `getFirmwareVersion` 校验 |
| 失败 | 展示错误文案，提供重试；思澈调用 `stop`；杰理确认 `otaV2Service.stop`；必要时 `forceOutOTADevice` |

相关错误码：`HwBCCodeOtaError`(90)、`HwBCCodePowerLowError`(80)、`HwBCCodeBLEDisconnected`(13)、`HwBCCodeBLEUnavailable`(9) 等。思澈错误含通话中（如文案 `:65`）、设备忙等，以三方 SDK 说明为准。

### 17.8 完整分发示例（骨架）

```objc
- (void)startFirmwareUpgradeWithLocalFiles:(NSArray<NSDictionary *> *)files
                               isSifli:(BOOL)isSifli
                            isJLProtocol:(BOOL)isJL {
    if (!files.count) { /* 固件列表为空 */ return; }
    // files: @[ @{ @"type": @(HwOtaTypePlatform), @"path": @"..." }, ... ]

    if (isSifli) {
        // §17.6 解压 ZIP → SFOTAManager startOTANand
        return;
    }
    if (isJL) {
        NSMutableData *bin = [NSMutableData data];
        for (NSDictionary *f in files) {
            NSData *part = [NSData dataWithContentsOfFile:f[@"path"]];
            if (!part.length) { /* 固件文件缺失或为空：终止 */ return; }
            [bin appendData:part];
        }
        HwOtaV2Service *service = [HwBluetoothSDK sharedInstance].otaV2Service;
        if (!service || !bin.length) { /* 未就绪或固件为空 */ return; }
        [service startWithBinData:bin
                   readyCallback:...
                progressCallback:...
                  finishCallback:...];
        return;
    }

    // 经典 / 瑞昱 / 阿波罗
    NSMutableArray *models = [NSMutableArray new];
    for (NSDictionary *f in files) {
        NSData *data = [NSData dataWithContentsOfFile:f[@"path"]];
        if (data.length <= 4) { /* 地址头或固件本体不完整 */ return; }
        HwOtaType type = [f[@"type"] integerValue];
        [models addObject:[HwOtaDataModel dataModelWithType:type data:data]];
    }
    NSString *name = [HwBluetoothSDK sharedInstance].connectedDevice.name;
    [[HwBluetoothSDK sharedInstance] otaWithDataModels:models
                                         otaDeviceName:name
                                         readyCallback:...
                                      progressCallback:...
                                        finishCallback:...];
}
```

### 17.9 依赖与头文件汇总

| 内容 | 路径 / 依赖 |
|------|-------------|
| 门面 OTA | `HwBluetoothSDK` → `otaWithDataModels:otaDeviceName:…` / `batteryLimit:` |
| 经典 OTA 核心 | `HwBluetoothCenter+Ota.h` → `HwOtaDataModel` / `HwOtaType` / `startOta…` / `stopOta…` |
| 杰理 OTA V2 | `HwOtaV2Service.h` |
| 差分 OTA | `HwBluetoothCenter+FileDifferenceOta.h` |
| 退出 OTA 模式 | `forceOutOTADeviceWithCallback:` |
| 思澈固件 DFU | **额外** `SifliOTAManagerSDK`（`SFOTAManager`） |

---


## 18. GPS / 地图

```objc
[sdk getDeviceGpsStatusWithCallback:^(HwGpsStatus *status, NSError *error) { }];

[sdk setCurrentGpsLocationWithLatitude:lat
                             longitude:lng
                             timestamp:ts
                              callback:^(BOOL b, NSError *error) { }];

[sdk setDeviceMapAuthCode:authCode uuid:uuid callback:^(BOOL b, NSError *error) { }];
[sdk setDeviceMapTheme:HwMapThemeLight callback:^(BOOL b, NSError *error) { }];
[sdk setDeviceMapCenterWithLongitude:lng latitude:lat callback:^(BOOL b, NSError *error) { }];
[sdk setDeviceMapRangeWithLongitude:... /* 见头文件 */ callback:^(BOOL b, NSError *error) { }];

[sdk addDeviceAgpsShouldUpdateListener:^(long start, long end) {
    // 触发 AGPS 数据下发（见 +WorkoutTrack sendAGPSData...）
}];
[sdk addDeviceRequestGpsLocationListener:^{
    // 立即 setCurrentGpsLocation...
}];
```

---

## 19. 其他常用设置

```objc
// 亮度 / 亮屏时长
[sdk setBrightnessValue:80 callback:^(BOOL b, NSError *error) { }]; // 0~100（部分机型 get 为 1~5 档）
[sdk getBrightnessValueWithCallback:^(NSInteger n, NSError *error) { }];
[sdk setScreenOnDuration:15 callback:^(BOOL b, NSError *error) { }]; // 秒
[sdk getScreenOnDurationWithCallback:^(NSInteger n, NSError *error) { }];

[sdk setAODEnable:YES callback:^(BOOL b, NSError *error) { }];
[sdk setLiftWristAwakenEnable:YES callback:^(BOOL b, NSError *error) { }];

[sdk setDevicePasscode:@"1234" on:YES callback:^(BOOL b, NSError *error) { }];
[sdk delDevicePasscodeWithCallback:^(BOOL b, NSError *error) { }];
[sdk getDevicePasscodeWithCallback:^(NSString *str, NSError *error) { }];

[sdk restartDeviceWithCallback:^(BOOL b, NSError *error) { }];
[sdk resetDeviceWithCallback:^(BOOL b, NSError *error) { }];
[sdk deleteDeviceDataWithCallback:^(BOOL b, NSError *error) { }];

[sdk setAppState:HwAppStateForeground callback:^(BOOL b, NSError *error) { }];

[sdk getFeatureSwitchesWithCallback:^(NSArray<HwFeatureSwitch *> *list, NSError *error) { }];
[sdk setFeatureSwitchWithType:type S:YES callback:^(BOOL b, NSError *error) { }];

// 世界时钟
[sdk setWorldClockCities:cities callback:^(BOOL b, NSError *error) { }];
[sdk addWorldClockCity:city callback:^(BOOL b, NSError *error) { }];
[sdk delWorldClockCityById:Id callback:^(BOOL b, NSError *error) { }];

// 生理期
[sdk setPhysiologicalPeriodSetting:setting callback:^(BOOL b, NSError *error) { }];

// 佩戴习惯
[sdk setUserHandHabit:HwHandHabitLeft callback:^(BOOL b, NSError *error) { }];

// 弹幕等
[sdk setDeviceBullets:bullets on:YES callback:^(BOOL b, NSError *error) { }];
```

AI / 穆斯林朝拜等扩展见 `HwBluetoothSDK.h` 中 `#pragma mark - AI` / `#pragma mark - 穆斯林朝拜`，接入前确认固件支持。

---

## 20. 全局监听器

建议在启动后注册，在 `destroySDK` 前成对 `remove*`。常用：

| API | 用途 |
|-----|------|
| `addBluetoothStateChangedCallback` | 手机蓝牙开关/授权 |
| `addBluetoothConnectionStateChangedCallback` | BLE 连接态 |
| `addBatteryStateChangedListener` | 电量 / 充电 |
| `addDeviceEventCallback` | 设备主动事件（天气/活动等） |
| `addFindMyPhoneCallback` | 找手机 |
| `addCameraEventCallback` | 遥控拍照 |
| `addWorkoutRealtimeDataUpdateListener` | 运动实时 |
| `addWorkoutStateUpdatedCallback` | 运动状态 |
| `addGoalUpdatedListener` / `addGoalsUpdatedListener` | 目标变更 |
| `addHealthDataUpdatedListener` | 健康数据变更 |
| `addWatchfaceIdChangedListener` / `addWatchfaceNameChangedCallback` | 表盘切换 |
| `addDeviceAgpsShouldUpdateListener` | AGPS |
| `addDeviceRequestGpsLocationListener` | 表端要定位 |
| `addBtConnectionStateCallback` | 经典 BT 连接异常提示 |
| `addDevicePairStateCallback` | 配对完成 |

也可监听 `NSNotification`（如 `HwBluetoothConnectedNotification`、`HwBluetoothConnectionStateChangedNotification`），见 `HwBluetoothCenter` 头文件。

---

## 21. 协议分支说明

不同芯片/协议线 API 与命名不同，请按 `HwDeviceInfo.protocolVersion`、`getDeviceFeatures` 或厂商产品说明选择：

| 判断 / 命名 | 说明 |
|-------------|------|
| `protocolVersion` 较大 / 产品标注 WL | 健康多用 BigData 或新协议路径；闹钟/提醒可能走新接口 |
| `ForLS` / `ForLS16` / `startLS16Bind` | LS 系列 |
| `Sifli` / 表盘按名称 | 思澈芯片绑定与表盘名管理 |
| `otaV2Service` / `JLWatchFace` | 杰理 OTA V2 / 自定义表盘配置 |
| `otaWithDataModels` / `HwOtaType*` | 瑞昱 / 阿波罗通用固件 OTA（bin 前 4 字节地址） |
| `otaV2Service` | 杰理固件 OTA V2（多文件拼接） |
| `fdOta*` | 文件差分固件 OTA（备选） |
| 思澈 `SFOTAManager` | 思澈固件 DFU（额外 SDK；ZIP 解压后按前缀映射） |
| `HwMultipleFileTransferService` | 杰理：音乐 / 相册 / 在线·自定义表盘资源 |
| 无后缀常规 API | 通用主路径 |

不确定时以厂商产品对接文档为准。

---

## 22. 推荐集成流程

```text
1. didFinishLaunching → initSDK
2. 注册全局 Listener（连接态、找手机、设备事件等）
3. 首次绑定：蓝牙授权 → scan → connect →（按需系统配对）→ startBind*
4. 绑定成功：setDeviceTime / setUserInfo / setUnit / setLanguage / setGoal → endBind
5. 绑定结束成功后保存 MAC / UUID 等设备标识；按需调用 updateMacAddressIfNeedWithMac
6. 日常：connectWithMac → getDeviceInfo → 读取数据 → 可靠保存成功后再按需 delete*
7. 通知开关、天气、表盘、音乐、OTA 按业务调用
8. 解绑：关闭自动重连 → unbindDevice → disconnect → removeConnectionCache → 清除 App 绑定记录 → 提示系统“忽略此设备”
9. 进程退出：remove Listener → destroySDK
```

### 绑定成功后环境同步示例

```objc
- (void)syncEnvironmentAndEndBind {
    HwBluetoothSDK *sdk = [HwBluetoothSDK sharedInstance];
    [sdk setDeviceTime:[NSDate date] is24H:YES callback:^(BOOL b, NSError *error) {
        if (!b || error) return;
        [sdk setUserInfo:[self buildUserInfo] callback:^(BOOL b, NSError *error) {
            if (!b || error) return;
            [sdk setUnit:HwUnitMetric callback:^(BOOL b, NSError *error) {
                if (!b || error) return;
                [sdk setLanguage:HwLanguageChineseSimplified callback:^(BOOL b, NSError *error) {
                    if (!b || error) return;
                    [sdk endBindDeviceWithCallback:^(BOOL b, NSError *error) {
                        if (b && !error) {
                            // 保存绑定记录，进入主页；按业务需要开始同步。
                        }
                    }];
                }];
            }];
        }];
    }];
}
```

---

## 23. AiSDK 与 App 主动分析

### 23.1 依赖与入口

蓝牙 SDK 与 AiSDK 是不同模块。本节对应当前 Demo 的 AiSDK 1.3.4 Git 交付；相同版本号可能对应不同提交，复现时以 `Podfile.lock` 中的 commit 和 checksum 为准。

沿用仓库 `Podfile`，执行 `pod install` 并打开 `BleSdkDemo.xcworkspace`。当前 AiSDK 的 podspec 已包含 `NativeLib.xcframework` 和 `Vendor/OAS/*.xcframework`，**不需宿主再声明 OAS Pod 或添加寒霜 Specs 源**。旧提交若报 `OAS (= 2.5.0)` 找不到，应先核对是否已更新到自带二进制的交付。应用提供 `JLBmpConvertKit`，并在 SDK 初始化时注入转换器，见 `BleRepository.initSDK()`。

Demo 分为两条流程：

- **首页 → 表盘、媒体与 AI → AI → AI DEMO**：手表触发语音、问答、表盘等；注册 `AiSDKCallback`，通过 `startWorking()` 开始监听。
- **首页 → 表盘、媒体与 AI → AI → AI 分析下六个入口**：App 点击生成报告。当前仅输入健康数据为 mock，返回内容来自真实云端，不是本地伪造报告。实现见 `AiAnalysisViewController` / `AiAnalysisMock`。

### 23.2 渠道与设备初始化

需要真实且具备 AI 授权的设备 ID；mock 健康数据不等于可以使用 mock 设备 ID。Demo 先检查 BLE 连接，再通过 `BleRepository.getDeviceInfo` 取得 ID，不能只用设备名或 MAC 替代。

AI 洞察、身体状态、睡眠报告走 OAS。渠道参数需在 `setDeviceInfo` **之前**配置：

```swift
import AiSDK

AiOASClient.shared.configure(
    channelId: channelID,
    appKey: appKey,
    appUuid: nil,
    appChannel: nil
)
let ai = AiSDK.sharedInstance()
let info = AiDeviceInfo()
info.setValue(deviceId, forKey: "Id")
info.mac = deviceMac
info.name = deviceName
info.type = productType
info.width = 480
info.height = 480
info.cornerRadius = 240
info.thumbnailWidth = 264
info.thumbnailHeight = 264
info.thumbnailCornerRadius = 132
info.currentLocale = "zh"
info.supportedLocales = ["zh", "en"]
info.platformType = .jieLi // 此例为杰理；思澈用 .sifli，瑞昱用 .realtek
info.healthAnalysisAppOnly = true
ai.setDeviceInfo(info)
```

示例屏幕尺寸沿用 Demo 默认值；集成时填写真实产品参数，亦可复用 `AiDeviceInfoBuilder`。当前 `AiDeviceInfo` 暴露 `platformType`；平台应按产品配置确定；Demo 的 `AiPlatformHelper` 仅提供协议号和手动开关的兜底判断，不能替代客户机型配置。`setDeviceInfo` 触发 SDK 初始化，网络、授权和渠道错误必须显示给用户。

Demo 的 Channel ID / App Key 默认沿用 hawofit，**明文显示、允许编辑**；环境变量 `AI_OAS_CHANNEL_ID` / `AI_OAS_APP_KEY` 可覆盖默认值。编辑仅对当前页面有效，不写 UserDefaults。文档示例不包含真实密钥。

### 23.3 六项分析接口

桥接头需包含：

```objc
#import <AiSDK/AiSDK.h>
#import <AiSDK/AiSDK+HealthAgents.h>
#import <AiSDK/DefaultHealthAnalysisResultHandler.h>
```

| Demo 功能 | 输入与调用 | 返回 |
| --- | --- | --- |
| 运动健康分析 | `HwHealthData` → `DefaultHealthAnalysisResultHandler.analysis(_:)`，`appOnly = true` | `AiSDKCallback.aiHealthAnalysisDone`，`HwHealthAnalysisResult` |
| AI 洞察 | `AiExerciseInsightInput` → `generateExerciseInsight(_:completion:)` | 标题、正文、提醒类别、可选心情 |
| 身体状态 | `AiBodyStatusInput` → `generateBodyStatus(_:completion:)` | 标题、等级、0～100 评分、正文 |
| AI 睡眠（天） | `AiSleepChronotypeInput.period = 0` → `generateSleepChronotype(_:completion:)` | 最佳入睡时间、时型、解释、调整建议、睡眠计划 |
| AI 睡眠（周） | 同上，`period = 1` | 同上 |
| AI 睡眠（月） | 同上，`period = 2` | 同上 |

运动健康分析使用原有健康汇总分析通道，不是运动详情的 `getAiExerciseAnalyzeWithType:data:callback:`。调用前保存旧 `AiSDK.callback`，只在本次请求期间接管；结束、超时、退出时取消本页 handler 并恢复旧 callback。`healthAnalysisAppOnly` / handler 的 `appOnly` 防止把 Demo 结果回传手表。

其余五个入口使用直接 completion，不需为这些 App 主动调用注册全套手表监听，也不需单为它们调用 `startWorking()`。不要为退出分析页而全局 `stopWorking()`，避免中断其他模块。

### 23.4 输入顺序、日期与单位

- 运动健康分析：`HwHealthData.dailyDataList` 为最近 7 天，`day = 0...6`；Demo 基础资料为 30 岁、175 cm、70 kg，`weight = 700`（0.1 kg），睡眠为分钟。Swift 的 `PAI` 属性名为 `pai`。
- AI 洞察：含当天最近 7 天，所有每日数组均为 7 项，**从近到远**保持相同顺序。日期为 `yyyy/MM/dd-yyyy/MM/dd`，结束日期在前。心情使用 SDK 约定的中文枚举，不能直接换成翻译后的字符串。
- 身体状态：当天 `yyyy/MM/dd`；心率、HRV、压力等小时数组按时间顺序；睡眠分段数组对应一致。心率单位 bpm，HRV 为 ms，热量 kcal，活动与睡眠时长为分钟。
- 睡眠日／周／月：分别为 1 项、最近 7 项、本月 1 日至当天的项数；均从近到远。日日期为 `yyyy/MM/dd`，周／月为结束日期到开始日期。月报不是滚动 30 天。
- `sleepHours` 和 `getUpHours` 数量必须相同；Demo 固定 24 小时制，格式 `HH:mm:ss`。SDK 亦支持 `use12HourClock = true` 配合 `hh:mm:ss AM/PM`；缺失日期用字符串 `0` 占位。

Mock 工厂是 `AiAnalysisMock`；替换真实数据时保留相同单位、日期和数组对齐规则，不要把返回报告一起 mock。

### 23.5 UI 与验证边界

Demo 请求期间禁用重复操作及参数编辑；90 秒超时后恢复操作，退出页面丢弃旧会话结果。该超时是 Demo UI 策略，不代表云端请求已取消。SDK 返回 error 或空结果均显示失败，可重新生成；不将错误伪装成成功报告。

常见检查顺序：BLE 与设备 ID → AI 授权 → 渠道参数 → 网络 → 输入日期与数组数量 → 返回格式。语音录音功能才需麦克风权限，本页以健康数据生成报告不申请录音权限。

接入时需验证日／周／月输入数量、跨年与闰年日期、每日数组对齐以及数据单位；**真实云端与授权设备联调需在真机执行**。编译通过不能替代授权、网络和设备上的结果校验。

---

## 附录 A：主要头文件 / 类型

| 内容 | 路径 / 类型 |
|------|-------------|
| 伞头 / 入口 | `HwBluetoothSDK.h` / `HwBluetoothSDK` |
| BLE 核心 | `HwBluetoothCenter.h` |
| 设备模型 | `HwBluetoothDevice` |
| 错误码 | `HwBluetoothError.h` → `HwBCCode` |
| 通用回调 | `HwCommonDefines.h` |
| 设备信息 | `HwDeviceInfo` |
| 用户信息 | `HwUserInfo` |
| 健康 | `HwActivity` / `HwSleep` / `HwHeartRate` / `HwPAI` / … |
| 运动 | `HwWorkout` / `HwWorkoutRealtimeData` |
| 闹钟提醒 | `HwAlarm` / `HwReminder` / `HwSedentaryReminder` |
| 天气 | `HwWeatherInfo` |
| 固件 OTA | `HwOtaDataModel` / `HwOtaType`；`+Ota`；`HwOtaV2Service`；`+FileDifferenceOta`；思澈额外 `SifliOTAManagerSDK` |
| 表盘 | `+WatchFace`；`createOnlineWatchFaceDataAddress:`；`createWatchFaceOtaDataWithIndex:`；`HwJLWatchFaceConfigModel` |
| 音乐/相册/表盘文件 | `HwMultipleFileTransferService` / `HwMultipleFileTransferModel` |
| 杰理自定义表盘配置 | `+JLWatchFace` → `updateJLCustomWatceFace:` |
| Category 聚合 | `HwBluetoothInterfaces.h` |
| 思澈推送（额外） | `SifliWatchfaceSDK`（音乐/相册/QJS 表盘，按交付） |

---

## 附录 B：与 Android 文档差异速查

| 能力 | Android | iOS |
|------|---------|-----|
| 入口 | `BluetoothSDK` 静态方法 | `[HwBluetoothSDK sharedInstance]` |
| 初始化 | `init(app, maxMTU)` | `initSDK`（无 MTU 参数） |
| 失败回调 | `onFail(int code)` | `NSError *` / `error.code` |
| 经典蓝牙配对 | `createBond` / `removeBond` | 系统配对 + `requestDeviceToPair` |
| 本地绑定标记 | `setBind` / `isBind` | `getBindState` + App 自存 |
| 音乐 / 相册 | SPP 或 WL 媒体 / 思澈 ZIP | 杰理：`HwMultipleFileTransferService`；思澈：额外 `SifliWatchfaceSDK` |
| 表盘安装 | `setOnlineWatchface` / QJS / 自定义 | 杰理 MFT；经典 Picture OTA；思澈 `SifliWatchfaceSDK` |
| 固件 OTA | 通用 `ota` / WL `starWlOta` / 思澈 `SifliDFU` | 通用 `otaWithDataModels` / 杰理 `otaV2Service` / 思澈额外 `SifliOTAManagerSDK`；差分 `fdOta` 为备选 |
| 权限 | Manifest + 运行时 | Info.plist + 系统弹窗 |

---

## 附录 C：注意事项

1. **业务指令在连接成功且（多数产品）绑定完成后调用**；断连时常见 `HwBCCodeBLEDisconnected`。  
2. **Callback 勿做重耗时工作**；耗时逻辑请切队列/子线程。  
3. **健康/运动数据成功读取并可靠保存后，才按业务策略 `delete*`**；读取或保存失败时保留数据供重试。
4. **OTA / 推表盘 / 推音乐过程中**避免并发其它大流量指令。  
5. iOS 上已系统连接的设备，务必处理 **MAC 为空** 场景（`updateMacAddressIfNeedWithMac`）。  
6. AI、穆斯林、对讲等高阶能力需对应固件；头文件虽暴露 API，接入前向厂商确认。  
7. 真机调试；模拟器无法完整验证 BLE。  
8. 具体机型的协议版本、特征位、OTA 包格式请索取产品补充文档。
