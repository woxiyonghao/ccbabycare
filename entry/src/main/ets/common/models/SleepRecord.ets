import { SleepType, FallingAsleepMethod } from '../constants/FeedingConstants';

/**
 * 睡眠记录实体
 */
export class SleepRecord {
  id: string = '';
  babyId: string = '';
  startTime: number = 0;              // 入睡时间戳
  endTime: number = 0;                // 醒来时间戳
  durationMinutes: number = 0;        // 自动计算睡眠分钟数
  sleepType: string = SleepType.NAP;  // NAP 白天小睡, NIGHT 夜间睡眠
  method: string = FallingAsleepMethod.SELF; // 自主 / 抱睡 / 奶睡 / 推车
  nightWakeCount: number = 0;         // 夜醒次数
  caregiverId: string = 'MOM';
  notes: string = '';
  createdAt: number = 0;

  constructor(
    id: string = '',
    babyId: string = '',
    startTime: number = Date.now(),
    endTime: number = Date.now(),
    durationMinutes: number = 0,
    caregiverId: string = 'MOM'
  ) {
    this.id = id;
    this.babyId = babyId;
    this.startTime = startTime;
    this.endTime = endTime;
    this.durationMinutes = durationMinutes;
    this.caregiverId = caregiverId;
    this.createdAt = Date.now();
  }
}
