import { GrowthStandard2026, GrowthStandardItem } from '../constants/GrowthStandard2026';

export interface EvaluationResult {
  heightStatus: string;       // '偏矮' | '正常' | '偏高'
  weightStatus: string;       // '偏轻' | '正常' | '偏重'
  standardItem: GrowthStandardItem;
  summaryText: string;
  isAllNormal: boolean;
}

/**
 * 2026儿童生长标准评测算法
 */
export class GrowthEvaluator {
  static evaluate(gender: string, monthAge: number, height: number, weight: number): EvaluationResult {
    const standard = GrowthStandard2026.findStandard(gender, monthAge);

    let heightStatus = '正常';
    if (height > 0) {
      if (height < standard.heightMin) {
        heightStatus = '偏矮';
      } else if (height > standard.heightMax) {
        heightStatus = '偏高';
      }
    }

    let weightStatus = '正常';
    if (weight > 0) {
      if (weight < standard.weightMin) {
        weightStatus = '偏轻';
      } else if (weight > standard.weightMax) {
        weightStatus = '偏重';
      }
    }

    const isAllNormal = (heightStatus === '正常') && (weightStatus === '正常');

    let summaryText = '';
    if (isAllNormal) {
      summaryText = `身高、体重均在${standard.ageLabel}的2026标准正常参考范围内`;
    } else {
      const parts: string[] = [];
      if (heightStatus !== '正常') {
        parts.push(`身高${heightStatus}(参考${standard.heightMin}~${standard.heightMax}cm)`);
      }
      if (weightStatus !== '正常') {
        parts.push(`体重${weightStatus}(参考${standard.weightMin}~${standard.weightMax}kg)`);
      }
      summaryText = `对照提示：${parts.join('，')}`;
    }

    return {
      heightStatus,
      weightStatus,
      standardItem: standard,
      summaryText,
      isAllNormal
    };
  }
}
