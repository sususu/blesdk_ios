//
//  HwWorkout.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/1/17.
//

#import <Foundation/Foundation.h>
#import "HwTimeSection.h"
#import "HwWorkoutPoint.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Workout type enum
 */
typedef NS_ENUM(NSInteger, HwWorkoutType)
{
    HwWorkoutTypeOther = 0,
    // 户外健走
    HwWorkoutTypeOutdoorWalking = 1,
    // 户外跑步
    HwWorkoutTypeOutdoorRunning = 2,
    // 健身操
    HwWorkoutTypeSettingupExercise = 3,
    // 游泳
    HwWorkoutTypeSwimming = 4,
    // 户外骑行
    HwWorkoutTypeOutdoorCycling = 5,
    // 登山运动
    HwWorkoutTypeMoutaineering = 7,
    // 站立训练
    HwWorkoutTypeStandingTraining = 8,
    // 坐姿训练
    HwWorkoutTypeSittingTraining = 9,
    
    // 室内骑行
    HwWorkoutTypeIndoorCycling = 10,
    // 举重训练
    HwWorkoutTypeWeightTraining = 11,
    // 有氧运动
    HwWorkoutTypeAerobics = 12,
    // 室内健走
    HwWorkoutTypeIndoorWalking = 13,
    // 室内跑步
    HwWorkoutTypeIndoorRunning = 14,
    // 瑜伽
    HwWorkoutTypeYoga = 15,
    // 力量训练
    HwWorkoutTypeStrengthTraining = 16,
    // 椭圆机训练
    HwWorkoutTypeEllipticalTraining = 17,
    // 踏步机
    HwWorkoutTypeStairStepper = 18,
    // 跳舞
    HwWorkoutTypeDance = 19,
    // 羽毛球
    HwWorkoutTypeBadminton = 20,
    // 篮球
    HwWorkoutTypeBasketball = 21,
    // 自由训练
    HwWorkoutTypeFreeTraining = 22,
    // 徒步
    HwWorkoutTypeHiking = 23,  // 徒步
    // 越野跑
    HwWorkoutTypeCrossCountry = 24,
    // 划船机
    HwWorkoutTypeRowingMachine = 25,
    // 攀登
    HwWorkoutTypeClimbing = 26,
    // 需求
    HwWorkoutTypeFootball = 27,
    // 乒乓球
    HwWorkoutTypePingPong = 28,
    // 橄榄球
    HwWorkoutTypeRugby = 29,
    // 网球
    HwWorkoutTypeTennis = 30,
    // 排球
    HwWorkoutTypeVolleyBall = 31,
    // 摔跤
    HwWorkoutTypeWrestling = 32,
    // 拳击
    HwWorkoutTypeBoxing = 33,
    // 普拉提
    HwWorkoutTypePilates = 34,
    // 嘻哈
    HwWorkoutTypeHiphop = 35,
    // 高尔夫
    HwWorkoutTypeGolf = 36,
    // 冲浪
    HwWorkoutTypeSurfing = 37,
    // 皮划艇
    HwWorkoutTypeGanoeing = 38,
    // 滑冰
    HwWorkoutTypeIceSkating = 39,
    // 走步机
    HwWorkoutTypeTreadmill = 40,
    // 打猎
    HwWorkoutTypeHunting = 41,
    // 钓鱼
    HwWorkoutTypeFishing = 42,
    // 玩滑板
    HwWorkoutTypeSkateboarding = 43,
    // 空手道
    HwWorkoutTypeKarate = 44,
    // 跳绳
    HwWorkoutTypeRopeSkipping = 45,
    // 板球
    HwWorkoutTypeCricket = 46,
    // 拉伸
    HwWorkoutTypeStretching = 47,
    // 柔道
    HwWorkoutTypeJudo = 48,
    // 武术
    HwWorkoutTypeMartialArt = 49,
    // 体操
    HwWorkoutTypeGymnastic = 50,
    // 仰卧起坐
    HwWorkoutTypeSitupExercise = 51,
    // 竞走
    HwWorkoutTypeRaceWalking = 52,
    // 马拉松赛跑
    HwWorkoutTypeMarathon = 53,
    // 单车
    HwWorkoutTypeUnicycle = 54,
    // Bmx
    HwWorkoutTypeBmx = 55,
    // 轮滑
    HwWorkoutTypeRollerSkating = 56,
    // 健腹轮
    HwWorkoutTypeAbRoller = 57,
    // 步行机
    HwWorkoutTypeWalkingMachine = 58,
    // 呼拉圈
    HwWorkoutTypeHulaHoop = 59,
    // 飞镖
    HwWorkoutTypeDarts = 60,
    // 棒球运动
    HwWorkoutTypeBaseball = 61,
    // 台球
    HwWorkoutTypeBilliard = 62,
    // 羽毛球
    HwWorkoutTypeShuttlecock = 63,
    // 马球
    HwWorkoutTypePolo = 64,
    // 壁球
    HwWorkoutTypeSquash = 65,
    // 保龄球
    HwWorkoutTypeBowling = 66,
    // 体操
    HwWorkoutTypeGymBall = 67,
    // 曲棍球
    HwWorkoutTypeHockey = 68,
    // 芭蕾
    HwWorkoutTypeBallet = 69,
    // 快步舞
    HwWorkoutTypeQuickstep = 70,
    // 摇摆舞
    HwWorkoutTypeJive = 71,
    // 肚皮舞
    HwWorkoutTypeBellyDance = 72,
    // 探戈
    HwWorkoutTypeTango = 73,
    // 塑造
    HwWorkoutTypeShaping = 74,
    // 钢管舞
    HwWorkoutTypePoleDance = 75,
    // 恰恰舞
    HwWorkoutTypeChaCha = 76,
    // 伦巴
    HwWorkoutTypeRumba = 77,
    HwWorkoutTypeJazz = 78,
    HwWorkoutTypeSamba = 79,
    HwWorkoutTypePasoDoble = 80,
    HwWorkoutTypeWaltz = 81,
    HwWorkoutTypeMuayThai = 82,
    HwWorkoutTypeTaekwondo = 83,
    HwWorkoutTypefreeFight = 84,
    HwWorkoutTypeSanda = 85,
    HwWorkoutTypeJeetKuneDo = 86,
    HwWorkoutTypeMma = 87,
    HwWorkoutTypeKickboxing = 88,
    HwWorkoutTypeTaiChi = 89,
    HwWorkoutTypeSambo = 90,
    HwWorkoutTypeMulanquan = 91,
    HwWorkoutTypeSumo = 92,
    HwWorkoutTypeAikido = 93,
    HwWorkoutTypeFrisbee = 94,
    HwWorkoutTypeGliding = 95,
    HwWorkoutTypeTugOfWar = 96,
    HwWorkoutTypeHotAirBalloon = 97,
    HwWorkoutTypeParkour = 98,
    HwWorkoutTypeCarRace = 99,
    HwWorkoutTypeSailing = 100,
    HwWorkoutTypeMotorcycleRace = 101,
    HwWorkoutTypeExplore = 102,
    HwWorkoutTypeMotorboat = 103,
    HwWorkoutTypeDrift = 104,
    HwWorkoutTypeRowing = 105,
    HwWorkoutTypeBungee = 106,
    HwWorkoutTypeParachuting = 107,
    HwWorkoutTypeHorseRace = 108,
    //高强度间歇训练
    HwWorkoutTypeHIIT = 109,
    //核心训练
    HwWorkoutTypeCORETRAINING = 110,
    //有氧训练
    HwWorkoutTypeAEROBICTRAINING = 111,
    //无氧训练
    HwWorkoutTypeANAEROBICTRAINING = 112,
    //混合有氧
    HwWorkoutTypeMIXEDTRAINING = 113,
    //柔韧训练
    HwWorkoutTypeFLEXIBILITYTRAINING = 114,
    //冥想
    HwWorkoutTypeMEDITATION = 115,
    //室内健身
    HwWorkoutTypeINDOORFITNESS = 116,
    //踏步训练
    HwWorkoutTypeSTEPPING = 117,
    //划船
    HwWorkoutTypeBOATRACING = 118,
    //遛狗
    HwWorkoutTypeDOGWALKING = 119,
    //冰壶
    HwWorkoutTypeCURLING = 120,
    //户外溜冰
    HwWorkoutTypeOUTDOORICESKATING = 121,
    //室内溜冰
    HwWorkoutTypeINDOORICESKATING = 122,
    //滑雪
    HwWorkoutTypeSKIING = 123,
    //冬季两项
    HwWorkoutTypeBIATHLON = 124,
    //手球
    HwWorkoutTypeHANDBALL = 125,
    //垒球
    HwWorkoutTypeSOFTBALL = 126,
    //门球
    HwWorkoutTypeCROQUET = 127,
    //沙滩排球
    HwWorkoutTypeBEACHVOLLEYBALL = 128,
    //躲避球
    HwWorkoutTypeDODGEBALL = 129,
    //美式足球
    HwWorkoutTypeAMERICANFOOTBALL = 130,
    //广场舞
    HwWorkoutTypeSQUAREDANCE = 131,
    //交谊舞
    HwWorkoutTypeBALLROOMDANCE = 132,
    //尊巴
    HwWorkoutTypeZUMBA = 133,
    //迪斯科
    HwWorkoutTypeDISCO = 134,
    //拉丁舞
    HwWorkoutTypeLATIN = 135,
    //踢踏舞
    HwWorkoutTypeTAPDANCE = 136,
    //剑术
    HwWorkoutTypeFENCING = 137,
    //骑马
    HwWorkoutTypeHORSERIDING = 138,
    //射箭
    HwWorkoutTypeARCHERY = 139,
    //障碍赛
    HwWorkoutTypeSTEEPLECHASE = 140,
    //放风筝
    HwWorkoutTypeKITEFLYING = 141,
    //单杠
    HwWorkoutTypeHORIZONTALBAR = 142,
    //双杠
    HwWorkoutTypePARALLELBARS = 143,
    // 爬楼梯
    HwWorkoutTypeSTAIRCLIMBING = 144,
    // 室内游泳
    HwWorkoutTypeIndoorSwimming = 145,
    // 室外游泳
    HwWorkoutTypeOutdoorSwimming = 146,
    HwWorkoutTypeSEPAK_TAKRAW           = 0x93,     //藤球
    HwWorkoutTypeKENDO                  = 0x94,     //剑道
    HwWorkoutTypeSAVATE                 = 0x95,     //赛法斗
    HwWorkoutTypeKABADDI                = 0x96,     //卡巴迪
    HwWorkoutTypeTRAMPOLINE             = 0x97,     //蹦床
    HwWorkoutTypeATV                    = 0x98,     //ATV 全地形车运动
    HwWorkoutTypeDRAGON_BOAT_RACING     = 0x9a,     //赛龙舟
    HwWorkoutTypePARASAILING            = 0x9b,     //帆伞运动
    HwWorkoutTypePLANK                  = 0x9c,     //平板支撑

    HwWorkoutTypeKAYAKING                   = 0x9d,     //皮艇
    HwWorkoutTypeWATER_SPORTS               = 0x9e,     //水上运动
    HwWorkoutTypeWATER_ACTIVITIES           = 0x9f,     //一般水上活动
    HwWorkoutTypeSNOW_MOBILING              = 0xa0,     //雪上摩托车
    HwWorkoutTypeSLED                       = 0xa1,     //雪橇
    HwWorkoutTypeCROSSCOUNTRY_SKING         = 0xa2,     //越野滑雪

    HwWorkoutTypeSNOWBOARDING               = 0xa3,     //单板滑雪
    HwWorkoutTypeSNOWSHOEING                = 0xa4,     //雪鞋健行
    HwWorkoutTypeSNOW_SPORT                 = 0xa5,     //雪地运动
    HwWorkoutTypeEXTREME_SPORTS             = 0xa6,     //一般极限运动
    HwWorkoutTypeTRIATHLONS                 = 0xa7,     //铁人三项运动
    HwWorkoutTypeHANDCYCLING                = 0xa8,     //手轮车
    HwWorkoutTypeTRACK_FIELD                = 0xa9,     //田径
    HwWorkoutTypeSTEEPLESCHASE              = 0xaa,     //障碍

//    HwWorkoutTypeAIR_WALKER                 = 0xab,     //漫步机
    HwWorkoutTypeRESISTANCE_TRAINING        = 0xac,     //抗阻力训练
    HwWorkoutTypeCROSSFIT                   = 0xad,     //健身
    HwWorkoutTypeGROUP_CALISTHENICS         = 0xae,     //团体操
    HwWorkoutTypeYOGA_CAT_POSE              = 0xaf,     //瑜珈猫式
    HwWorkoutTypeYOGA_COW_POSE              = 0xb0,     //瑜珈牛式
    HwWorkoutTypeYOGA_COBRA_POSE            = 0xb1,     //瑜珈眼镜蛇式
    HwWorkoutTypeYOGA_HERO_1                = 0xb2,     //瑜珈英雄式1
    HwWorkoutTypeYOGA_HERO_2                = 0xb3,     //瑜珈英雄式2
    HwWorkoutTypeYOGA_HERO_3                = 0xb4,     //瑜珈英雄式3
    HwWorkoutTypeYOGA_ROLLING               = 0xb5,     //瑜珈滚轮
    HwWorkoutTypeCROSS_FIT                  = 0xb6,     //混合健身
    HwWorkoutTypeFUNCTIONAL_TRAINING        = 0xb7,     //功能性训练
    HwWorkoutTypePHYSICAL_TRAINING          = 0xb8,     //体能训练
    HwWorkoutTypeBODY_COMBAT                = 0xb9,     //有氧搏击操
    HwWorkoutTypeCIRCUIT_TRAINING           = 0xba,     //循环训练
    HwWorkoutTypeAEROBICS                   = 0xbb,     //有氧运动
    HwWorkoutTypeCALISTHENICS               = 0xbc,     //健美操
    HwWorkoutTypeP90X                       = 0xbd,     //P90X
    HwWorkoutTypeKETTLEBELL_TRAINING        = 0xbe,     //壶铃训练
    HwWorkoutTypeSTAIR_CLIMBING_MACHINE     = 0xbf,     //爬楼梯机
//    HwWorkoutTypeWEIGHTLIFTING              = 0xc0,     //举重
    HwWorkoutTypeBARRE                      = 0xc1,     //运动塑形操
    HwWorkoutTypeMIND_BODY                  = 0xc2,     //身心运动
    HwWorkoutTypeFLEXIBILITY                = 0xc3,     //柔软操
    HwWorkoutTypeMIXED_CARDIO               = 0xc4,     //混和有氧
    HwWorkoutTypeCROSS_TRAINING             = 0xc5,     //交叉训练
    HwWorkoutTypeSTEP_TRAINING              = 0xc6,     //阶梯训练
    HwWorkoutTypeGENERAL_EXERCISE           = 0xc7,     //一般锻炼
    HwWorkoutTypeDIVING                     = 0xc8,     //跳水
    HwWorkoutTypeWATER_FITNESS              = 0xc9,     //水上健身
    HwWorkoutTypeFREESTYLE_SWIMMING         = 0xca,     //自由泳
    HwWorkoutTypeBREASTSTROKE_SWIMMING      = 0xcb,     //蛙泳
    HwWorkoutTypeBACKSTROKE_SWIMMING        = 0xcc,     //仰泳
    HwWorkoutTypeBUTTERFLY_SWIMMING         = 0xcd,     //蝶泳
    HwWorkoutTypeICE_SPORTS                 = 0xce,     //一般冰上运动

//    HwWorkoutTypeAMERICAN_FOOTBALL          = 0x82,     //美式橄榄球, 看 130,0x82
    HwWorkoutTypeBEACH_SOCCER               = 0xd0,     //沙滩足球
    HwWorkoutTypeBEACH_VOLLEYBALL           = 0xd1,     //沙滩排球
//    HwWorkoutTypeDODGE_BALL                 = 0x81,     //躲避球, 129
    HwWorkoutTypeRACQUETBALL                = 0xd3,     //美式壁球
    HwWorkoutTypeGATEBALL                   = 0xd4,     //门球
    HwWorkoutTypePICKLEBALL                 = 0xd5,     //匹克球
    HwWorkoutTypeLACROSSE                   = 0xd6,     //长曲棍球
    HwWorkoutTypeWATER_POLO                 = 0xd7,     //水球
    HwWorkoutTypeICE_HOCKEY                 = 0xd8,     //冰球
    HwWorkoutTypeBALL_GAMES                 = 0xd9,     //一般球类运动

    HwWorkoutTypeGENERAL_DANCE              = 0xda,     //一般舞蹈

    HwWorkoutTypeBATTLE_GAME                = 0xdb,     //对战游戏
    HwWorkoutTypeSWING                      = 0xdc,     //秋千
//    HwWorkoutTypeSTAIR_CLIMBING             = 0xdd,     //爬楼梯，看值为 0x90, 10进制 144
    HwWorkoutTypeSCOOTER_RIDING             = 0xde,     //滑板车
//    HwWorkoutTypePARAGLIDING                = 0xdf,     //滑翔伞
    HwWorkoutTypeTEAM_SPORTS                = 0xe0,     //团队竞技
    HwWorkoutTypeFITNESS_GAMING             = 0xe1,     //健身电玩
    HwWorkoutTypeEQUESTRIAN_SPORTS          = 0xe2,     //马术运动
    HwWorkoutTypePLAY                       = 0xe3,     //玩乐
    HwWorkoutTypeWHITEWATER_RAFTING         = 0xe4,     //白水漂流
    HwWorkoutTypeSUP                        = 0xe5,     //浆板冲浪
    HwWorkoutTypeSCUBA_DIVING               = 0xe6,     //潜水
    HwWorkoutTypeKITESURFING                = 0xe7,     //风筝冲浪
    HwWorkoutTypeWAKEBOARDING               = 0xe8,     //冲浪滑水
    HwWorkoutTypeWINDSURFING                = 0xe9,     //风帆冲浪
    HwWorkoutTypeORIENTEERING               = 0xea,     //定向越野
    HwWorkoutTypeRECREATIONAL_SPORTS        = 0xeb,     //一般休闲运动
    HwWorkoutTypeELEVATOR                   = 0xec,     //乘电梯
    HwWorkoutTypeESCALATOR                  = 0xed,     //乘手扶梯
    HwWorkoutTypeGARDENING                  = 0xee,     //做园艺
    HwWorkoutTypeHOUSE_WORK                 = 0xef,     //做家务
    HwWorkoutTypeIN_VEHICLE                 = 0xf0,     //在车里
    HwWorkoutTypeSTILL                      = 0xf1,     //静止
    HwWorkoutTypeTILTING                    = 0xf2,     //倾斜
    HwWorkoutTypeWHEELCHAIR                 = 0xf3,     //坐轮椅移动
    HwWorkoutTypePlateTennis = 244, // 板式网球
    HwWorkoutTypeFreestyle = 256,//自由泳，LS项目使用
    HwWorkoutTypeIntegratedTraining = 257, // 自由训练，LS项目使用
    HwWorkoutTypeCrossCountryRun = 258, // 越野跑，LS项目使用
    HwWorkoutTypeAerobicTraining2 = 259, // 有氧运动，LS项目使用
    HwWorkoutTypeSwimmingInAPool = 260, // 泳池游泳，LS项目使用
    HwWorkoutTypeBackstrokeSwimming = 261, // 仰泳，LS项目使用
    HwWorkoutTypeSnowSports = 262, // 雪地运动，LS项目使用
    HwWorkoutTypeSledge = 263, // 雪橇，LS项目使用
    HwWorkoutTypeLeisureSports = 264, // 休闲运动，LS项目使用
    HwWorkoutTypeBreaststroke = 265, // 蛙泳，LS项目使用
    HwWorkoutTypeEllipticalMachine = 266, // 椭圆机，LS项目使用
    HwWorkoutTypeTriathlon = 267, // 铁人三项，LS项目使用
    HwWorkoutTypeJumpRope = 268, // 跳绳，LS项目使用
    HwWorkoutTypeParachute = 269, // 跳伞，LS项目使用
    HwWorkoutTypeAthletics = 270, // 田径，LS项目使用
    HwWorkoutTypeIndoorCycle = 271, // 室内骑行，LS项目使用
    HwWorkoutTypeIndoorRun = 272, // 室内跑步，LS项目使用
    HwWorkoutTypeIndoorWalk = 273, // 室内健走，LS项目使用
    HwWorkoutTypeIndoorFitness2 = 274, // 室内健身，LS项目使用
    HwWorkoutTypeRacing = 275, // 赛车，LS项目使用
    HwWorkoutTypeFlexibilityTraining2 = 276, // 柔韧训练，LS项目使用
    HwWorkoutTypeTRX = 277, // 全身抗阻力锻炼，LS项目使用
    HwWorkoutTypeTableTennis = 278, // 乒乓球，LS项目使用
    HwWorkoutTypeRafting = 279, // 漂流，LS项目使用
    HwWorkoutTypeKayak = 280, // 皮划艇，LS项目使用
    HwWorkoutTypeStairClimber = 281, // 爬楼机，LS项目使用
    HwWorkoutTypeJetSkiing = 282, // 摩托艇，LS项目使用
    HwWorkoutTypeEquestrian = 283, // 马术运动，LS项目使用
    HwWorkoutTypeStrengthTraining2 = 284, // 力量训练，LS项目使用
    HwWorkoutTypeLatin2 = 285, // 拉丁舞，LS项目使用
    HwWorkoutTypeSwimmingInOpenWaters = 286, // 开放水域游泳，LS项目使用
    HwWorkoutTypeJazz2 = 287, // 爵士舞，LS项目使用
    HwWorkoutTypeBallroomDance = 288, // 交谊舞，LS项目使用
    HwWorkoutTypeMixedTraining2 = 289, // 混合有氧，LS项目使用
    HwWorkoutTypeParaglider = 290, // 滑翔伞，LS项目使用
    HwWorkoutTypeWaterSkiing = 291, // 滑水，LS项目使用
    HwWorkoutTypeSpeedSkating = 292, // 滑冰，LS项目使用
    HwWorkoutTypeScooter = 293, // 滑板车，LS项目使用
    HwWorkoutTypeOutdoorCycle = 294, // 户外骑行，LS项目使用
    HwWorkoutTypeOutdoorRun = 295, // 户外跑步，LS项目使用
    HwWorkoutTypeOutdoorIceSkating2 = 296, // 户外溜冰，LS项目使用
    HwWorkoutTypeOutdoorWalk = 297, // 户外健走，LS项目使用
    HwWorkoutTypeSquareDance2 = 298, // 广场舞，LS项目使用
    HwWorkoutTypeButterflyStroke = 299, // 蝶泳，LS项目使用
    HwWorkoutTypeClimbing2 = 300, // 登山，LS项目使用
    HwWorkoutTypeBungee2 = 301, // 蹦极，LS项目使用
    HwWorkoutTypeBallet2 = 302, // 芭蕾舞，LS项目使用
};

