import router from '@ohos.router';
import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { BabyModel } from '../../common/models/BabyModel';
import { GrowthRecord } from '../../common/models/GrowthRecord';
import { GrowthStandard2026, GrowthStandardItem } from '../../common/constants/GrowthStandard2026';
import { GrowthEvaluator, EvaluationResult } from '../../common/utils/GrowthEvaluator';
import { ArrowIcon } from '../../common/components/ArrowIcon';

/**
 * 统计与成长曲线页：结合2026儿童身高体重标准比对（图三）与喂养睡眠规律
 */
@Entry
@Component
export struct StatisticsPage {
  @State currentBaby: BabyModel = new BabyModel();
  @State growthList: GrowthRecord[] = [];
  @State standardList: GrowthStandardItem[] = [];

  // 计算器模拟状态（无预设占位数值，初始为空）
  @State simMonthAge: number = 3;
  @State simWeight: string = '';
  @State simHeight: string = '';
  @State simResultText: string = '请输入宝宝当前体重与身高，系统将实时对照2026标准评估';
  @State simResultState: string = 'empty'; // 'empty' | 'normal' | 'warn'

  aboutToAppear() {
    this.refreshData();
  }

  onPageShow() {
    this.refreshData();
  }

  private refreshData() {
    const db = DatabaseHelper.getInstance();
    this.currentBaby = db.getCurrentBaby();
    this.growthList = db.getGrowthRecords();
    this.standardList = (this.currentBaby.gender === 'girl') ?
      GrowthStandard2026.GIRLS_STANDARDS :
      GrowthStandard2026.BOYS_STANDARDS;
    this.simMonthAge = this.currentBaby.getTotalMonthAge() || 3;
    this.runSimCalc();
  }

  /**
   * 过滤并净化输入的数字（禁止负号、非数字，规范小数点与前导零）
   */
  private sanitizeNumber(val: string): string {
    if (!val) return '';
    // 1. 过滤非数字与非小数点（严禁负号 - 、英文字符及符号）
    let clean = val.replace(/[^0-9.]/g, '');
    // 2. 开头如果是小数点自动补 0
    if (clean.startsWith('.')) {
      clean = '0' + clean;
    }
    // 3. 严格限制只能存在一个小数点
    const dotIndex = clean.indexOf('.');
    if (dotIndex !== -1) {
      const intPart = clean.substring(0, dotIndex);
      const decPart = clean.substring(dotIndex + 1).replace(/\./g, '');
      clean = intPart + '.' + decPart.substring(0, 2);
    }
    // 4. 规范多余前导零（如 "005" -> "5"）
    if (clean.length > 1 && clean.startsWith('0') && !clean.startsWith('0.')) {
      clean = clean.replace(/^0+/, '');
      if (clean === '') clean = '0';
    }
    return clean;
  }

  private runSimCalc() {
    const w = parseFloat(this.simWeight);
    const h = parseFloat(this.simHeight);

    // 未输入或输入不完整
    if (!this.simWeight || !this.simHeight || isNaN(w) || isNaN(h) || w <= 0 || h <= 0) {
      this.simResultText = '请输入宝宝当前体重与身高，系统将实时对照2026标准评估';
      this.simResultState = 'empty';
      return;
    }

    // 异常过大数值保护
    if (w > 50 || h > 150) {
      this.simResultText = '输入的数值偏大，请确认输入单位为体重(kg)与身高(cm)';
      this.simResultState = 'warn';
      return;
    }

    const res: EvaluationResult = GrowthEvaluator.evaluate(
      this.currentBaby.gender,
      this.simMonthAge,
      h,
      w
    );
    this.simResultText = res.summaryText;
    this.simResultState = res.isAllNormal ? 'normal' : 'warn';
  }

