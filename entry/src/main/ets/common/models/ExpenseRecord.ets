/**
 * 每月花销记账实体（参考图二手绘日记本 P34-P35 每月花销特色）
 */

export class ExpenseRecord {
  id: string = '';
  babyId: string = '';
  expenseDate: number = 0;             // 花费日期
  category: string = '奶粉配方';       // 奶粉配方 / 纸尿裤 / 辅食零食 / 衣服童鞋 / 玩具绘本 / 医疗疫苗 / 托育早教 / 其他
  amount: number = 0;                  // 金额 (元)
  notes: string = '';                  // 购买渠道、品牌规格等备注
  createdAt: number = 0;

  constructor(
    id: string = '',
    babyId: string = '',
    expenseDate: number = Date.now(),
    category: string = '奶粉配方',
    amount: number = 0,
    notes: string = ''
  ) {
    this.id = id;
    this.babyId = babyId;
    this.expenseDate = expenseDate;
    this.category = category;
    this.amount = amount;
    this.notes = notes;
    this.createdAt = Date.now();
  }

  static readonly CATEGORIES: string[] = [
    '奶粉配方',
    '纸尿裤',
    '辅食营养',
    '衣服童鞋',
    '玩具绘本',
    '医疗疫苗',
    '洗护喂哺',
    '其他开销'
  ];
}
