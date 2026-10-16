# BLE Demo · iOS 使用指南

本项目是 `HwBluetoothSDK` 的 iOS 接入示例，包含设备连接与绑定、健康数据、提醒、表盘、媒体推送、固件升级和 AI 功能。本文介绍 Demo 的安装、运行、功能操作和调试方法。SDK 在客户 App 中的集成与接口用法，请阅读 [SDK_iOS.md](SDK_iOS.md)。

- **首次使用 Demo**：从下面的「运行 Demo」开始。
- **接入 SDK、查接口和参数**：阅读 [SDK 使用文档](SDK_iOS.md)。
- **安卓对齐界面**：打开 [BLE Demo UI 对照稿](<docs/BLE Demo UI 对照稿.html>)，可离线查看。

## 1. 运行 Demo

### 准备

- Mac、Xcode、CocoaPods。
- 一台 **iOS 14.0 或以上的真机 iPhone**；蓝牙功能请使用真机验证。
- 与本 SDK 配套的手表或手环，确认设备方案和固件版本。
- 安装依赖需要访问 Podfile 中的 Git 仓库；在线表盘、OTA 检查和 AI 等功能还需要网络。

### 安装与启动

在仓库根目录执行：

```bash
pod install
open BleSdkDemo.xcworkspace
```

在 Xcode 中完成以下设置：

1. 打开 **BleSdkDemo.xcworkspace**，选择 **BleSdkDemo** Scheme。
2. 在 Target → **Signing & Capabilities** 中选择自己的 Team，按需修改 Bundle Identifier。
3. 选择已连接的 iPhone，运行 App，允许蓝牙访问并打开手机蓝牙。

请保留仓库中的 `Podfile.lock`，首次安装使用 `pod install`。工程已配置依赖所需的路径和构建设置，不需要手动拖入额外的 Zip、SSZipArchive 等库。

### 第一次验证：连接 → 绑定 → 读取

| 步骤 | Demo 操作 | 验证结果 |
| --- | --- | --- |
| 连接 | 首页 → **设备连接 → 扫描连接**，按名称找到自己的设备并点击 | 返回首页，显示连接状态和设备信息 |
| 绑定 | 首页 → **设备连接 → 绑定**，在手表上确认（如设备要求） | 绑定步骤完成，首页显示已绑定 |
| 读取 | 按设备方案选择下面的入口 | 显示设备返回的数据，或正常的空数据结果 |

- **杰理设备**：首页 → **健康数据 → 同步数据（杰理）**，先选择一项读取；也可进入 **手动测量（杰理）**，选择心率后开始测量。
- **使用通用接口的设备**：首页 → **健康数据 → 目标 Goals → 获取目标**，验证业务接口可正常返回。
- 返回首页，点击 **展开运行日志** 查看连接或同步过程；子页面有日志时，也可在页面内展开查看。

**注意「同步数据」的演示策略**：首页不带“杰理”后缀的 **同步数据**，在成功读取非空的活动、心率、睡眠数据后，会调用删除接口清理相应设备端数据。首次验证建议先使用上面的读取入口；正式接入时应在数据可靠保存后，再决定是否删除设备端记录。杰理同步页的读取与删除是独立操作，删除需要确认。

## 2. 在 Demo 中找到需要的功能

首页按场景分为五组。功能是否支持由设备方案、机型和固件决定；带 **“杰理”** 的入口使用杰理相关接口，思澈与杰理的传输、表盘和 OTA 入口应按实际设备选择。

| 首页分类 | 功能入口 | 从哪里看实现 |
| --- | --- | --- |
| 设备连接 | 扫描连接、绑定、断开、解绑 | [扫描连接](BleSdkDemo/Sources/UI/Scan/ScanConnectViewController.swift)、[绑定流程](BleSdkDemo/Sources/UI/Bind/BindFlowViewController.swift)、[解绑流程](BleSdkDemo/Sources/UI/Unbind/UnbindFlowViewController.swift) |
| 健康数据 | 通用同步、杰理同步、手动测量、自动监测、目标 | [通用业务封装](BleSdkDemo/Sources/Services/BleRepository.swift)、[杰理数据同步](BleSdkDemo/Sources/UI/Jieli/JieliHealthSyncViewController.swift)、[手动测量](BleSdkDemo/Sources/UI/Jieli/JieliManualMeasureViewController.swift)、[自动监测](BleSdkDemo/Sources/UI/Jieli/JieliAutoMonitorViewController.swift) |
| 提醒与日常 | 闹钟、杰理闹钟与提醒、通知与通讯录 | [目标／闹钟／通知示例](BleSdkDemo/Sources/UI/Features/FeatureViewControllers.swift)、[杰理提醒设置](BleSdkDemo/Sources/UI/Jieli/JieliAlarmReminderViewController.swift) |
| 表盘、媒体与 AI | 思澈／杰理表盘、音乐推送、相册推送、AI | [思澈表盘](BleSdkDemo/Sources/UI/Watchface/WatchfaceHostViewController.swift)、[杰理表盘](BleSdkDemo/Sources/UI/Jieli/JieliWatchfaceHostViewController.swift)、[音乐](BleSdkDemo/Sources/UI/Features/MusicTransferViewController.swift)、[相册](BleSdkDemo/Sources/UI/Features/AlbumTransferViewController.swift)、[AI 入口](BleSdkDemo/Sources/UI/AI/AiHostViewController.swift) |
| 升级与维护 | AGPS、思澈 OTA、杰理 OTA | [AGPS](BleSdkDemo/Sources/UI/Features/AgpsUpdateViewController.swift)、[思澈 OTA](BleSdkDemo/Sources/UI/Features/OtaUpgradeViewController.swift)、[杰理 OTA](BleSdkDemo/Sources/UI/Jieli/JieliOtaUpgradeViewController.swift) |

