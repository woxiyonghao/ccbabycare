/**
 * 疫苗接种实体与国家免疫规划推荐表
 */

export interface VaccinePresetItem {
  name: string;
  monthAge: number;
  monthLabel: string;
  dose: string;
  isFree: boolean;
  desc: string;
}

export class VaccineRecord {
  id: string = '';
  babyId: string = '';
  vaccineName: string = '';
  monthLabel: string = '';
  dose: string = '第1针';               // 第1针 / 第2针 / 第3针 / 加强针
  isDone: number = 0;                  // 1 已接种, 0 待接种
  vaccinatedDate: number = 0;          // 接种日期
  organization: string = '';           // 接种机构/社区卫生服务中心
  batchNumber: string = '';            // 疫苗批号
  isFree: number = 1;                  // 1 一类免费, 0 二类自费
  adverseReaction: string = '';        // 发热、局部红肿等不良反应
  reminderDate: number = 0;            // 下次接种提醒日期
  notes: string = '';
  createdAt: number = 0;

  constructor(
    id: string = '',
    babyId: string = '',
    vaccineName: string = '',
    dose: string = '第1针',
    monthLabel: string = ''
  ) {
    this.id = id;
    this.babyId = babyId;
    this.vaccineName = vaccineName;
    this.dose = dose;
    this.monthLabel = monthLabel;
    this.createdAt = Date.now();
  }

  /**
   * 国家免疫规划常用疫苗基准清单
   */
  static readonly PRESET_VACCINES: VaccinePresetItem[] = [
    { name: '乙肝疫苗', monthAge: 0, monthLabel: '0月(出生24h内)', dose: '第1针', isFree: true, desc: '预防乙型病毒性肝炎' },
    { name: '卡介苗', monthAge: 0, monthLabel: '0月(出生24h内)', dose: '第1针', isFree: true, desc: '预防结核病' },
    { name: '乙肝疫苗', monthAge: 1, monthLabel: '1月龄', dose: '第2针', isFree: true, desc: '预防乙型肝炎第2剂' },
    { name: '脊髓灰质炎疫苗', monthAge: 2, monthLabel: '2月龄', dose: '第1针', isFree: true, desc: '预防小儿麻痹症' },
    { name: '脊髓灰质炎疫苗', monthAge: 3, monthLabel: '3月龄', dose: '第2针', isFree: true, desc: '预防小儿麻痹症' },
    { name: '百白破疫苗', monthAge: 3, monthLabel: '3月龄', dose: '第1针', isFree: true, desc: '预防百日咳、白喉、破伤风' },
    { name: '百白破疫苗', monthAge: 4, monthLabel: '4月龄', dose: '第2针', isFree: true, desc: '预防百日咳、白喉、破伤风' },
    { name: '百白破疫苗', monthAge: 5, monthLabel: '5月龄', dose: '第3针', isFree: true, desc: '预防百白破第3剂' },
    { name: '乙肝疫苗', monthAge: 6, monthLabel: '6月龄', dose: '第3针', isFree: true, desc: '预防乙型肝炎第3剂' },
    { name: 'A群流脑疫苗', monthAge: 6, monthLabel: '6月龄', dose: '第1针', isFree: true, desc: '预防流行性脑脊髓膜炎' },
    { name: '麻腮风疫苗', monthAge: 8, monthLabel: '8月龄', dose: '第1针', isFree: true, desc: '预防麻疹、风疹、腮腺炎' },
    { name: '乙脑减毒活疫苗', monthAge: 8, monthLabel: '8月龄', dose: '第1针', isFree: true, desc: '预防流行性乙型脑炎' },
    { name: '百白破加强疫苗', monthAge: 18, monthLabel: '18月龄', dose: '加强针', isFree: true, desc: '百白破加强免疫' },
    { name: '水痘疫苗(自费推荐)', monthAge: 12, monthLabel: '12月龄', dose: '第1针', isFree: false, desc: '预防小儿水痘感染' }
  ];
}
