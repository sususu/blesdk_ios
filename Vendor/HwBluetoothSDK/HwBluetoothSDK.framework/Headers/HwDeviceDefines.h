//
//  HwDeviceDefines.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/24.
//

#ifndef HwDeviceDefines_h
#define HwDeviceDefines_h

@class HwTimeFaceStyleModel;
@class HwVibrationModel;
@class HwDontDisturbModel;
@class HwNightModeModel;
@class HwTimeZone;
@class HwWeatherInfo;
@class HwLocalizeTimeZone;
@class HwMovementScaleModel;
@class HwMenstrual;
@class HwDeviceInfo;

#pragma mark - enum
/*!
 用户性别[user's gender]
 
 - HwSexMale: 男性[male]
 - HwSexFemale: 女性[female]
 */
typedef NS_ENUM(NSInteger, HwSex) {
    HwSexMale = 0x00,
    HwSexFemale = 0x01,
    HwSexUnkown = 0x02
};

typedef NS_ENUM(NSInteger, HwMapTheme) {
    HwMapThemeLight = 0x00,
    HwMapThemeDark = 0x01
};

/*!
 用户戴手表习惯[user's habit of wearing watches]
 
 - HwHandHabitLeft: 左手[left hand]
 - HwHandHabitRight: 右手[right hand]
 */
typedef NS_ENUM(NSInteger, HwHandHabit) {
    HwHandHabitLeft,
    HwHandHabitRight
};

/**
 bind state of device

 - HwBindStateNone: do not bind yet
 - HwBindStateDone: bind
 - HwBindStateOta = 0x81 //思澈OTA中断，需自动升级
 */
typedef NS_ENUM(NSInteger, HwBindState)
{
    HwBindStateNone,
    HwBindStateDone,
    HwBindStateOta = 0x81
};

/**
 Device status

 - HwDeviceUpgradeStateNone: 正常
 - HwDeviceUpgradeStateWaitRecovery: 等待恢复
 - HwDeviceUpgradeStateToBeContinued: 等待续传
 - HwDeviceUpgradeStateToBeContinued: 正在升级
 */
typedef NS_ENUM(NSInteger, HwDeviceUpgradeState)
{
    HwDeviceUpgradeStateNone = 0x00,
    HwDeviceUpgradeStateWaitRecovery = 0x01,
    HwDeviceUpgradeStateToBeContinued = 0x02,
    HwDeviceUpgradeStateBeUpgrading = 0x03
};

typedef NS_ENUM(NSInteger, HwRepeatType)
{
    HwRepeatTypeNone,
    HwRepeatTypeDay,
    HwRepeatTypeWeek,
    HwRepeatTypeMonth,
    HwRepeatTypeYear
};

/*!
 语言类型 Language type
 */
