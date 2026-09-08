import { FormulaStage } from '../constants/FeedingConstants';

/**
 * 奶粉库实体（预存奶粉段位、冲调水粉比例与默认奶量）
 */
export class FormulaProfile {
  id: string = '';
  stage: string = FormulaStage.STAGE_1;
  waterPerScoop: number = 30;           // 每勺对应水量 (ml)，默认 30ml / 50ml
  defaultAmount: number = 120;          // 常用快捷喂养奶量 (ml)
  brandName: string = '';               // 奶粉品牌备注
  isDefault: number = 1;

  constructor(
    id: string = '',
    stage: string = FormulaStage.STAGE_1,
    waterPerScoop: number = 30,
    defaultAmount: number = 120,
    brandName: string = '',
    isDefault: number = 1
  ) {
    this.id = id;
    this.stage = stage;
    this.waterPerScoop = waterPerScoop;
    this.defaultAmount = defaultAmount;
    this.brandName = brandName;
    this.isDefault = isDefault;
  }
}
