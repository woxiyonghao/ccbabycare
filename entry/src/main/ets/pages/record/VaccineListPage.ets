import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { VaccineRecord } from '../../common/models/VaccineRecord';
import { AddVaccineDialog } from './AddVaccineDialog';
import { ArrowIcon } from '../../common/components/ArrowIcon';

/**
 * 疫苗接种档案全览页面
 * - 顶部统计栏与快速新增
 * - 分类过滤胶囊（全部 / 待接种 / 已接种）
 * - 完整接种列表卡片，支持侧滑删除、长按删除及接种状态切换
 */
@Entry
@Component
struct VaccineListPage {
  @State vaccineList: VaccineRecord[] = [];
  @State selectedFilter: number = 0; // 0 全部, 1 待接种, 2 已接种
  @StorageProp('APP_REFRESH_TRIGGER') @Watch('refreshData') refreshTrigger: number = 0;

  // 疫苗接种自主录入弹窗
  private addVaccineDialog: CustomDialogController = new CustomDialogController({
    builder: AddVaccineDialog({
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear() {
    this.refreshData();
  }

  private refreshData(): void {
    const db = DatabaseHelper.getInstance();
    this.vaccineList = db.getVaccineRecords();
  }

  private getDoneCount(): number {
    return this.vaccineList.filter(v => v.isDone === 1).length;
  }

  private getPendingCount(): number {
    return this.vaccineList.filter(v => v.isDone === 0).length;
  }

  private getFilteredVaccines(): VaccineRecord[] {
    if (this.selectedFilter === 1) {
      return this.vaccineList.filter(v => v.isDone === 0);
    } else if (this.selectedFilter === 2) {
      return this.vaccineList.filter(v => v.isDone === 1);
    }
    return this.vaccineList;
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
          this.refreshData();
          AppStorage.setOrCreate('APP_REFRESH_TRIGGER', Date.now());
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
          this.refreshData();
          AppStorage.setOrCreate('APP_REFRESH_TRIGGER', Date.now());
          try {
            promptAction.showToast({ message: '已删除接种记录' });
          } catch (e) {}
        }
      }
    });
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
    Column({ space: 10 }) {
      // 1. 顶部标题栏
      Row() {
        Row({ space: 6 }) {
          ArrowIcon({ arrowDirection: 'left', variant: 'gray', iconSize: 14 })
          Text('返回')
            .fontSize(14)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
        }
        .padding({ left: 4, right: 8, top: 6, bottom: 6 })
        .onClick(() => {
          router.back();
        })
        .width(72)

        Text('疫苗接种档案')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 记一笔按钮
        Row({ space: 2 }) {
          Text('+')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_PRIMARY)
          Text('记一笔')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppConstants.COLOR_PRIMARY)
        }
        .width(72)
        .justifyContent(FlexAlign.End)
        .padding({ right: 4, top: 6, bottom: 6 })
        .onClick(() => {
          this.addVaccineDialog.open();
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })
      .backgroundColor(AppConstants.COLOR_BG_CREAM)

      // 2. 状态统计看板
      Row() {
        Column({ space: 2 }) {
          Text('接种进度')
            .fontSize(11)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          Row({ space: 4 }) {
            Text(`${this.getDoneCount()}`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_PRIMARY)
            Text(`/ ${this.vaccineList.length} 针`)
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .margin({ bottom: 2 })
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 状态筛选胶囊
        Row({ space: 6 }) {
          Text(`全部 (${this.vaccineList.length})`)
            .fontSize(11)
            .fontWeight(this.selectedFilter === 0 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedFilter === 0 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
            .backgroundColor(this.selectedFilter === 0 ? AppConstants.COLOR_PRIMARY : '#ECE7DE')
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .onClick(() => { this.selectedFilter = 0; })

          Text(`待接种 (${this.getPendingCount()})`)
            .fontSize(11)
            .fontWeight(this.selectedFilter === 1 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedFilter === 1 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
            .backgroundColor(this.selectedFilter === 1 ? AppConstants.COLOR_PRIMARY : '#ECE7DE')
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .onClick(() => { this.selectedFilter = 1; })

          Text(`已接种 (${this.getDoneCount()})`)
            .fontSize(11)
            .fontWeight(this.selectedFilter === 2 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedFilter === 2 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
            .backgroundColor(this.selectedFilter === 2 ? AppConstants.COLOR_PRIMARY : '#ECE7DE')
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .onClick(() => { this.selectedFilter = 2; })
        }
      }
      .width('94%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(AppConstants.COLOR_CARD_BG)
      .borderRadius(14)
      .border({ width: 1, color: AppConstants.COLOR_BORDER })

      // 3. 疫苗列表
      if (this.getFilteredVaccines().length === 0) {
        Column({ space: 8 }) {
          Text('💉')
            .fontSize(38)
          Text('暂无接种记录')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
          Text('轻触右上角「+记一笔」添加接种信息')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
        }
        .width('94%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.getFilteredVaccines(), (item: VaccineRecord) => {
            ListItem() {
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
              .padding({ left: 14, right: 14, top: 12, bottom: 12 })
              .backgroundColor(AppConstants.COLOR_CARD_BG)
              .borderRadius(12)
              .border({ width: 1, color: AppConstants.COLOR_BORDER })
              .gesture(
                LongPressGesture({ duration: 350 })
                  .onAction(() => {
                    this.showDeleteVaccineDialog(item);
                  })
              )
            }
            .swipeAction({
              end: {
                builder: () => {
                  this.renderSwipeDeleteButton(item);
                }
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (item: VaccineRecord) => `${item.id}_${item.isDone}`)

          // 底部间距
          ListItem() {
            Row().height(40)
          }
        }
        .width('94%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