typedef NS_ENUM(NSInteger, HwLanguage) {
    HwLanguageEnglish = 0x00,               // 英文 English
    HwLanguageChineseSimplified = 0x01,     // 中文(简体) Chinese(S)
    HwLanguageChineseTraditional = 0x02,    // 中文(繁体) Chinese(T)
    HwLanguageKorean = 0x03,                // 韩文 Korean
    HwLanguageThai = 0x04,                  // 泰文 Thai
    HwLanguageJapanese = 0x05,              // 日文 Japanese
    HwLanguageSpanish = 0x06,               // 西班牙文 Spanish
    HwLanguageFrench = 0x07,                // 法文 French
    HwLanguageGermany = 0x08,               // 德文 German
    HwLanguageItalian = 0x09,               // 意大利文 Italian
    HwLanguagePolish = 0x0A,                // 波兰文 Polish
    HwLanguagePortuguese = 0x0B,            // 葡萄牙文 Portuguese
    HwLanguageRu = 0x0C,                    // 俄文 Russian
    HwLanguageDutch = 0x0D,                 // 荷兰文 Dutch
    HwLanguageArab = 0x0E,                  // 阿拉伯 Arabic
    HwLanguageGreece = 0x0F,                // 希腊 Greek
    HwLanguageHebrew = 0x11,                // 希伯来文 Hebrew
    HwLanguageSweden = 0x12,                // 瑞典 Swedish
    HwLanguageCzech = 0x13,                 // 捷克语 Czech
    HwLanguageRomania = 0x20,               // 罗马尼亚 Romania
    HwLanguageHungary = 0x21,               // 匈牙利  Hungary
    HwLanguageHindi = 0x22,                 // 印地语 Hindi
    HwLanguageVietnamese = 0x23,            // 越南语 Vietnamese
    HwLanguageIndonesian = 0x24,            // 印尼语 Indonesian
    HwLanguageTurkish = 0x25,               // 土耳其语 Turkish
    HwLanguageBangla = 0x26,                // 孟加拉 Bangla
    HwLanguageUkrainian = 0x27,             // 乌克兰语 Ukrainian
    HwLanguageBelarusian = 0x28,            // 白俄罗斯语 Belarusian
    HwLanguageFarsi = 0x29,                 // 波斯语 Farsi
    HwLanguageKhmer = 0x2A,                 // 高棉语 Khmer
    HwLanguageMalaysia = 0x2B,              // 马来西亚 Malaysia
    HwLanguageSlovak = 0x2C,                // 斯洛伐克语 Slovak
    HwLanguageBulgarian = 0x2D,             // 保加利亚语（Bulgarian）
    HwLanguageSlovenian = 0x2E,             // 斯洛文尼亚语（Slovenian）
    HwLanguageCroatian = 0x2F,              // 克罗地亚语（Croatian）
    HwLanguageDanish = 0x30,                // 丹麦语（Danish）
    HwLanguageKurdishSorani = 0x31,         // 库尔德语-索拉尼（KurdishSorani）
    HwLanguageArmenian = 0x33,              // 亚美尼亚语 Armenian
    HwLanguageIrish = 0x34,                 // 爱尔兰语 Irish
    HwLanguageGeorgian = 0x35,              // 格鲁吉亚语 Georgian
    HwLanguageKazakh = 0x36,                // 哈萨克语 Kazakh
    HwLanguageUzbek = 0x37,                 // 乌兹别克语 Uzbek
    HwLanguageTelugu = 0x38,                // 泰卢固语 Telugu
    HwLanguageTamil = 0x39,                 // 泰米尔语 Tamil
    HwLanguageMarathi = 0x3A,               // 马拉地语 Marathi
    HwLanguageKannada = 0x3B,               // 卡纳达语 Kannada
    HwLanguageGujarati = 0x3C,              // 古吉拉特语 Gujarati
    HwLanguageSerbian = 0x3D,              // 塞尔维亚语 Serbian
    HwLanguageMacedonian = 0x3E,              // 马其顿语 Macedonian
    HwLanguageAlbanian = 0x3F,              // 阿尔巴尼亚语 Albanian
};

/*!
 震动类型 Vibration type
 */
typedef NS_ENUM(NSInteger, HwVibrationType) {
    HwVibrationTypeAntiLost = 0,/**< 防丢提醒0 anti lost*/
    HwVibrationTypeAlarmClock  ,/**< 闹钟提醒1 wake-up alarm*/
    HwVibrationTypeCall        ,/**< 来电提醒2 incoming call*/
    HwVibrationTypeMissingCall ,/**< 未接来电提醒3 missed call*/
    HwVibrationTypeMessage     ,/**< 短信提醒4 sms notification*/
    HwVibrationTypeSocial      ,/**< 社交提醒5 social media notification*/
    HwVibrationTypeEmail       ,/**< 邮件提醒6 email notification*/
    HwVibrationTypeCalendar    ,/**< 日历提醒7 calendar event notification*/
    HwVibrationTypeSitLongTime ,/**< 久坐提醒8 Inactivity Alert */
    HwVibrationTypeLowPower     /**< 低电提醒9 low power alert*/
};

/*!
 震动强度 vibration intensity
 
 - HwVibrationStrengthOFF: 无 none
 - HwVibrationStrengthWeak: 弱 week
 - HwVibrationStrengthStandard: 标准 standard
 - HwVibrationStrengthStrong: 强 strong
 */
typedef NS_ENUM(NSInteger, HwVibrationStrengthType) {
    HwVibrationStrengthOFF      = 0,
    HwVibrationStrengthWeak     = 55,
    HwVibrationStrengthStandard = 75,
    HwVibrationStrengthStrong   = 100
};

/*!
 震动状态
 */
