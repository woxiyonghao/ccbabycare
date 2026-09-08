import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { FeedingRecordDialog } from './FeedingRecordDialog';
import { EliminationRecordDialog } from './EliminationRecordDialog';
import { SleepRecordDialog } from './SleepRecordDialog';
import { GrowthRecordDialog } from './GrowthRecordDialog';
import { VaccineRecord } from '../../common/models/VaccineRecord';

/**
 * 记录中心页：聚合喂养、排便、睡眠、成长、疫苗全分类记录
 */
@Component
export struct RecordHubPage {
  @State vaccineList: VaccineRecord[] = [];

  private feedingDialog: CustomDialogController = new CustomDialogController({
    builder: FeedingRecordDialog(),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    customStyle: true
  });

  private elimDialog: CustomDialogController = new CustomDialogController({
    builder: EliminationRecordDialog(),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    customStyle: true
  });

  private sleepDialog: CustomDialogController = new CustomDialogController({
    builder: SleepRecordDialog(),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    customStyle: true
  });

  private growthDialog: CustomDialogController = new CustomDialogController({
    builder: GrowthRecordDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear() {
    this.refreshVaccines();
  }

  private refreshVaccines() {
    const db = DatabaseHelper.getInstance();
    this.vaccineList = db.getVaccineRecords();
  }

  build() {
    Column({ space: 14 }) {
      // 顶栏
      Row() {
        Text('📝 记录中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
        Blank()
        Text('全部分类')
          .fontSize(13)
          .fontColor(AppConstants.COLOR_PRIMARY)
      }
      .width('94%')
      .padding({ top: 16, bottom: 8 })

      // 四大核心卡片快捷录入区
      Grid() {
        GridItem() {
          Column({ space: 8 }) {
            Text('🍼')
              .fontSize(28)
            Text('喂养记录')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
            Text('配方奶/母乳/辅食')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFF5F2')
          .borderRadius(16)
          .onClick(() => this.feedingDialog.open())
        }

        GridItem() {
          Column({ space: 8 }) {
            Text('💩')
              .fontSize(28)
            Text('排便排尿')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
            Text('性状颜色/异常标记')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#E6FFFA')
          .borderRadius(16)
          .onClick(() => this.elimDialog.open())
        }

        GridItem() {
          Column({ space: 8 }) {
            Text('🌙')
              .fontSize(28)
            Text('睡眠记录')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
            Text('小睡/夜长觉/夜醒')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FAF5FF')
          .borderRadius(16)
          .onClick(() => this.sleepDialog.open())
        }

        GridItem() {
          Column({ space: 8 }) {
            Text('📈')
              .fontSize(28)
            Text('成长体检')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
            Text('2026标准实时比对')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#EBF8FF')
          .borderRadius(16)
          .onClick(() => this.growthDialog.open())
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('94%')
      .height(210)

      // 疫苗免疫规划专区
      Row() {
        Text('💉 国家免疫规划疫苗档案')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
        Blank()
        Text('已接种/待接种')
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
      }
      .width('94%')
      .margin({ top: 8 })

      List({ space: 8 }) {
        ForEach(this.vaccineList, (item: VaccineRecord) => {
          ListItem() {
            Row({ space: 10 }) {
              Checkbox()
                .select(item.isDone === 1)
                .selectedColor(AppConstants.COLOR_SUCCESS)
                .onChange((checked: boolean) => {
                  const db = DatabaseHelper.getInstance();
                  db.updateVaccineStatus(item.id, checked ? 1 : 0, Date.now());
                  this.refreshVaccines();
                })

              Column({ space: 2 }) {
                Row({ space: 6 }) {
                  Text(item.vaccineName)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLOR_TEXT_MAIN)
                  Text(item.dose)
                    .fontSize(11)
                    .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                    .backgroundColor('#F3F4F6')
                    .borderRadius(6)
                  if (item.isFree === 1) {
                    Text('免费一类')
                      .fontSize(10)
                      .fontColor(AppConstants.COLOR_SUCCESS)
                  }
                }
                Text(`推荐月龄: ${item.monthLabel}`)
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(item.isDone === 1 ? '✅ 已接种' : '⏳ 待接种')
                .fontSize(12)
                .fontColor(item.isDone === 1 ? AppConstants.COLOR_SUCCESS : AppConstants.COLOR_WARNING)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(AppConstants.COLOR_CARD_BG)
            .borderRadius(14)
            .border({ width: 1, color: AppConstants.COLOR_BORDER })
          }
        }, (item: VaccineRecord) => item.id)
      }
      .width('94%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
