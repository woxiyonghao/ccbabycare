import { EliminationType, StoolTexture, StoolColor, EliminationVolume } from '../constants/FeedingConstants';

/**
 * 排泄与换尿布记录实体
 */
export class EliminationRecord {
  id: string = '';
  babyId: string = '';
  recordTime: number = 0;
  eliminationType: string = EliminationType.POOP; // PEE, POOP, MIXED, DIAPER_ONLY
  stoolTexture: string = StoolTexture.SOFT;
  stoolColor: string = StoolColor.GOLDEN;
  volume: string = EliminationVolume.MEDIUM;
  isAbnormal: number = 0;                         // 1 标记异常（红点提醒）, 0 正常
  abnormalNotes: string = '';                     // 黏液、泡沫、血丝等
  caregiverId: string = 'MOM';                    // 照护者角色
  notes: string = '';
  createdAt: number = 0;

  constructor(
    id: string = '',
    babyId: string = '',
    recordTime: number = Date.now(),
    eliminationType: string = EliminationType.POOP,
    caregiverId: string = 'MOM'
  ) {
    this.id = id;
    this.babyId = babyId;
    this.recordTime = recordTime;
    this.eliminationType = eliminationType;
    this.caregiverId = caregiverId;
    this.createdAt = Date.now();
  }
}
