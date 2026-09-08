/**
 * 萌宝喂养日记 · 全局常量定义
 */
export class AppConstants {
  // 数据库相关
  static readonly DB_NAME: string = 'ccbabycare.db';
  static readonly DB_VERSION: number = 1;

  // 表名
  static readonly TABLE_BABY: string = 'baby_table';
  static readonly TABLE_FEEDING: string = 'feeding_record_table';
  static readonly TABLE_ELIMINATION: string = 'elimination_record_table';
  static readonly TABLE_SLEEP: string = 'sleep_record_table';
  static readonly TABLE_VACCINE: string = 'vaccine_record_table';
  static readonly TABLE_GROWTH: string = 'growth_record_table';
  static readonly TABLE_EXPENSE: string = 'expense_record_table';
  static readonly TABLE_FORMULA_PROFILE: string = 'formula_profile_table';

  // 首选项 Key
  static readonly PREF_NAME: string = 'ccbabycare_pref';
  static readonly KEY_CURRENT_BABY_ID: string = 'current_baby_id';
  static readonly KEY_CURRENT_CAREGIVER: string = 'current_caregiver';
  static readonly KEY_ACTIVE_SLEEP_START_TIME: string = 'active_sleep_start_time';

  // 主题色系（手绘日记奶油暖色风）
  static readonly COLOR_PRIMARY: string = '#FF7B54';          // 活力蜜桃橙
  static readonly COLOR_PRIMARY_LIGHT: string = '#FFF2EE';    // 浅橙背景
  static readonly COLOR_PRIMARY_HOVER: string = '#FA6032';
  static readonly COLOR_SECONDARY: string = '#9376E0';        // 温馨紫
  static readonly COLOR_SECONDARY_LIGHT: string = '#F4F0FF';
  static readonly COLOR_BG_CREAM: string = '#FAF7F2';         // 日记本温润奶油底色
  static readonly COLOR_CARD_BG: string = '#FFFFFF';          // 白色卡片底色
  static readonly COLOR_TEXT_MAIN: string = '#2D3748';        // 主标题深墨灰
  static readonly COLOR_TEXT_MUTED: string = '#718096';       // 次要文字灰
  static readonly COLOR_BORDER: string = '#EBE5DF';           // 柔和边框色
  static readonly COLOR_SUCCESS: string = '#48BB78';          // 护眼绿
  static readonly COLOR_SUCCESS_LIGHT: string = '#E6FFFA';
  static readonly COLOR_WARNING: string = '#ED8936';          // 警示橙
  static readonly COLOR_DANGER: string = '#E53E3E';           // 异常醒目红
}
