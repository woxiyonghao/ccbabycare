/**
 * 宝宝档案实体与月龄换算
 */

export class BabyModel {
  id: string = '';
  name: string = '';
  birthday: number = 0;              // 毫秒时间戳
  gender: string = 'boy';            // 'boy' | 'girl'
  birthWeight: number = 0;           // kg
  birthHeight: number = 0;           // cm
  bloodType: string = '未知';        // A / B / AB / O / 未知
  avatar: string = '';               // 头像图标或本地图片
  notes: string = '';                // 备注
  isDefault: number = 1;             // 1 默认, 0 非默认
  createdAt: number = 0;

  constructor(
    id: string = '',
    name: string = '',
    birthday: number = 0,
    gender: string = 'boy',
    birthWeight: number = 0,
    birthHeight: number = 0,
    bloodType: string = '未知',
    avatar: string = '👶',
    notes: string = '',
    isDefault: number = 1,
    createdAt: number = Date.now()
  ) {
    this.id = id;
    this.name = name;
    this.birthday = birthday;
    this.gender = gender;
    this.birthWeight = birthWeight;
    this.birthHeight = birthHeight;
    this.bloodType = bloodType;
    this.avatar = avatar;
    this.notes = notes;
    this.isDefault = isDefault;
    this.createdAt = createdAt;
  }

  /**
   * 自动计算当前宝宝的月龄与天数表达（如"3个月15天"）
   */
  getAgeString(): string {
    if (this.birthday <= 0) {
      return '0月0天';
    }
    const now = new Date();
    const birth = new Date(this.birthday);

    let years = now.getFullYear() - birth.getFullYear();
    let months = now.getMonth() - birth.getMonth();
    let days = now.getDate() - birth.getDate();

    if (days < 0) {
      months -= 1;
      const prevMonthLastDay = new Date(now.getFullYear(), now.getMonth(), 0).getDate();
      days += prevMonthLastDay;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    const totalMonths = years * 12 + months;
    if (totalMonths === 0) {
      return `${Math.max(0, days)}天`;
    }
    if (years === 0) {
      return `${totalMonths}个月${days}天`;
    }
    return `${years}岁${months}个月${days}天`;
  }

  /**
   * 获取纯月龄数字（用于比对标准对照表）
   */
  getTotalMonthAge(): number {
    if (this.birthday <= 0) {
      return 0;
    }
    const now = new Date();
    const birth = new Date(this.birthday);
    const months = (now.getFullYear() - birth.getFullYear()) * 12 + (now.getMonth() - birth.getMonth());
    return Math.max(0, months);
  }
}