typedef NS_ENUM(NSInteger, HwVibrationState) {
    HwVibrationStateClose      =0,/**< 不震动0 None */
    HwVibrationState1Long        ,/**< 单次长震动1 single long vibration */
    HwVibrationState1Short       ,/**< 单次短震动2 singl short vibration */
    HwVibrationStateSleep2Long   ,/**< 间歇2次长震动3 long vibration twice with Intermittent */
    HwVibrationStateSleep2Short  ,/**< 间歇2次短震动4 short vibration twice with Intermittent*/
    HwVibrationStateLongAndShort ,/**< 长震动-短震动交替5 long vibration-short vibration alternatively */
    HwVibrationStateLongAlways   ,/**< 一直长震6 long vibration all the time */
    HwVibrationStateShortAlways ,  /**< 一直短震7 short vibration all the time*/
    HwVibrationStateSleep5Short ,  /**< 间歇5次长震动 8 long vibration five with Intermittent */
    HwVibrationState1Ring        , /**< 单次响铃 9 single ring */
    HwVibrationState2Ring        , /**< 单2次响铃 10 ring*2 */
    HwVibrationStateLongRing     , /**< 一直响铃 11 ring all the time */
    HwVibrationState1VibrationAndRing, /**< 震动+响铃1 12 vibration and ring */
    HwVibrationStateLongVibrationAndRing, /**< 震动+响铃（一直）13 vibration and ring all the time */
    HwVibrationStateSilent,               /** 静音 14 mute*/
};


/*!
 天气单位 temperature unit
 
 - HwWeatherUnitC: C
 - HwWeatherUnitF: F
 */
typedef NS_ENUM(NSInteger, HwWeatherUnit) {
    HwWeatherUnitC,
    HwWeatherUnitF
};

typedef NS_ENUM(NSInteger, HwWeatherStyle)
{
    HwWeatherStyleSmallForOneDay,
    HwWeatherStyleSmallForFiveDay,
    HwWeatherStyleLargeForOneDay,
    HwWeatherStyleLargeForFiveDay
};

/*!
 时间区 time zone
 
 - HwTimezoneAreaWest: 西部 western
 - HwTimezoneAreaEast: 东部 eastern
 */
typedef NS_ENUM(NSInteger, HwTimezoneArea) {
    HwTimezoneAreaWest,
    HwTimezoneAreaEast
};

typedef NS_ENUM(NSInteger, HwAppState) {
    HwAppStateBackground = 0x00,
    HwAppStateForeground = 0x01
};

/*!
 通知字体大小 notification text size
 
 - HwTextSizeTypeBig: 大 large
 - HwTextSizeTypeSmall: 小 small
 */
typedef NS_ENUM(NSInteger, HwTextSizeType) {
    HwTextSizeTypeBig = 0x00,
    HwTextSizeTypeSmall = 0x01
};

/**
 手表实体按钮事件

 - HwButtonEventTopButtonPress: 上键短按
 - HwButtonEventBottomButtonPress: 下键短按
 - HwButtonEventOtsPress: Ots短按
 - HwButtonEventOtsLongPress: Ots长按
 */
typedef NS_ENUM(NSInteger, HwButtonEvent) {
    HwButtonEventTopButtonPress = 0x01,
//    HwButtonEventTopButtonLongPress = 0x02,
    HwButtonEventBottomButtonPress,
    HwButtonEventOtsPress,
    HwButtonEventOtsLongPress
};

typedef NS_ENUM(NSInteger, HwPowerState) {
    HwPowerStateNormal = 0x00,
    HwPowerStateFlash = 0x01, //低电关闭flash
    HwPowerStateBuzzer = 0x02, //低电关闭蜂鸣器
    HwPowerStateFlashAndBuzzer = 0x03 // 低电关闭flash和蜂鸣器
};

