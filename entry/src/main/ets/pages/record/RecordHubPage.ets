import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { RecordCategoryItem, getCategoryByKey } from '../../common/models/RecordCategoryItem';
import { FeedingRecordDialog } from './FeedingRecordDialog';
import { EliminationRecordDialog } from './EliminationRecordDialog';
import { SleepRecordDialog } from './SleepRecordDialog';
import { GrowthRecordDialog } from './GrowthRecordDialog';
import { AllCategoriesDialog } from './AllCategoriesDialog';
import { AddExpenseDialog } from '../diary/AddExpenseDialog';
import { AddRoutineDialog } from '../diary/AddRoutineDialog';
import { AddParentsMessageDialog } from '../diary/AddParentsMessageDialog';
import { VaccineRecord } from '../../common/models/VaccineRecord';

/**
 * 记录中心页：聚合喂养、排便、睡眠、成长、疫苗全分类记录与快捷记录中心
 */
@Component
export struct RecordHubPage {
  @State vaccineList: VaccineRecord[] = [];
  @State selectedVaccineFilter: number = 0; // 0 全部, 1 待接种, 2 已接种
  @State topCategories: RecordCategoryItem[] = [];
  @StorageProp('APP_REFRESH_TRIGGER') @Watch('refreshVaccines') refreshTrigger: number = 0;
  @StorageProp('CATEGORY_ORDER_TRIGGER') @Watch('refreshTopCategories') categoryOrderTrigger: number = 0;