表盘页包含 **自定义、在线、AI** 三个页签。当前音乐、相册和 AGPS 演示入口走思澈通道。首页右上角可切换中文、English 或跟随系统。

## 3. Demo 源码参考

启动入口是 [AppDelegate.swift](BleSdkDemo/Sources/AppDelegate.swift) 中的 `BleRepository.shared.initSDK()`；该方法统一完成蓝牙、传输 SDK 初始化及杰理 AI 图片转换器注入。依赖和构建设置见 [Podfile](Podfile)，权限配置见 [Info.plist](BleSdkDemo/Supporting/Info.plist)。

| Demo 模块 | 实现位置 |
| --- | --- |
| 初始化、扫描、连接、回调、重连和通用业务 | [BleRepository.swift](BleSdkDemo/Sources/Services/BleRepository.swift) |
| 用户选择扫描结果、连接结果处理 | [ScanConnectViewController.swift](BleSdkDemo/Sources/UI/Scan/ScanConnectViewController.swift) |
| 完整绑定顺序及失败处理 | [BindFlowViewController.swift](BleSdkDemo/Sources/UI/Bind/BindFlowViewController.swift) |
| 本地绑定记录 | [BoundDeviceStore.swift](BleSdkDemo/Sources/Services/BoundDeviceStore.swift) |
| 完整解绑流程 | [UnbindFlowViewController.swift](BleSdkDemo/Sources/UI/Unbind/UnbindFlowViewController.swift) |
| 杰理文件传输／OTA | `HwBluetoothSDK.multipleFileTransferService` / `otaV2Service`；调用示例见 [BleRepository.swift](BleSdkDemo/Sources/Services/BleRepository.swift) |
| 杰理健康数据封装 | [JieliHealthRepository.swift](BleSdkDemo/Sources/Services/Jieli/JieliHealthRepository.swift) |

`BleRepository` 是 Demo 的业务封装，并非 SDK 对外类；它同时引用表盘、OTA 和 AI 相关代码。接入自己的 App 时，所需依赖、权限、初始化步骤和 API 调用方式统一查阅 [SDK 使用文档](SDK_iOS.md)。

## 4. 使用 Demo 验证客户设备时的配置

| 项目 | 替换位置与说明 |
| --- | --- |
| 用户资料、目标、提醒等示例值 | [BleRepository.swift](BleSdkDemo/Sources/Services/BleRepository.swift) 及对应页面；改为 App 的真实用户配置 |
| OTA 服务 | [OtaFirmwareApi.swift](BleSdkDemo/Sources/Services/Ota/OtaFirmwareApi.swift) 中的 `baseURL`、`fileBaseURL`、`customerCode`；当前指向测试环境 |
| 在线表盘服务 | [WatchfaceApi.swift](BleSdkDemo/Sources/Services/Watchface/WatchfaceApi.swift) 中的服务地址、客户标识和产品类型匹配逻辑 |
| 相册及表盘尺寸 | 使用实际设备屏幕和缩略图参数；相册 Demo 默认尺寸为 `466 × 466`，不能通用于所有设备 |
| AI 授权与渠道配置 | [AiAnalysisViewController.swift](BleSdkDemo/Sources/UI/AI/AiAnalysisViewController.swift)；替换为自己的配置，可用 `AI_OAS_CHANNEL_ID` / `AI_OAS_APP_KEY` 环境变量覆盖 |
| AI 分析输入 | 同一文件的 `AiAnalysisMock`；Demo 使用模拟健康数据调用真实 AI 服务，接入时替换为真实数据，设备需具备相应授权 |

表盘、音乐、相册、AGPS 和 OTA 应串行执行；Demo 已共用传输锁。使用自己的封装时也应避免传输任务相互占用蓝牙通道。

## 5. 常见问题

| 现象 | 先检查 |
| --- | --- |
| 编译提示模块或头文件缺失 | 是否执行 `pod install`、打开 `.xcworkspace`，以及是否保留 `Vendor/HwBluetoothSDK` 和 Podfile 的构建配置 |
| 扫描不到设备 | 真机蓝牙和 App 蓝牙权限是否开启；设备是否在附近、可被发现，是否已被其他 App／手机连接 |
| 已连接但业务接口失败 | 是否完成绑定；当前机型／固件是否支持该接口；是否选错了思澈／杰理入口；查看错误和运行日志 |
| 读取结果为空 | 手表可能尚未产生记录，或此前已被同步删除；佩戴设备产生数据后重试 |
| 手动断开后不再自动连接 | 这是 Demo 的预期行为；手动断开会关闭自动重连，可重新扫描连接 |
| 解绑后再次绑定异常 | 到 iPhone **设置 → 蓝牙 → 对应设备 → 忽略此设备** 后重试；iOS 无公开 API 自动清除系统配对 |
| 后台断开后没有持续重连 | 已绑定且开启自动重连时，Demo 在前台执行重连；回到前台或蓝牙恢复可用后再尝试 |
| OTA／在线表盘无可用资源 | 确认服务器环境、客户配置、产品类型与设备固件匹配；测试服务不代表客户机型已有对应资源 |
| AI 请求失败 | 检查网络、设备 ID、AI 授权与自己的渠道配置，并查看页面错误；AI 分析并非本地模拟返回 |

需要排查时，请同时提供 **SDK 版本（首页左上角）、iPhone/iOS 版本、设备型号与固件版本、复现步骤和错误日志**。

完整 API、协议分支与数据单位请继续查阅 [SDK_iOS.md](SDK_iOS.md)。