typedef NS_ENUM(NSInteger, HwButtonAction) {
    HwButtonActionNone = 0x00,
    HwButtonActionScreenSwitch = 0x01,
    HwButtonActionHeartRate,
    HwButtonActionCalendar,
    HwButtonActionMusicControl,
    HwButtonActionTimer,
    HwButtonActionCameraRemote,
    HwButtonActionAlarm,
    HwButtonActionWeather,
    HwButtonActionHomeTimeZone,
    HwButtonActionNotificationList,
    HwButtonActionSMSList,
    HwButtonActionStopWatch,
    HwButtonActionMessedCalls,
    HwButtonActionActivityData,
    HwButtonActionSleepData,
    HwButtonActionFindMyPhone,
    HwButtonActionFindDontDisturb,
    HwButtonActionFindSlientMode,
    HwButtonActionFindFlightMode,
    HwButtonActionDate,
    HwButtonActionWeek,
    HwButtonActionGroupWithDateWeekActivity,  // 固定组合：日期、星期、运动
    HwButtonActionMusicPlayOrPause,
    HwButtonActionMusicPrevious,
    HwButtonActionMusicNext,
    HwButtonActionMusicAddVolume,
    HwButtonActionMusicReduceVolume,
    
    HwButtonActionTurnOn = 0xFF // 功能打开（按原设置内容）
};

typedef NS_ENUM(NSInteger, HwScaleContentType) {
    HwScaleContentTypeAllResidualContacts,   // 剩余所有未设置的联系人
    HwScaleContentTypeSocial,        // 社交
    HwScaleContentTypeSingleContact,  // 设置单个联系人
    HwScaleContentTypeAllResidualMessage // 剩余所有未设置的联系人的短信
};

typedef NS_ENUM(NSInteger, HwSocialType) {
    HwSocialTypeMissCall = 0x00, // 未接来电
    HwSocialTypeMessage = 0x01, // 短信息
    HwSocialTypeSocialMessage = 0x02, // 社交消息
    HwSocialTypeMail = 0x03, // 邮件
    HwSocialTypeSchedule = 0x04, // 日程
    HwSocialTypeIncomingCall = 0x05, // 来电
    HwSocialTypeHangupCall = 0x06, // 来电挂断
    HwSocialTypeWechat = 0x07, // Wechat
    HwSocialTypeViber = 0x08, // Viber
    HwSocialTypeSnapchat = 0x09, // Snapchat
    HwSocialTypeWhatsApp = 0x0A, // WhatsApp
    HwSocialTypeQQ = 0x0B, // QQ
    HwSocialTypeFacebook = 0x0C, // Facebook
    HwSocialTypeHangouts = 0x0D, // Hangouts
    HwSocialTypeGmail = 0x0E, // Gmail
    HwSocialTypeMessenger = 0x0F, // Messenger
    HwSocialTypeInstagram = 0x10, // Instagram
    HwSocialTypeTwitter = 0x11, // Twitter
    HwSocialTypeLinkedin = 0x12, // Linkedin
    HwSocialTypeUber = 0x13, // Uber
    HwSocialTypeLine = 0x14, // Line
    HwSocialTypeSkype = 0x15, // Skype
    HwSocialTypeBooking = 0x17, // Booking
    HwSocialTypeAirbnb = 0x18, // Airbnb
    HwSocialTypeFlipboard = 0x19, // Flipboard
    HwSocialTypeTelegram = 0x1A, // Telegram
    HwSocialTypePandora = 0x1B, // Pandora
    HwSocialTypeSpotify = 0x1C, // Spotify
    HwSocialTypeDropbox = 0x1D, // Dropbox
    HwSocialTypeShazam = 0x1E, // Shazam
    HwSocialTypeLift = 0x1F, // Lift
    HwSocialTypeWaze = 0x20, // Waze
    HwSocialTypeSlack = 0x21, // Slack
    HwSocialTypeDeliveroo = 0x22, // Deliveroo
    HwSocialTypePinterest = 0x23, // Pinterest
    HwSocialTypeNetflix = 0x24, // Netflix
    HwSocialTypeYoutube = 0x25, // Youtube
    HwSocialTypeGoogleMap = 0x26, // GoogleMap
    HwSocialTypeLyft = 0x27, // Lyft
    HwSocialTypeVenmo = 0x28, // Venmo
    HwSocialTypePaypal = 0x29, // Paypal
    HwSocialTypeAirFrance = 0x2A, // AirFrance
    HwSocialTypeBfmtv = 0x2B, // Bfmtv
    HwSocialTypeBusinessInsider = 0x2C, // BusinessInsider
    HwSocialTypeCNNBreaking = 0x2D, // CNNBreaking
    HwSocialTypeIGeneration = 0x2E, // IGeneration
    HwSocialTypeLemonde = 0x2F, // Lemonde
    HwSocialTypeSpark = 0x30, // Spark
    HwSocialTypeOther = 0x31, // 其他
    HwSocialTypeEspn = 0x32, // Espn
    HwSocialTypeCash = 0x34, // Cash
    HwSocialTypeTinder = 0x35, // Tinder
    HwSocialTypeBumble = 0x36, // Bumble
    HwSocialTypeBankOfAmericaMobile = 0x37, // BankOfAmericaMobile
    HwSocialTypeWellsFargoMobile = 0x38, // WellsFargoMobile
    HwSocialTypeOutlook = 0x39, // Outlook
    HwSocialTypeLeFigaro = 0x3A, // LeFigaro
    HwSocialTypeMorandiniBlog = 0x3B, // MorandiniBlog
    HwSocialTypeIndiegogo = 0x3C, // Indiegogo
    HwSocialTypeKickstarter = 0x3D, // Kickstarter
    HwSocialTypeStripeDashboard = 0x3E, // StripeDashboard
    HwSocialTypeKLM = 0x3F, // KLM
    HwSocialTypeEasyJet = 0x40, // EasyJet
    HwSocialTypeSWISS = 0x41, // SWISS
    HwSocialTypeLufthansa = 0x42, // Lufthansa
    HwSocialTypeAmericanAirlines = 0x43, // AmericanAirlines
    HwSocialTypeFlyDelta = 0x44, // FlyDelta
    HwSocialTypeJetSmarter = 0x45, // JetSmarter
    HwSocialTypeDiDi = 0x46, // DiDi
    HwSocialTypeUberEats = 0x47, // UberEats
    HwSocialTypeOpenTable = 0x48, // OpenTable
    HwSocialTypeMention = 0x49, // Mention
    HwSocialTypeSwissQuote = 0x4A, // SwissQuote
    HwSocialTypeDiagralConnect = 0x4B, // DiagralConnect
    HwSocialTypeNest = 0x4C, // Nest
    HwSocialTypeNetatmoSecurity = 0x4D, // NetatmoSecurity
    HwSocialTypeUBSFinancial = 0x4E, // UBSFinancial
    HwSocialTypeN26MobileBank = 0x4F, // N26MobileBank
    HwSocialTypeKakaoTalk = 0x50, // KakaoTalk
    HwSocialTypeAmazon = 0x51, // Amazon
    HwSocialTypeEbay = 0x52, // Ebay
    HwSocialTypeWeibo = 0x54, // Weibo
    HwSocialTypeYelp = 0x55, // Yelp
    HwSocialTypeGoogleDrive = 0x56, // GoogleDrive
    HwSocialTypeTikTok = 0x57, // TikTok
    HwSocialTypeLetgo = 0x58, // Letgo
    HwSocialTypeOfferUp = 0x59, // OfferUp
    HwSocialTypeStarbucks = 0x5A, // Starbucks
    HwSocialTypeTumblr = 0x5B, // Tumblr
    HwSocialTypeYolo = 0x5C, // Yolo
    HwSocialTypeDingDing = 0x5D, // 钉钉
};

