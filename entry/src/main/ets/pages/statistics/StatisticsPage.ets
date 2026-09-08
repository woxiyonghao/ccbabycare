import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { BabyModel } from '../../common/models/BabyModel';
import { GrowthRecord } from '../../common/models/GrowthRecord';
import { GrowthStandard2026, GrowthStandardItem } from '../../common/constants/GrowthStandard2026';
import { GrowthEvaluator, EvaluationResult } from '../../common/utils/GrowthEvaluator';

/**
 * 统计与成长曲线页：结合2026儿童身高体重标准比对（图三）与喂养睡眠规律
 */
@Component
export struct StatisticsPage {
  @State currentBaby: BabyModel = new BabyModel();
  @State growthList: GrowthRecord[] = [];
  @State standardList: GrowthStandardItem[] = [];

  // 计算器模拟状态
  @State simMonthAge: number = 3;
  @State simWeight: string = '6.8';
  @State simHeight: string = '62.5';
  @State simResultText: string = '正常';
  @State simResultClass: boolean = true;

  aboutToAppear() {
    this.refreshData();
  }

  private refreshData() {
    const db = DatabaseHelper.getInstance();
    this.currentBaby = db.getCurrentBaby();
    this.growthList = db.getGrowthRecords();
    this.standardList = (this.currentBaby.gender === 'girl') ?
      GrowthStandard2026.GIRLS_STANDARDS :
      GrowthStandard2026.BOYS_STANDARDS;
    this.runSimCalc();
  }

  private runSimCalc() {
    const w = parseFloat(this.simWeight) || 0;
    const h = parseFloat(this.simHeight) || 0;
    const res: EvaluationResult = GrowthEvaluator.evaluate(
      this.currentBaby.gender,
      this.simMonthAge,
      h,
      w
    );
    this.simResultText = res.summaryText;
    this.simResultClass = res.isAllNormal;
  }

  build() {
    Column({ space: 14 }) {
      // 顶栏
      Row() {
        Text('📊 统计与生长曲线 (2026标准对照)')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
      }
      .width('94%')
      .padding({ top: 16, bottom: 4 })

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

          // 3. 2026 标准快速评测测算器
          Column({ space: 10 }) {
            Text('🔍 2026 发育达标测算器（输入即测）')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)

            Row({ space: 8 }) {
              TextInput({ placeholder: '体重 (kg)', text: this.simWeight })
                .type(InputType.Number)
                .layoutWeight(1)
                .onChange((v: string) => {
                  this.simWeight = v;
                  this.runSimCalc();
                })

              TextInput({ placeholder: '身高 (cm)', text: this.simHeight })
                .type(InputType.Number)
                .layoutWeight(1)
                .onChange((v: string) => {
                  this.simHeight = v;
                  this.runSimCalc();
                })
            }
            .width('100%')

            Row() {
              Text(this.simResultClass ? '✅ ' : '⚠️ ')
                .fontSize(14)
              Text(this.simResultText)
                .fontSize(12)
                .fontColor(this.simResultClass ? '#046C4E' : '#C81E1E')
                .layoutWeight(1)
            }
            .width('100%')
            .padding(10)
            .backgroundColor(this.simResultClass ? '#DEF7EC' : '#FDE8E8')
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