@class HwWorkoutGpsPoint;
@interface HwWorkout : NSObject

/*! @brief
 索引[index]
 */
@property(nonatomic, assign) NSUInteger index;


/*! @brief
 时间点（毫秒级时间戳）[interval time, milli seconds]
 */
@property(nonatomic, assign) long startTime;

/*! @brief
 时间点（毫秒级时间戳）[interval time, milli seconds]
 */
@property(nonatomic, assign) long endTime;

/*! @brief
 Record the workout pause period
 */
@property(nonatomic, copy) NSArray *pausedTimeSections;

/*! @brief
 运动类型[workout type]
 */
@property(nonatomic, assign) HwWorkoutType type;

/*! @brief
 步数[step]
 */
@property(nonatomic, assign) NSUInteger step;
/*! @brief
 卡路里[calorie]
 */
@property(nonatomic, assign) NSUInteger calorie;
/*! @brief
 距离[distance]
 */
@property(nonatomic, assign) NSUInteger distance;
/*! @brief
 运动时间[integer duration]
 */
@property(nonatomic, assign) NSUInteger duration;

/*! @brief
 average heartRate bpm for this moment
 */
@property(nonatomic, assign) NSUInteger bpm;

@property(nonatomic, assign) NSUInteger maxBpm;
@property(nonatomic, assign) NSUInteger minBpm;