/*!
新增0x26  事件时间间隔提醒类型[HwEven Remind interval Type]
 
 - HwEvenRemindWaterType: 喝水量[water]
 - HwEvenRemindTemperatureType:体温[temperature]
 */
typedef NS_ENUM(NSInteger, HwEvenRemindType) {
    HwEvenRemindWaterType = 0x00,
    HwEvenRemindTemperatureType = 0x01
};

/*! @brief
 手表时间界面日期样式 [date format of device]
 */
typedef NS_ENUM(NSInteger, HwDateStyle)
{
    HwDateStyleNotDisplay = 0x00,     // 不显示日期 [not showing date]
    HwDateStyleYY_MM_DD = 0x01,       // yy/mm/dd
    HwDateStyleDD_MM_YY = 0x02,       // dd/mm/yy
    HwDateStyleMM_DD_YY = 0x03,       // mm/dd/yy
    HwDateStyleWeek_MM_DD = 0x04,     // 星期几/mm/dd [week/mm/dd]
    HwDateStyleMM_DD = 0x05,          // mm/dd
    HwDateStyleDD_MM = 0x06,          // dd/mm
    HwDateStyleYY_DD_MM = 0x07,       // yy/dd/mm
    HwDateStyleNone = 0xff              // none
};

/*! @brief
 手表时间界面时间样式 [Time format of the watch]
 */
