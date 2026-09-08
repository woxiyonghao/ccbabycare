import { FeedingType, FormulaStage } from '../constants/FeedingConstants';

/**
 * 喂养记录实体（配方奶、母乳亲喂、母乳瓶喂、饮水、辅食）
 */
export class FeedingRecord {
  id: string = '';
  babyId: string = '';
  recordTime: number = 0;              // 喂食时间戳
  feedingType: string = FeedingType.FORMULA;
  amount: number = 0;                 // 核心喂食量：配方奶/瓶喂/饮水(ml)、亲喂(总分钟)、辅食(g/勺)
  amountUnit: string = 'ml';          // 'ml' | '分钟' | 'g' | '勺'

  // 配方奶专属字段
  formulaStage: string = FormulaStage.STAGE_1;
  scoops: number = 0;                 // 冲调勺数
  waterAmount: number = 0;            // 冲调用水量 (ml)

  // 母乳亲喂专属字段
  leftDuration: number = 0;           // 左侧亲喂时长 (分钟)
  rightDuration: number = 0;          // 右侧亲喂时长 (分钟)
  suckStatus: string = '正常';        // 正常 / 偏弱 / 急促

  // 母乳瓶喂专属字段
  milkSource: string = '亲喂泵出';    // 冷藏 / 冷冻 / 亲喂泵出

  // 辅食专属字段
  solidsName: string = '';            // 辅食名称（米粉、南瓜泥、蛋黄等）
  solidsIngredients: string = '';     // 食材明细
  isNewFood: number = 0;              // 1 首次添加新食材, 0 否
  hasAllergy: number = 0;             // 1 出现过敏反应, 0 无异常
  allergyNote: string = '';           // 过敏症状说明

  // 照护者与通用备注
  caregiverId: string = 'MOM';        // 照护者角色 (MOM, DAD, GRANDPARENT, NANNY)
  notes: string = '';                 // 拍嗝/吐奶/情绪等
  createdAt: number = 0;

  constructor(
    id: string = '',
    babyId: string = '',
    recordTime: number = Date.now(),
    feedingType: string = FeedingType.FORMULA,
    amount: number = 0,
    amountUnit: string = 'ml',
    caregiverId: string = 'MOM'
  ) {
    this.id = id;
    this.babyId = babyId;
    this.recordTime = recordTime;
    this.feedingType = feedingType;
    this.amount = amount;
    this.amountUnit = amountUnit;
    this.caregiverId = caregiverId;
    this.createdAt = Date.now();
  }
}
