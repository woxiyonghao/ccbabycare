/**
 * 2026儿童身高体重标准对照数据字典（依据卫生行业标准与图三权威数据表）
 */

export interface GrowthStandardItem {
  monthAge: number;        // 月龄（0月、1月...12月、18月、24月...78月）
  ageLabel: string;        // 年龄标签，如"3月"、"1岁"、"1岁半"
  weightMin: number;       // 正常体重下限 (kg)
  weightMax: number;       // 正常体重上限 (kg)
  heightMin: number;       // 正常身高下限 (cm)
  heightMax: number;       // 正常身高上限 (cm)
}

export class GrowthStandard2026 {
  // 男孩标准
  static readonly BOYS_STANDARDS: GrowthStandardItem[] = [
    { monthAge: 0, ageLabel: '0月 (出生)', weightMin: 2.8, weightMax: 4.2, heightMin: 47.6, heightMax: 54.8 },
    { monthAge: 1, ageLabel: '1月', weightMin: 3.7, weightMax: 5.6, heightMin: 51.3, heightMax: 59.0 },
    { monthAge: 2, ageLabel: '2月', weightMin: 4.7, weightMax: 7.1, heightMin: 54.9, heightMax: 63.0 },
    { monthAge: 3, ageLabel: '3月', weightMin: 5.5, weightMax: 8.3, heightMin: 58.0, heightMax: 66.4 },
    { monthAge: 4, ageLabel: '4月', weightMin: 6.1, weightMax: 9.2, heightMin: 60.5, heightMax: 69.1 },
    { monthAge: 5, ageLabel: '5月', weightMin: 6.6, weightMax: 9.8, heightMin: 62.5, heightMax: 71.3 },
    { monthAge: 6, ageLabel: '6月', weightMin: 6.9, weightMax: 10.3, heightMin: 64.2, heightMax: 73.2 },
    { monthAge: 7, ageLabel: '7月', weightMin: 7.2, weightMax: 10.8, heightMin: 65.7, heightMax: 74.9 },
    { monthAge: 8, ageLabel: '8月', weightMin: 7.5, weightMax: 11.1, heightMin: 67.1, heightMax: 76.4 },
    { monthAge: 9, ageLabel: '9月', weightMin: 7.7, weightMax: 11.5, heightMin: 68.3, heightMax: 77.8 },
    { monthAge: 10, ageLabel: '10月', weightMin: 7.9, weightMax: 11.8, heightMin: 69.5, heightMax: 79.1 },
    { monthAge: 11, ageLabel: '11月', weightMin: 8.1, weightMax: 12.0, heightMin: 70.7, heightMax: 80.3 },
    { monthAge: 12, ageLabel: '1岁', weightMin: 8.3, weightMax: 12.3, heightMin: 71.7, heightMax: 81.6 },
    { monthAge: 18, ageLabel: '1岁半', weightMin: 9.3, weightMax: 13.8, heightMin: 77.7, heightMax: 88.5 },
    { monthAge: 24, ageLabel: '2岁', weightMin: 10.4, weightMax: 15.4, heightMin: 82.4, heightMax: 94.0 },
    { monthAge: 30, ageLabel: '2岁半', weightMin: 11.2, weightMax: 16.7, heightMin: 87.0, heightMax: 99.4 },
    { monthAge: 36, ageLabel: '3岁', weightMin: 12.0, weightMax: 18.5, heightMin: 90.9, heightMax: 104.1 },
    { monthAge: 42, ageLabel: '3岁半', weightMin: 12.8, weightMax: 19.4, heightMin: 94.4, heightMax: 108.3 },
    { monthAge: 48, ageLabel: '4岁', weightMin: 13.6, weightMax: 20.8, heightMin: 97.6, heightMax: 112.2 },
    { monthAge: 54, ageLabel: '4岁半', weightMin: 14.5, weightMax: 22.4, heightMin: 100.8, heightMax: 116.0 },
    { monthAge: 60, ageLabel: '5岁', weightMin: 15.3, weightMax: 24.2, heightMin: 104.1, heightMax: 119.9 },
    { monthAge: 66, ageLabel: '5岁半', weightMin: 16.2, weightMax: 26.0, heightMin: 107.2, heightMax: 123.7 },
    { monthAge: 72, ageLabel: '6岁', weightMin: 17.1, weightMax: 27.9, heightMin: 110.3, heightMax: 127.3 },
    { monthAge: 78, ageLabel: '6岁半', weightMin: 17.8, weightMax: 29.8, heightMin: 113.1, heightMax: 130.9 }
  ];