typedef NS_ENUM(NSInteger, HwTimeStyle)
{
    HwTimeStyleNotDisplay = 0x00,       // 不显示时间 [not showing time]
    HwTimeStyle24H = 0x01,              // 24Hour style
    HwTimeStyle12H = 0x02,              // 12Hour style
    HwTimeStyleAnalogy1 = 0x03,         // 模拟时钟1 [Analog clock1]
    HwTimeStyleAnalogy2 = 0x04,         // 模拟时钟2 [Analog clock2]
    HwTimeStyleAnalogyNone = 0xff
};

typedef NS_ENUM(NSInteger, HwTimeFormat)
{
    HwTimeFormat24H = 0x01,             // 24Hour style
    HwTimeFormat12H = 0x02              // 12Hour style
};

/*! @brief
 距离的显示单位 [Display unit of distance]
 */
typedef NS_ENUM(NSInteger, HwUnitStyle)
{
    HwUnitStyleKM = 0x00,
    HwUnitStyleMile = 0x01
};


/*! @brief
 手表时间界面电池样式[battery icon type of the watch face]
 
 - HwBatteryStyleNotDisplay: 不显示电池 [not showing battery]
 - HwBatteryStyleDisplay: 显示电池 [show battery]
 */
typedef NS_ENUM(NSInteger, HwBatteryStyle)
{
    HwBatteryStyleNotDisplay = 0x00,
    HwBatteryStyleDisplay = 0x01,
    HwBatteryStyleNone = 0xff
};

/*! @brief
 手表时间界面农历样式 [Lunar calendar format of watch face]
 
 - HwLunarStyleNotDisplay: 不显示农历 [not showing Lunar calendar]
 - HwLunarStyleDisplay: 显示农历 [show Lunar calendar]
 */
typedef NS_ENUM(NSInteger, HwLunarStyle)
{
    HwLunarStyleNotDisplay = 0x00,
    HwLunarStyleDisplay = 0x01,
    HwLunarStyleNone = 0xff
};

/*! @brief
 手表时间界面屏幕样式[style of the time format on the watch ]
 
 - HwScreenStyleHorizontal: 水平 [Horizontal]
 - HwScreenStyleVertical: 垂直 [Vertical]
 */
typedef NS_ENUM(NSInteger, HwScreenStyle)
{
    HwScreenStyleHorizontal = 0x00,
    HwScreenStyleVertical = 0x01,
    HwScreenStyleNone = 0xff
};
// 其他的自行扩展，也可以自己根据业务自定义枚举

/*! @brief
 手表时间界面心率样式
 
 - HwHeartRateStyleNotDisplay: 不显示
 - HwHeartRateStyle1: 样式1（具体看UI、UE设计）
 - HwHeartRateStyle2: 样式2
 - HwHeartRateStyle3: 样式3
 - HwHeartRateStyle4: 样式4
 - HwHeartRateStyle5: 样式5
 - HwHeartRateStyle6: 样式6
 - HwHeartRateStyle7: 样式7
 - HwHeartRateStyle8: 样式8
 - HwHeartRateStyle9: 样式9
 */
typedef NS_ENUM(NSInteger, HwHeartRateStyle)
{
    HwHeartRateStyleNotDisplay = 0x00,
    HwHeartRateStyle1 = 0x01,
    HwHeartRateStyle2 = 0x02,
    HwHeartRateStyle3 = 0x03,
    HwHeartRateStyle4 = 0x04,
    HwHeartRateStyle5 = 0x05,
    HwHeartRateStyle6 = 0x06,
    HwHeartRateStyle7 = 0x07,
    HwHeartRateStyle8 = 0x08,
    HwHeartRateStyle9 = 0x09,
    HwHeartRateStyleNone = 0xff
};

/*! @brief
 手表时间界面用户名样式
 
 - HwUsernameStyleNotDisplay: 不显示
 - HwUsernameStyleDisplay: 显示
 */
typedef NS_ENUM(NSInteger, HwUsernameStyle)
{
    HwUsernameStyleNotDisplay = 0x00,
    HwUsernameStyleDisplay = 0x01,
    HwUsernameStyleNone = 0xff
};


