import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { BabyModel } from '../../common/models/BabyModel';
import { FormulaProfile } from '../../common/models/FormulaProfile';
import { ArrowIcon } from '../../common/components/ArrowIcon';
import { AddFormulaDialog } from './AddFormulaDialog';

/**
 * 档案与设置页：宝宝档案修改、奶粉库配比快速添加、隐私政策、清除所有数据
 */
@Component
export struct ProfilePage {
  @State babies: BabyModel[] = [];
  @State currentBaby: BabyModel = new BabyModel();
  @State formulas: FormulaProfile[] = [];
  @State currentDefaultFormulaId: string = '';
  @StorageProp('APP_REFRESH_TRIGGER') @Watch('refreshData') refreshTrigger: number = 0;

  // 新增奶粉配比弹窗
  private addFormulaDialogController: CustomDialogController = new CustomDialogController({
    builder: AddFormulaDialog({
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

  public refreshData(): void {
    const db = DatabaseHelper.getInstance();
    this.babies = db.getBabies();
    this.currentBaby = db.getCurrentBaby();
    const list = db.getFormulaProfiles();
    this.formulas = [...list];
    const def = list.find((f: FormulaProfile) => f.isDefault === 1);
    this.currentDefaultFormulaId = def ? def.id : '';
  }

  build() {
    Column({ space: 14 }) {
      // 顶栏
      Row() {
        Text('⚙️ 档案与设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
      }
      .width('94%')
      .padding({ top: 16, bottom: 4 })

      Scroll() {
        Column({ space: 14 }) {
          // 1. 当前宝宝档案卡（支持右上角独立页面编辑，无左侧符号）
          Column({ space: 8 }) {
            Row({ space: 12 }) {
              Text(this.currentBaby.avatar || '👶')
                .fontSize(36)
              Column({ space: 4 }) {
                Row({ space: 6 }) {
                  Text(this.currentBaby.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLOR_TEXT_MAIN)
                  Text(this.currentBaby.gender === 'boy' ? '👦 男童' : '👧 女童')
                    .fontSize(11)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor('#EBF8FF')
                    .borderRadius(6)
                }
                Text(`当前月龄：${this.currentBaby.getAgeString()}`)
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_PRIMARY)
                Text(`出生信息：${this.currentBaby.birthWeight > 0 ? this.currentBaby.birthWeight + 'kg' : '--'} · ${this.currentBaby.birthHeight > 0 ? this.currentBaby.birthHeight + 'cm' : '--'} · ${this.currentBaby.bloodType && this.currentBaby.bloodType !== '未知' ? this.currentBaby.bloodType + '型血' : '血型未填'}`)
                  .fontSize(11)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              // 截图5 & 用户要求：编辑按钮单独page，且无左侧符号
              Button('编辑')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppConstants.COLOR_PRIMARY)
                .backgroundColor(AppConstants.COLOR_PRIMARY_LIGHT)
                .height(28)
                .padding({ left: 14, right: 14 })
                .borderRadius(14)
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/profile/EditBabyProfilePage',
                    params: { isFirstSetup: false }
                  });
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 2. 奶粉库设置卡片（常用只能设置一个 + 右上角+图标快速添加）
          Column({ space: 10 }) {
            Row() {
              Text('🍼 奶粉库设置')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
              Blank()
              // 右上角 + 快速添加
              Button({ type: ButtonType.Normal }) {
                Image($r('app.media.ic_plus'))
                  .width(13)
                  .height(13)
              }
              .width(28)
              .height(28)
              .backgroundColor(AppConstants.COLOR_PRIMARY_LIGHT)
              .borderRadius(14)
              .onClick(() => {
                this.addFormulaDialogController.open();
              })
            }
            .width('100%')

            if (this.formulas.length === 0) {
              Column({ space: 4 }) {
                Text('暂无奶粉段位配置')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Text('点击右上角「+」即可添加宝宝常喝的奶粉与冲调配比')
                  .fontSize(11)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .width('100%')
              .padding({ top: 14, bottom: 14 })
              .alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.formulas, (item: FormulaProfile) => {
                Row() {
                  Column({ space: 2 }) {
                    Text(item.stage)
                      .fontSize(13)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppConstants.COLOR_TEXT_MAIN)
                    Text(`冲调比: 1平勺兑 ${item.waterPerScoop}ml 水 · 常用量: ${item.defaultAmount}ml`)
                      .fontSize(11)
                      .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Blank()

                  // 用户要求：不要有默认，只有用户主动设为常用后才高亮，且全局只能设置一个
                  if (this.currentDefaultFormulaId !== '' && this.currentDefaultFormulaId === item.id) {
                    Text('常用 ✓')
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppConstants.COLOR_SUCCESS)
                      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                      .backgroundColor(AppConstants.COLOR_SUCCESS_LIGHT)
                      .borderRadius(8)
                  } else {
                    Text('设为常用')
                      .fontSize(11)
                      .fontColor(AppConstants.COLOR_TEXT_MUTED)
                      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                      .backgroundColor('#F3F4F6')
                      .borderRadius(8)
                      .onClick(() => {
                        this.currentDefaultFormulaId = item.id;
                        DatabaseHelper.getInstance().setDefaultFormula(item.id);
                        this.refreshData();
                        try {
                          promptAction.showToast({ message: `已将 ${item.stage} 设为常用` });
                        } catch (e) {}
                      })
                  }

                  // 支持删除奶粉段位（弹窗二次确认）
                  Text('✕')
                    .fontSize(12)
                    .fontColor(AppConstants.COLOR_TEXT_MUTED)
                    .padding({ left: 8, right: 4, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.showDeleteFormulaConfirmDialog(item);
                    })
                }
                .width('100%')
                .padding(10)
                .backgroundColor('#FFFBF5')
                .borderRadius(10)
              }, (item: FormulaProfile) => `${item.id}_${item.isDefault}_${this.currentDefaultFormulaId}`)
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 3. 成长与健康统计卡片（点击跳转独立 StatisticsPage）
          Row() {
            Row({ space: 10 }) {
              Text('📈')
                .fontSize(22)
              Column({ space: 3 }) {
                Text('成长与健康统计')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Text('2026儿童身高体重标准对照、达标测算与曲线')
                  .fontSize(11)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .alignItems(HorizontalAlign.Start)
            }
            Blank()
            ArrowIcon({ arrowDirection: 'right', variant: 'gray', iconSize: 14 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/statistics/StatisticsPage'
            });
          })

          // 4. 隐私政策卡片（点击跳转独立 PrivacyPolicyPage）
          Row() {
            Row({ space: 10 }) {
              Text('🛡️')
                .fontSize(22)
              Column({ space: 3 }) {
                Text('隐私政策')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Text('纯本地离线运行与零敏感权限保护承诺')
                  .fontSize(11)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .alignItems(HorizontalAlign.Start)
            }
            Blank()
            ArrowIcon({ arrowDirection: 'right', variant: 'gray', iconSize: 14 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/privacy/PrivacyPolicyPage'
            });
          })

          // 4. 清除所有数据卡片（整行点击触发弹窗 + 先toast提示）
          Row() {
            Row({ space: 10 }) {
              Text('🗑️')
                .fontSize(22)
              Column({ space: 3 }) {
                Text('清除所有数据')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_DANGER)
                Text('彻底清空所有本地记录，清理后不可恢复')
                  .fontSize(11)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .alignItems(HorizontalAlign.Start)
            }
            Blank()
            ArrowIcon({ arrowDirection: 'right', variant: 'gray', iconSize: 14 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })
          .onClick(() => {
            this.showClearConfirmDialog();
          })
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

  /**
   * 弹窗确认是否删除奶粉段位配置
   */
  private showDeleteFormulaConfirmDialog(item: FormulaProfile): void {
    AlertDialog.show({
      title: '删除奶粉配置',
      message: `确定要删除「${item.stage}」的奶粉配置吗？删除后不可撤回。`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认删除',
        fontColor: AppConstants.COLOR_DANGER,
        action: () => {
          DatabaseHelper.getInstance().deleteFormulaProfile(item.id);
          this.refreshData();
          try {
            promptAction.showToast({ message: `已删除「${item.stage}」配置` });
          } catch (e) {}
        }
      }
    });
  }

  /**
   * 弹窗确认是否清除所有数据，点击确认先 toast 提示，然后彻底清理本地数据
   */
  private showClearConfirmDialog(): void {
    AlertDialog.show({
      title: '清除所有数据',
      message: '确定要清除所有本地数据吗？此操作将清空所有喂养、排便、睡眠、生长及花销记录，清理后不可恢复！',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认清除',
        fontColor: AppConstants.COLOR_DANGER,
        action: () => {
          // 点击确认先toast一下
          try {
            promptAction.showToast({
              message: '数据已全部清空，请重新设置宝宝档案',
              duration: 2000
            });
          } catch (err) {}
          DatabaseHelper.getInstance().clearAllData();
          this.refreshData();
          router.replaceUrl({
            url: 'pages/profile/EditBabyProfilePage',
            params: { isFirstSetup: true }
          });
        }
      }
    });
  }
}
