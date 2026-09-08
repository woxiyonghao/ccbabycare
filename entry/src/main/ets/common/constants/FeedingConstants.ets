/**
 * 喂养、排泄、睡眠等业务枚举常量
 */

// 喂养方式
export enum FeedingType {
  FORMULA = 'FORMULA',             // 配方奶
  BREASTFEEDING = 'BREASTFEEDING', // 母乳亲喂
  BOTTLE = 'BOTTLE',               // 母乳瓶喂
  WATER = 'WATER',                 // 饮水
  SOLIDS = 'SOLIDS'                // 辅食
}

// 配方奶段位
export enum FormulaStage {
  STAGE_1 = '1段 (0-6个月)',
  STAGE_2 = '2段 (6-12个月)',
  STAGE_3 = '3段 (1-3岁)',
  STAGE_4 = '4段 (3岁以上)'
}

// 排泄类型
export enum EliminationType {
  PEE = 'PEE',                     // 嘘嘘（尿尿）
  POOP = 'POOP',                   // 便便
  MIXED = 'MIXED',                 // 混合（尿+便）
  DIAPER_ONLY = 'DIAPER_ONLY'      // 仅换尿布
}

// 便便性状
export enum StoolTexture {
  WATERY = '稀水便',
  PASTY = '糊状便',
  SOFT = '软便 (正常)',
  FORMED = '成形条状',
  HARD = '干硬便'
}

// 便便颜色
export enum StoolColor {
  GOLDEN = '金黄色',
  YELLOW_GREEN = '黄绿色',
  DARK_GREEN = '墨绿色',
  BROWN = '褐色',
  BLOOD_STREAK = '带血丝(异常)',
  ABNORMAL = '其他异常色'
}

// 排泄量级
export enum EliminationVolume {
  LOW = '少量',
  MEDIUM = '中量',
  HIGH = '多量'
}

// 睡眠类型
export enum SleepType {
  NAP = '白天小睡',
  NIGHT = '夜间睡眠'
}

// 入睡方式
export enum FallingAsleepMethod {
  SELF = '自主入睡',
  HOLDING = '抱睡/摇睡',
  NURSING = '奶睡',
  STROLLER = '推车/安抚'
}