typedef NS_ENUM(NSInteger, HwDeviceWorkMode)
{
    HwDeviceWorkModePowerSave = 0x00,       // 省电模式 [power saving mode]
    HwDeviceWorkModeFly = 0x01,         // 飞行模式 [flying mode]
    HwDeviceWorkModeDefault = 0x02,     // 默认模式 [default mode]
    HwDeviceWorkModeCustom = 0x03,      // 用户自定义模式 [customerized mode]
};

typedef NS_ENUM(NSInteger, HwBluetoothSpeed)
{
    HwBluetoothSpeedSlow = 0x01,
    HwBluetoothSpeedNormal = 0x02,
    HwBluetoothSpeedFast = 0x03
};

/*! @brief
 关机后模式 [power off mode]
 
 - HwPowerOffModeHands: 只有指针在动 [only hands are moving]
 - HwPowerOffModeHandsAndActivity: 指针和运动检测同时工作 [hands moving and device are detecting activity info ]
 */
typedef NS_ENUM(NSInteger, HwPowerOffMode) {
    HwPowerOffModeHands,
    HwPowerOffModeHandsAndActivity
};

/**
 手表屏幕亮度等级

 - WatchQuarterBright: 四分之一亮
 - WatchHalfBright: 半亮
 - WatchThreeQuarterBright: 四分之三亮
 - WatchFullBright: 最高亮度
 */
typedef NS_ENUM(NSInteger, WatchScreenBrightnessLevel) {
    WatchQuarterBright = 25,
    WatchHalfBright = 50,
    WatchThreeQuarterBright = 75,
    WatchFullBright = 100,
};

typedef NS_ENUM(NSInteger, HwContactType)
{
    HwContactTypeFirst,
    HwContactTypeMiddle,
    HwContactTypeEnd,
    HwContactTypeOnlyOne
};


/**
 星期几[day  of the week]
 例子：星期一、星期二、星期五可表示为
 HwWeek week = HwWeekMonday | HwWeekTuesday | HwWeekFriday;
 
 - HwWeekMonday: 星期一
 - HwWeekTuesday: 星期二
 - HwWeekWednesday: 星期三
 - HwWeekThursday: 星期四
 - HwWeekFriday: 星期五
 - HwWeekSaturday: 星期六
 - HwWeekSunday: 星期日
 */
typedef NS_ENUM(NSInteger, HwWeek) {
    HwWeekMonday = (0x01 << 0),
    HwWeekTuesday = (0x01 << 1),
    HwWeekWednesday = (0x01 << 2),
    HwWeekThursday = (0x01 << 3),
    HwWeekFriday = (0x01 << 4),
    HwWeekSaturday = (0x01 << 5),
    HwWeekSunday = (0x01 << 6),
};

#pragma mark - callback
typedef void (^HwLanguageCallback)(HwLanguage lan, NSError *error);
typedef void (^HwSupportedLanguagesCallback)(NSArray *languages, NSError *error);
typedef void (^HwTimeFaceStyleCallback)(HwTimeFaceStyleModel *model, NSError *error);
typedef void (^HwCustomWatchFaceInfoCallback)(NSInteger index, NSData *address, NSError *error);
typedef void (^HwSetCustomWatchFaceCallback)(NSData *otaData, BOOL needOTA, BOOL b, NSError *error);
typedef void (^HwVibrationArrayCallback)(NSArray<HwVibrationModel *> *models, NSError *error);
typedef void (^HwTimezoneCallback)(HwTimeZone *timezone, NSError *error);
typedef void (^HwNotificationTextSizeCallback)(HwTextSizeType type, NSError *error);
typedef void (^HwWorkModeCallback)(HwDeviceWorkMode mode, NSError *error);
typedef void (^HwDontDisturbCallback)(HwDontDisturbModel *model, NSError *error);
typedef void (^HwBluetoothSpeedCallback)(HwBluetoothSpeed speed, NSError *error);
typedef void (^HwPowerOffModeCallback)(HwPowerOffMode mode, NSError *error);
typedef void (^HwWatchButtonCallback)(NSArray *actions, NSArray *events, NSError *error);
typedef void (^HwDeviceInfoCallback)(HwDeviceInfo *deviceInfo, NSError *error);
#pragma mark - const



#endif /* HwDeviceDefines_h */