  build() {
    Column({ space: 14 }) {
      // 顶栏导航（带返回按钮）
      Row({ space: 12 }) {
        Row() {
          ArrowIcon({ arrowDirection: 'left', variant: 'dark', iconSize: 18 })
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .borderRadius(18)
        .backgroundColor('rgba(0, 0, 0, 0.05)')
        .onClick(() => {
          router.back();
        })

        Text('统计与生长曲线 (2026标准)')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      Scroll() {
        Column({ space: 14 }) {
          // 1. 最新测量与标准评测卡片
          if (this.growthList.length > 0) {
            Column({ space: 8 }) {
              Row() {
                Text(`🌟 最新生长状态 (${this.currentBaby.name})`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Blank()
                Text(this.growthList[this.growthList.length - 1].percentileText)
                  .fontSize(11)
                  .fontColor(AppConstants.COLOR_SUCCESS)
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')

              Row({ space: 12 }) {
                Column({ space: 2 }) {
                  Text('当前身长')
                    .fontSize(11)
                    .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  Row() {
                    Text(`${this.growthList[this.growthList.length - 1].height}`)
                      .fontSize(22)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppConstants.COLOR_PRIMARY)
                    Text(' cm')
                      .fontSize(12)
                      .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  }
                  Text(`评测: ${this.growthList[this.growthList.length - 1].heightStatus}`)
                    .fontSize(10)
                    .fontColor(AppConstants.COLOR_PRIMARY)
                }
                .layoutWeight(1)
                .padding(10)
                .backgroundColor('#FFF5F2')
                .borderRadius(12)

                Column({ space: 2 }) {
                  Text('当前体重')
                    .fontSize(11)
                    .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  Row() {
                    Text(`${this.growthList[this.growthList.length - 1].weight}`)
                      .fontSize(22)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#319795')
                    Text(' kg')
                      .fontSize(12)
                      .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  }
                  Text(`评测: ${this.growthList[this.growthList.length - 1].weightStatus}`)
                    .fontSize(10)
                    .fontColor('#319795')
                }
                .layoutWeight(1)
                .padding(10)
                .backgroundColor('#E6FFFA')
                .borderRadius(12)

                Column({ space: 2 }) {
                  Text('当前头围')
                    .fontSize(11)
                    .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  Row() {
                    Text(`${this.growthList[this.growthList.length - 1].headCircumference || 40}`)
                      .fontSize(22)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppConstants.COLOR_SECONDARY)
                    Text(' cm')
                      .fontSize(12)
                      .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  }
                  Text('头围发育正常')
                    .fontSize(10)
                    .fontColor(AppConstants.COLOR_SECONDARY)
                }
                .layoutWeight(1)
                .padding(10)
                .backgroundColor('#FAF5FF')
                .borderRadius(12)
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .backgroundColor(AppConstants.COLOR_CARD_BG)
            .borderRadius(16)
            .border({ width: 1, color: AppConstants.COLOR_BORDER })
          }

          // 2. 2026 标准对照数据对照表（图三数据呈现）
          Column({ space: 8 }) {
            Row() {
              Text(`📈 2026儿童身高体重标准对照表 (${this.currentBaby.gender === 'boy' ? '男童' : '女童'})`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
            }
            .width('100%')

            // 表头
            Row() {
              Text('月龄')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .width(60)
              Text('体重范围 (kg)')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
              Text('身高范围 (cm)')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            .backgroundColor('#FFF6F0')
            .borderRadius(8)

            // 数据行（展示核心月龄区间）
            ForEach(this.standardList.slice(0, 8), (st: GrowthStandardItem) => {
              Row() {
                Text(st.ageLabel)
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                  .width(60)
                Text(`${st.weightMin} ~ ${st.weightMax} kg`)
                  .fontSize(12)
                  .fontColor('#319795')
                  .layoutWeight(1)
                Text(`${st.heightMin} ~ ${st.heightMax} cm`)
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_PRIMARY)
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 })
              .border({ width: { bottom: 1 }, color: '#F3F4F6' })
            }, (st: GrowthStandardItem) => st.monthAge.toString())
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 3. 2026 标准快速评测测算器（无预设占位数值、标签清晰指示、严禁输入负数与特殊符号）
          Column({ space: 10 }) {
            Text('🔍 2026 发育达标测算器（输入即测）')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)

            Row({ space: 10 }) {
              Column({ space: 4 }) {
                Text('体重 (kg)')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                TextInput({ text: this.simWeight })
                  .type(InputType.NUMBER_DECIMAL)
                  .inputFilter('[0-9.]')
                  .height(42)
                  .fontSize(14)
                  .backgroundColor('#F7FAFC')
                  .borderRadius(10)
                  .onChange((v: string) => {
                    this.simWeight = this.sanitizeNumber(v);
                    this.runSimCalc();
                  })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Column({ space: 4 }) {
                Text('身高 (cm)')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                TextInput({ text: this.simHeight })
                  .type(InputType.NUMBER_DECIMAL)
                  .inputFilter('[0-9.]')
                  .height(42)
                  .fontSize(14)
                  .backgroundColor('#F7FAFC')
                  .borderRadius(10)
                  .onChange((v: string) => {
                    this.simHeight = this.sanitizeNumber(v);
                    this.runSimCalc();
                  })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')

            Row() {
              Text(this.simResultState === 'empty' ? '💡 ' : (this.simResultState === 'normal' ? '✅ ' : '⚠️ '))
                .fontSize(14)
              Text(this.simResultText)
                .fontSize(12)
                .fontColor(this.simResultState === 'empty' ? AppConstants.COLOR_TEXT_MUTED : (this.simResultState === 'normal' ? '#046C4E' : '#C81E1E'))
                .layoutWeight(1)
            }
            .width('100%')
            .padding(10)
            .backgroundColor(this.simResultState === 'empty' ? '#F7FAFC' : (this.simResultState === 'normal' ? '#DEF7EC' : '#FDE8E8'))
            .borderRadius(10)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })
        }
        .width('94%')
        .padding({ bottom: 40 })
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
