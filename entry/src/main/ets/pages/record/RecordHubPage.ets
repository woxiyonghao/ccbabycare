import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { RecordCategoryItem, getCategoryByKey, DEFAULT_CATEGORY_KEYS } from '../../common/models/RecordCategoryItem';
import { FeedingRecordDialog } from './FeedingRecordDialog';
import { EliminationRecordDialog } from './EliminationRecordDialog';
import { SleepRecordDialog } from './SleepRecordDialog';
import { GrowthRecordDialog } from './GrowthRecordDialog';
import { AllCategoriesDialog } from './AllCategoriesDialog';
import { AddVaccineDialog } from './AddVaccineDialog';
import { AddExpenseDialog } from '../diary/AddExpenseDialog';
import { AddRoutineDialog } from '../diary/AddRoutineDialog';
import { AddParentsMessageDialog } from '../diary/AddParentsMessageDialog';
import { VaccineRecord } from '../../common/models/VaccineRecord';
import { ArrowIcon } from '../../common/components/ArrowIcon';

/**
 * 记录中心页：聚合四大核心快捷卡片与疫苗接种自主录入档案
 */
@Component
export struct RecordHubPage {
  @State vaccineList: VaccineRecord[] = [];
  @State selectedVaccineFilter: number = 0; // 0 全部, 1 待接种, 2 已接种
  @State topCategories: RecordCategoryItem[] = DEFAULT_CATEGORY_KEYS.slice(0, 4).map((k: string) => getCategoryByKey(k));
  @StorageProp('APP_REFRESH_TRIGGER') @Watch('onAppRefresh') refreshTrigger: number = 0;
  @StorageProp('CATEGORY_ORDER_TRIGGER') @Watch('onCategoryOrderChanged') categoryOrderTrigger: number = 0;

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