  // 1. 喂养记录弹窗
  private feedingDialog: CustomDialogController = new CustomDialogController({
    builder: FeedingRecordDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 2. 排便排尿记录弹窗
  private elimDialog: CustomDialogController = new CustomDialogController({
    builder: EliminationRecordDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 3. 睡眠记录弹窗
  private sleepDialog: CustomDialogController = new CustomDialogController({
    builder: SleepRecordDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 4. 成长体检弹窗
  private growthDialog: CustomDialogController = new CustomDialogController({
    builder: GrowthRecordDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 5. 养娃账本弹窗
  private expenseDialog: CustomDialogController = new CustomDialogController({
    builder: AddExpenseDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 6. 规律作息弹窗
  private routineDialog: CustomDialogController = new CustomDialogController({
    builder: AddRoutineDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 7. 父母寄语弹窗
  private messageDialog: CustomDialogController = new CustomDialogController({
    builder: AddParentsMessageDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 8. 全部分类面板弹窗
  private allCategoriesDialog: CustomDialogController = new CustomDialogController({
    builder: AllCategoriesDialog({
      onSelectCategory: (key: string) => {
        this.handleSelectCategory(key);
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear() {
    this.refreshVaccines();
    this.refreshTopCategories();
  }

  private refreshTopCategories() {
    const db = DatabaseHelper.getInstance();
    const order = db.getCategoryOrder();
    this.topCategories = order.slice(0, 4).map(k => getCategoryByKey(k));
  }

  private refreshVaccines() {
    const db = DatabaseHelper.getInstance();
    this.vaccineList = db.getVaccineRecords();
  }

  private handleSelectCategory(key: string): void {
    if (key === 'feeding') {
      this.feedingDialog.open();
    } else if (key === 'elimination') {
      this.elimDialog.open();
    } else if (key === 'sleep') {
      this.sleepDialog.open();
    } else if (key === 'growth') {
      this.growthDialog.open();
    } else if (key === 'vaccine') {
      this.selectedVaccineFilter = 0;
      try {
        promptAction.showToast({ message: '已为您定位至国家免疫规划疫苗专区' });
      } catch (e) {}
    } else if (key === 'expense') {
      this.expenseDialog.open();
    } else if (key === 'routine') {
      this.routineDialog.open();
    } else if (key === 'message') {
      this.messageDialog.open();
    }
  }

  private getDoneCount(): number {
    return this.vaccineList.filter(v => v.isDone === 1).length;
  }

  private getPendingCount(): number {
    return this.vaccineList.filter(v => v.isDone === 0).length;
  }

  private getFilteredVaccines(): VaccineRecord[] {
    if (this.selectedVaccineFilter === 1) {
      return this.vaccineList.filter(v => v.isDone === 0);
    } else if (this.selectedVaccineFilter === 2) {
      return this.vaccineList.filter(v => v.isDone === 1);
    }
    return this.vaccineList;
  }

  @Builder
  renderHubCard(item: RecordCategoryItem) {
    Column({ space: 4 }) {
      Text(item.icon)
        .fontSize(26)
      Text(item.title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppConstants.COLOR_TEXT_MAIN)
      Text(item.desc)
        .fontSize(11)
        .fontColor(AppConstants.COLOR_TEXT_MUTED)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor(item.bgColor)
    .borderRadius(14)
    .onClick(() => {
      this.handleSelectCategory(item.key);
    })
  }

  build() {
    Column({ space: 12 }) {
      // 1. 顶栏：标题与可点击响应的「全部分类」按钮
      Row() {
        Row({ space: 6 }) {
          Text('📝')
            .fontSize(22)
          Text('记录中心')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
        }

        Blank()

        // 可点击「全部分类」功能胶囊
        Row({ space: 4 }) {
          Text('全部分类')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppConstants.COLOR_PRIMARY)
          Text('›')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_PRIMARY)
        }
        .padding({ left: 10, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#FFF5F2')
        .borderRadius(14)
        .onClick(() => {
          router.pushUrl({ url: 'pages/record/CategorySortPage' });
        })
      }
      .width('94%')
      .padding({ top: 16, bottom: 4 })

      // 2. 四大核心卡片快捷录入区（自适应高度，按用户排序展示前4项，无缝衔接且绝不重叠）
      if (this.topCategories.length >= 4) {
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            this.renderHubCard(this.topCategories[0])
            this.renderHubCard(this.topCategories[1])
          }
          .width('100%')

          Row({ space: 10 }) {
            this.renderHubCard(this.topCategories[2])
            this.renderHubCard(this.topCategories[3])
          }
          .width('100%')
        }
        .width('94%')
        .margin({ bottom: 4 })
      }

      // 3. 国家免疫规划疫苗档案看板
      Row() {
        Row({ space: 6 }) {
          Text('💉')
            .fontSize(16)
          Text('国家免疫规划疫苗档案')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
        }

        Blank()

        Text(`已接种 ${this.getDoneCount()}/${this.vaccineList.length} 针`)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppConstants.COLOR_PRIMARY)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor('#FFF5F2')
          .borderRadius(10)
      }
      .width('94%')
      .margin({ top: 8 })

      // 4. 疫苗状态过滤胶囊切换
      Row({ space: 8 }) {
        // 全部
        Text(`全部 (${this.vaccineList.length})`)
          .fontSize(11)
          .fontWeight(this.selectedVaccineFilter === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.selectedVaccineFilter === 0 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
          .backgroundColor(this.selectedVaccineFilter === 0 ? AppConstants.COLOR_PRIMARY : '#ECE7DE')
          .borderRadius(12)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .onClick(() => { this.selectedVaccineFilter = 0; })

        // 待接种
        Text(`待接种 (${this.getPendingCount()})`)
          .fontSize(11)
          .fontWeight(this.selectedVaccineFilter === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.selectedVaccineFilter === 1 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
          .backgroundColor(this.selectedVaccineFilter === 1 ? AppConstants.COLOR_PRIMARY : '#ECE7DE')
          .borderRadius(12)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .onClick(() => { this.selectedVaccineFilter = 1; })

        // 已接种
        Text(`已接种 (${this.getDoneCount()})`)
          .fontSize(11)
          .fontWeight(this.selectedVaccineFilter === 2 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.selectedVaccineFilter === 2 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
          .backgroundColor(this.selectedVaccineFilter === 2 ? AppConstants.COLOR_PRIMARY : '#ECE7DE')
          .borderRadius(12)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .onClick(() => { this.selectedVaccineFilter = 2; })
      }
      .width('94%')

      // 5. 疫苗档案列表
      List({ space: 8 }) {
        ForEach(this.getFilteredVaccines(), (item: VaccineRecord) => {
          ListItem() {
            Row({ space: 10 }) {
              Checkbox()
                .select(item.isDone === 1)
                .selectedColor(AppConstants.COLOR_SUCCESS)
                .onChange((checked: boolean) => {
                  const db = DatabaseHelper.getInstance();
                  db.updateVaccineStatus(item.id, checked ? 1 : 0, Date.now());
                  this.refreshVaccines();
                  try {
                    promptAction.showToast({
                      message: checked ? `已标记「${item.vaccineName}」为已接种` : `已取消「${item.vaccineName}」接种`
                    });
                  } catch (e) {}
                })

              Column({ space: 3 }) {
                Row({ space: 6 }) {
                  Text(item.vaccineName)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLOR_TEXT_MAIN)
                  Text(item.dose)
                    .fontSize(10)
                    .fontColor(AppConstants.COLOR_TEXT_MUTED)
                    .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                    .backgroundColor('#F3F4F6')
                    .borderRadius(4)
                  if (item.isFree === 1) {
                    Text('免费一类')
                      .fontSize(9)
                      .fontColor(AppConstants.COLOR_SUCCESS)
                      .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                      .backgroundColor('#E6FFFA')
                      .borderRadius(4)
                  }
                }

                Text(`推荐接种: ${item.monthLabel}`)
                  .fontSize(11)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(item.isDone === 1 ? '✅ 已接种' : '⏳ 待接种')
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(item.isDone === 1 ? AppConstants.COLOR_SUCCESS : '#DD6B20')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(item.isDone === 1 ? '#F0FFF4' : '#FFFAF0')
                .borderRadius(6)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(AppConstants.COLOR_CARD_BG)
            .borderRadius(12)
            .border({ width: 1, color: AppConstants.COLOR_BORDER })
          }
        }, (item: VaccineRecord) => `${item.id}_${item.isDone}`)
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
