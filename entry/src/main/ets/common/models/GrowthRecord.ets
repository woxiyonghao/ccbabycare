/**
 * 成长记录实体（身高、体重、头围及2026标准评测结果）
 */
export class GrowthRecord {
  id: string = '';
  babyId: string = '';
  recordDate: number = 0;              // 测量日期时间戳
  monthAge: number = 0;                // 测量时的月龄
  height: number = 0;                  // 身高 (cm)
  weight: number = 0;                  // 体重 (kg)
  headCircumference: number = 0;       // 头围 (cm, 可选)

  // 2026儿童标准比对状态
  heightStatus: string = '正常';       // '偏矮' | '正常' | '偏高'
  weightStatus: string = '正常';       // '偏轻' | '正常' | '偏重'
  percentileText: string = '正常范围'; // P3 ~ P97 等评估结论

  measureLocation: string = '家庭测量';// 家庭测量 / 医院体检 / 社区体检
  caregiverId: string = 'MOM';
  notes: string = '';
  createdAt: number = 0;

  constructor(
    id: string = '',
    babyId: string = '',
    recordDate: number = Date.now(),
    height: number = 0,
    weight: number = 0,
    monthAge: number = 0
  ) {
    this.id = id;
    this.babyId = babyId;
    this.recordDate = recordDate;
    this.height = height;
    this.weight = weight;
    this.monthAge = monthAge;
    this.createdAt = Date.now();
  }
}