  // 5. 疫苗接种自主录入弹窗（同记事本体验）
  private addVaccineDialog: CustomDialogController = new CustomDialogController({
    builder: AddVaccineDialog({
      onSuccess: () => {
        this.refreshVaccines();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 6. 养娃账本弹窗
  private expenseDialog: CustomDialogController = new CustomDialogController({
    builder: AddExpenseDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 7. 规律作息弹窗
  private routineDialog: CustomDialogController = new CustomDialogController({
    builder: AddRoutineDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 8. 父母寄语弹窗
  private messageDialog: CustomDialogController = new CustomDialogController({
    builder: AddParentsMessageDialog(),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 9. 全部分类面板弹窗
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

  private onAppRefresh(): void {
    this.refreshVaccines();
    this.refreshTopCategories();
  }

  private onCategoryOrderChanged(): void {
    this.refreshTopCategories();
  }

  private refreshTopCategories(): void {
    const db = DatabaseHelper.getInstance();
    const order = db.getCategoryOrder();
    const fullOrder: string[] = [];
    if (Array.isArray(order)) {
      for (let i = 0; i < order.length; i++) {
        if (!fullOrder.includes(order[i])) {
          fullOrder.push(order[i]);
        }
      }
    }
    for (let i = 0; i < DEFAULT_CATEGORY_KEYS.length; i++) {
      if (!fullOrder.includes(DEFAULT_CATEGORY_KEYS[i])) {
        fullOrder.push(DEFAULT_CATEGORY_KEYS[i]);
      }
    }
    this.topCategories = fullOrder.slice(0, 4).map(k => getCategoryByKey(k));
  }

  private refreshVaccines(): void {
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
      this.addVaccineDialog.open();
    } else if (key === 'expense') {
      this.expenseDialog.open();
    } else if (key === 'routine') {
      this.routineDialog.open();
    } else if (key === 'message') {
      this.messageDialog.open();
    }
  }

  private showToggleVaccineStatusDialog(item: VaccineRecord): void {
    const isCurrentlyDone = item.isDone === 1;
    const targetStatusText = isCurrentlyDone ? '待接种' : '已接种';
    AlertDialog.show({
      title: '切换接种状态',
      message: isCurrentlyDone
        ? `确定将「${item.vaccineName} (${item.dose})」更改为【待接种】状态吗？`
        : `确定将「${item.vaccineName} (${item.dose})」标记为【已接种】吗？`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: `设为${targetStatusText}`,
        fontColor: isCurrentlyDone ? '#DD6B20' : AppConstants.COLOR_SUCCESS,
        action: () => {
          const nextStatus = isCurrentlyDone ? 0 : 1;
          DatabaseHelper.getInstance().updateVaccineStatus(item.id, nextStatus, nextStatus === 1 ? Date.now() : 0);
          this.refreshVaccines();
          try {
            promptAction.showToast({
              message: `已将「${item.vaccineName}」设为${targetStatusText}`
            });
          } catch (e) {}
        }
      }
    });
  }

  private showDeleteVaccineDialog(item: VaccineRecord): void {
    AlertDialog.show({
      title: '删除接种记录',
      message: `确定要删除「${item.vaccineName} (${item.dose})」接种记录吗？删除后不可恢复。`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppConstants.COLOR_DANGER,
        action: () => {
          DatabaseHelper.getInstance().deleteVaccineRecord(item.id);
          this.refreshVaccines();
          try {
            promptAction.showToast({ message: '已删除接种记录' });
          } catch (e) {}
        }
      }
    });
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

  @Builder
  renderSwipeDeleteButton(item: VaccineRecord) {
    Row() {
      Button('删除', { type: ButtonType.Normal })
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor(AppConstants.COLOR_DANGER)
        .width(68)
        .height('100%')
        .borderRadius(12)
        .margin({ left: 6 })
        .onClick(() => {
          this.showDeleteVaccineDialog(item);
        })
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.End)
  }

  build() {
    Scroll() {
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

        // 2. 四大核心卡片快捷录入区（动态响应用户分类排序，自适应高度无重叠）
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
          .margin({ bottom: 2 })
        }

        // 2.5 下方查看所有流水记录条目（高度增加24vp，更加饱满大气）
        Row() {
          Row({ space: 10 }) {
            Text('📋')
              .fontSize(22)
            Column({ space: 4 }) {
              Text('查看所有记录')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
              Text('汇总全部分类历史流水 · 按日整理')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            .alignItems(HorizontalAlign.Start)
          }

          Blank()

          Row({ space: 4 }) {
            Text('全部')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppConstants.COLOR_PRIMARY)
            ArrowIcon({ arrowDirection: 'right', variant: 'orange', iconSize: 13 })
          }
          .padding({ left: 10, right: 8, top: 5, bottom: 5 })
          .backgroundColor('#FFF5F2')
          .borderRadius(12)
        }
        .width('94%')
        .height(68) // 高度增加 24vp（原约44vp -> 68vp）
        .padding({ left: 16, right: 16 })
        .backgroundColor(AppConstants.COLOR_CARD_BG)
        .borderRadius(16)
        .border({ width: 1, color: AppConstants.COLOR_BORDER })
        .shadow({ radius: 6, color: 'rgba(0,0,0,0.02)', offsetY: 2 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/record/AllRecordsPage' });
        })

        // 3. 疫苗接种档案卡片（做成一个小卡片，最多显示三条，超过三条显示查看全部进入新页面）
        Column({ space: 10 }) {
          // 卡片头
          Row() {
            Row({ space: 6 }) {
              Text('💉')
                .fontSize(16)
              Text('疫苗接种档案')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
            }

            Blank()

            if (this.vaccineList.length > 0) {
              Text(`已接种 ${this.getDoneCount()}/${this.vaccineList.length} 针`)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppConstants.COLOR_PRIMARY)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor('#FFF5F2')
                .borderRadius(10)
                .margin({ right: 6 })
            }

            Row({ space: 2 }) {
              Text('+')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_PRIMARY)
              Text('记一笔')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppConstants.COLOR_PRIMARY)
            }
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor('#FFF5F2')
            .borderRadius(10)
            .onClick(() => {
              this.addVaccineDialog.open();
            })
          }
          .width('100%')

          // 卡片内容：最多显示三条
          if (this.vaccineList.length === 0) {
            Column({ space: 6 }) {
              Text('💉')
                .fontSize(30)
              Text('暂无疫苗接种记录')
                .fontSize(13)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 })
            .alignItems(HorizontalAlign.Center)
          } else {
            Column({ space: 8 }) {
              ForEach(this.vaccineList.slice(0, 3), (item: VaccineRecord) => {
                Row({ space: 10 }) {
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
                      } else {
                        Text('自费二类')
                          .fontSize(9)
                          .fontColor('#DD6B20')
                          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                          .backgroundColor('#FFFAF0')
                          .borderRadius(4)
                      }
                    }

                    Text(item.organization ? `${item.monthLabel || '接种'} · ${item.organization}` : (item.monthLabel ? `接种日期: ${item.monthLabel}` : (item.notes || '健康疫苗接种')))
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
                    .onClick(() => {
                      this.showToggleVaccineStatusDialog(item);
                    })
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                .backgroundColor('#FAFAFA')
                .borderRadius(10)
                .border({ width: 1, color: '#F0ECE4' })
                .gesture(
                  LongPressGesture({ duration: 350 })
                    .onAction(() => {
                      this.showDeleteVaccineDialog(item);
                    })
                )
              }, (item: VaccineRecord) => `${item.id}_${item.isDone}`)
            }
            .width('100%')

            // 超过三条，下面显示查看全部，跳出一个新的page
            if (this.vaccineList.length > 3) {
              Row({ space: 4 }) {
                Text(`查看全部疫苗档案 (${this.vaccineList.length}针)`)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppConstants.COLOR_PRIMARY)
                ArrowIcon({ arrowDirection: 'right', variant: 'orange', iconSize: 12 })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ top: 8, bottom: 4 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/record/VaccineListPage' });
              })
            }
          }
        }
        .width('94%')
        .padding(14)
        .backgroundColor(AppConstants.COLOR_CARD_BG)
        .borderRadius(16)
        .border({ width: 1, color: AppConstants.COLOR_BORDER })

        // 底部 spacer，避让 TabBar
        Row().height(88)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