  // 女孩标准
  static readonly GIRLS_STANDARDS: GrowthStandardItem[] = [
    { monthAge: 0, ageLabel: '0月 (出生)', weightMin: 2.7, weightMax: 4.1, heightMin: 46.8, heightMax: 53.8 },
    { monthAge: 1, ageLabel: '1月', weightMin: 3.5, weightMax: 5.3, heightMin: 50.4, heightMax: 57.8 },
    { monthAge: 2, ageLabel: '2月', weightMin: 4.4, weightMax: 6.6, heightMin: 53.8, heightMax: 61.8 },
    { monthAge: 3, ageLabel: '3月', weightMin: 5.1, weightMax: 7.6, heightMin: 56.7, heightMax: 64.8 },
    { monthAge: 4, ageLabel: '4月', weightMin: 5.6, weightMax: 8.4, heightMin: 59.1, heightMax: 67.4 },
    { monthAge: 5, ageLabel: '5月', weightMin: 6.0, weightMax: 9.1, heightMin: 61.0, heightMax: 69.6 },
    { monthAge: 6, ageLabel: '6月', weightMin: 6.4, weightMax: 9.6, heightMin: 62.7, heightMax: 71.5 },
    { monthAge: 7, ageLabel: '7月', weightMin: 6.7, weightMax: 10.0, heightMin: 64.2, heightMax: 73.1 },
    { monthAge: 8, ageLabel: '8月', weightMin: 6.9, weightMax: 10.4, heightMin: 65.6, heightMax: 74.7 },
    { monthAge: 9, ageLabel: '9月', weightMin: 7.2, weightMax: 10.8, heightMin: 66.8, heightMax: 76.1 },
    { monthAge: 10, ageLabel: '10月', weightMin: 7.4, weightMax: 11.1, heightMin: 68.1, heightMax: 77.5 },
    { monthAge: 11, ageLabel: '11月', weightMin: 7.6, weightMax: 11.4, heightMin: 69.2, heightMax: 78.8 },
    { monthAge: 12, ageLabel: '1岁', weightMin: 7.7, weightMax: 11.6, heightMin: 70.4, heightMax: 80.1 },
    { monthAge: 18, ageLabel: '1岁半', weightMin: 8.8, weightMax: 13.2, heightMin: 76.5, heightMax: 87.2 },
    { monthAge: 24, ageLabel: '2岁', weightMin: 9.8, weightMax: 14.8, heightMin: 81.3, heightMax: 92.8 },
    { monthAge: 30, ageLabel: '2岁半', weightMin: 10.7, weightMax: 16.2, heightMin: 85.7, heightMax: 98.1 },
    { monthAge: 36, ageLabel: '3岁', weightMin: 11.5, weightMax: 17.7, heightMin: 89.7, heightMax: 102.7 },
    { monthAge: 42, ageLabel: '3岁半', weightMin: 12.5, weightMax: 19.1, heightMin: 93.2, heightMax: 106.9 },
    { monthAge: 48, ageLabel: '4岁', weightMin: 13.1, weightMax: 20.5, heightMin: 96.5, heightMax: 110.9 },
    { monthAge: 54, ageLabel: '4岁半', weightMin: 13.9, weightMax: 21.9, heightMin: 99.7, heightMax: 114.7 },
    { monthAge: 60, ageLabel: '5岁', weightMin: 14.7, weightMax: 23.4, heightMin: 103.0, heightMax: 118.6 },
    { monthAge: 66, ageLabel: '5岁半', weightMin: 15.5, weightMax: 25.1, heightMin: 106.1, heightMax: 122.4 },
    { monthAge: 72, ageLabel: '6岁', weightMin: 16.3, weightMax: 26.8, heightMin: 109.0, heightMax: 126.0 },
    { monthAge: 78, ageLabel: '6岁半', weightMin: 17.0, weightMax: 28.5, heightMin: 111.8, heightMax: 129.4 }
  ];

  /**
   * 根据性别和月龄匹配最接近的标准区间
   */
  static findStandard(gender: string, monthAge: number): GrowthStandardItem {
    const list = (gender === 'girl' || gender === '女') ? GrowthStandard2026.GIRLS_STANDARDS : GrowthStandard2026.BOYS_STANDARDS;
    let closest = list[0];
    let minDiff = Math.abs(closest.monthAge - monthAge);

    for (let i = 1; i < list.length; i++) {
      const diff = Math.abs(list[i].monthAge - monthAge);
      if (diff < minDiff) {
        minDiff = diff;
        closest = list[i];
      }
    }
    return closest;
  }
}