@property(nonatomic, assign) NSUInteger pace;            // 秒/千米
@property(nonatomic, assign) NSUInteger speed;           // 千米/小时
@property(nonatomic, assign) NSUInteger lapDuration;      // 一圈要多少分钟
@property(nonatomic, assign) NSUInteger cadence;            // 步频，步数/分钟

//多运动
@property(nonatomic, assign) NSUInteger warmUpDuration;   //多运动的
@property(nonatomic, assign) NSUInteger burningDuration;
@property(nonatomic, assign) NSUInteger aerobicDuration;
@property(nonatomic, assign) NSUInteger anaerobicDuration;
@property(nonatomic, assign) NSUInteger limitDuration;
@property(nonatomic, assign) NSUInteger restingDuration;

@property(nonatomic, assign) NSInteger elevationGain;
@property(nonatomic, assign) NSInteger elevationLoss;
@property(nonatomic, assign) NSInteger elevationNow;
@property(nonatomic, assign) NSUInteger actionCount;
@property(nonatomic, assign) NSUInteger swolf;
@property(nonatomic, assign) NSUInteger actionPosture;
@property(nonatomic, assign) NSUInteger laps;
@property(nonatomic, assign) NSUInteger actionRate;
@property(nonatomic, assign) NSUInteger maxConsecutiveActionCount;
@property(nonatomic, assign) NSUInteger interruptActionCount;
@property(nonatomic, assign) double actualDuration1; // 秒，拉桨时间保留小数
@property(nonatomic, assign) double actualDuration2; // 秒，回桨时间保留小数
@property(nonatomic, assign) NSUInteger actualDuration3;
@property(nonatomic, assign) NSUInteger aerobicTrainingEffect;
@property(nonatomic, assign) NSUInteger anaerobicTrainingEffect;
/**
 步幅，0.01米
 */
@property(nonatomic, assign) NSUInteger strike;
/**
 锻炼恢复时间
 */
@property(nonatomic, assign) NSUInteger recoveryTime;

@property(nonatomic, assign) NSUInteger poolLength;
/**
 最大摄氧量
 */
@property(nonatomic, assign) NSUInteger vo2max;
/**
 最大气压值
 */
@property(nonatomic, assign) NSInteger maxPressure;
/**
 最小气压
 */
@property(nonatomic, assign) NSInteger minPressure;
@property(nonatomic, assign) BOOL supportedNav;

@property(nonatomic, strong) NSArray<HwWorkoutPoint *> *workoutPoints;
@property(nonatomic, strong) NSArray<HwWorkoutGpsPoint *> *workoutGpsPoints;

- (HwWorkout *) initWithData:(NSData *)data;
- (HwWorkout *) initWithBigDataContent:(NSData *)bigDataContent;

+ (NSArray<HwWorkout *> *) workoutsFromBigDataContentV2:(NSData *)bigDataContent;

@end

NS_ASSUME_NONNULL_END
