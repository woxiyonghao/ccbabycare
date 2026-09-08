import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { BabyModel } from '../../common/models/BabyModel';
import { FormulaProfile } from '../../common/models/FormulaProfile';

/**
 * 档案与设置页：宝宝档案切换、奶粉库、离线全量数据备份/导出、隐私关于
 */
@Component
export struct ProfilePage {
  @State babies: BabyModel[] = [];
  @State currentBaby: BabyModel = new BabyModel();
  @State formulas: FormulaProfile[] = [];
  @State exportStatusMsg: string = '';

  aboutToAppear() {
    this.refreshData();
  }

  private refreshData() {
    const db = DatabaseHelper.getInstance();
    this.babies = db.getBabies();
    this.currentBaby = db.getCurrentBaby();
    this.formulas = db.getFormulaProfiles();
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
          // 1. 当前宝宝档案卡
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
                Text(`出生信息：${this.currentBaby.birthWeight}kg · ${this.currentBaby.birthHeight}cm · ${this.currentBaby.bloodType}型血`)
                  .fontSize(11)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 2. 奶粉库设置卡片（P0配套）
          Column({ space: 10 }) {
            Row() {
              Text('🍼 奶粉库设置')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
              Blank()
              Text('快捷段位与配比')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            .width('100%')

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
                Blank()
                Text('常用 ✓')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_SUCCESS)
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#FFFBF5')
              .borderRadius(10)
            }, (item: FormulaProfile) => item.id)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 3. 离线数据备份与导出（P0）
          Column({ space: 10 }) {
            Row() {
              Text('💾 本地数据备份与导出')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
              Blank()
              Text('完全离线存储')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_SUCCESS)
            }
            .width('100%')

            Text('所有数据均保存在您手机本地沙盒中，不上传任何云端服务器。您可以一键导出备份文件，通过文件面板分享或保存，杜绝隐私泄露。')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .lineHeight(18)

            Row({ space: 10 }) {
              Button('导出全量数据 (JSON)')
                .layoutWeight(1)
                .height(38)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .backgroundColor(AppConstants.COLOR_PRIMARY)
                .onClick(() => {
                  const db = DatabaseHelper.getInstance();
                  const jsonStr = db.exportAllDataJson();
                  this.exportStatusMsg = `✅ 已成功生成全量离线备份包 (共计 ${jsonStr.length} 字符)`;
                })

              Button('恢复备份数据')
                .layoutWeight(1)
                .height(38)
                .fontSize(13)
                .fontWeight(FontWeight.Normal)
                .backgroundColor('#F3F4F6')
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
                .onClick(() => {
                  this.exportStatusMsg = 'ℹ️ 请通过系统文件面板选择 .json 备份文件进行覆盖或合并恢复';
                })
            }
            .width('100%')

            if (this.exportStatusMsg) {
              Text(this.exportStatusMsg)
                .fontSize(12)
                .fontColor(AppConstants.COLOR_PRIMARY)
                .padding(8)
                .backgroundColor(AppConstants.COLOR_PRIMARY_LIGHT)
                .borderRadius(8)
                .width('100%')
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 4. 隐私安全与关于
          Column({ space: 6 }) {
            Text('🔒 隐私与权限承诺')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
            Text('• 零敏感权限申请：不索取通讯录、位置、外部存储、电话等权限。\n• 零网络依赖：全流程断网可用。\n• 零账号登录：免去手机号与注册烦恼，打开即用。')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .lineHeight(18)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#F7FAFC')
          .borderRadius(14)
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
