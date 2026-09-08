import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { ExpenseRecord } from '../../common/models/ExpenseRecord';
import { CaregiverConstants } from '../../common/constants/CaregiverConstants';

/**
 * 手绘喂养日记本（还原图二手绘手帐质感、角色交接、月度花销记账与父母寄语）
 */
@Component
export struct DiaryBookPage {
  @State selectedSubTab: number = 0; // 0 花销记账, 1 月计划作息, 2 父母寄语
  @State expenses: ExpenseRecord[] = [];
  @State totalExpense: number = 0;
  @State newExpenseAmount: string = '';
  @State newExpenseCategory: string = '奶粉配方';
  @State newExpenseNotes: string = '';
  @State parentsMessage: string = '亲爱的宝贝，看着你一天天长大，每一次大口喝奶、每一个可爱的微笑，都是爸爸妈妈最幸福的时刻。愿你健康、平安、快乐成长！';

  aboutToAppear() {
    this.refreshExpenses();
  }

  private refreshExpenses() {
    const db = DatabaseHelper.getInstance();
    this.expenses = db.getExpenses();
    let sum = 0;
    this.expenses.forEach(e => {
      sum += e.amount;
    });
    this.totalExpense = sum;
  }

  build() {
    Column({ space: 12 }) {
      // 1. 手绘日记封面顶栏
      Row({ space: 10 }) {
        Text('📖')
          .fontSize(24)
        Column({ space: 2 }) {
          Text('手绘喂养日记本')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
          Text('家庭照护交接 · 月计划 · 养娃花销 · 父母寄语')
            .fontSize(11)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('94%')
      .padding({ top: 16, bottom: 4 })

      // 2. 日记栏目切换
      Row({ space: 8 }) {
        Button('💰 每月花销账本')
          .fontSize(12)
          .fontWeight(this.selectedSubTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.selectedSubTab === 0 ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.selectedSubTab === 0 ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .height(34)
          .onClick(() => { this.selectedSubTab = 0; })

        Button('📅 月计划与作息')
          .fontSize(12)
          .fontWeight(this.selectedSubTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.selectedSubTab === 1 ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.selectedSubTab === 1 ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .height(34)
          .onClick(() => { this.selectedSubTab = 1; })

        Button('💌 父母寄语')
          .fontSize(12)
          .fontWeight(this.selectedSubTab === 2 ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.selectedSubTab === 2 ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.selectedSubTab === 2 ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .height(34)
          .onClick(() => { this.selectedSubTab = 2; })
      }
      .width('94%')

      // --- 子栏目 0: 每月花销账本（图二 P34-P35 特色） ---
      if (this.selectedSubTab === 0) {
        Column({ space: 10 }) {
          // 花销汇总卡片
          Row() {
            Column({ space: 4 }) {
              Text('本月养娃总开销')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
              Row() {
                Text('¥ ')
                  .fontSize(14)
                  .fontColor(AppConstants.COLOR_PRIMARY)
                Text(`${this.totalExpense.toFixed(2)}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_PRIMARY)
              }
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Button('+ 快速记一笔')
              .fontSize(12)
              .height(32)
              .backgroundColor(AppConstants.COLOR_PRIMARY)
              .onClick(() => {
                if (!this.newExpenseAmount) return;
                const amt = parseFloat(this.newExpenseAmount) || 0;
                if (amt <= 0) return;
                const db = DatabaseHelper.getInstance();
                const exp = new ExpenseRecord(
                  'exp_' + Date.now(),
                  db.getCurrentBaby().id,
                  Date.now(),
                  this.newExpenseCategory,
                  amt,
                  this.newExpenseNotes || this.newExpenseCategory
                );
                db.addExpense(exp);
                this.newExpenseAmount = '';
                this.newExpenseNotes = '';
                this.refreshExpenses();
              })
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 快速记账输入行
          Row({ space: 8 }) {
            Select([
              { value: '奶粉配方' },
              { value: '纸尿裤' },
              { value: '辅食营养' },
              { value: '衣服童鞋' },
              { value: '玩具绘本' },
              { value: '医疗疫苗' }
            ])
              .selected(0)
              .value(this.newExpenseCategory)
              .onSelect((idx: number, v: string) => { this.newExpenseCategory = v; })
              .width(110)

            TextInput({ placeholder: '金额 ¥', text: this.newExpenseAmount })
              .type(InputType.Number)
              .layoutWeight(1)
              .onChange((v: string) => { this.newExpenseAmount = v; })

            TextInput({ placeholder: '备注', text: this.newExpenseNotes })
              .layoutWeight(1)
              .onChange((v: string) => { this.newExpenseNotes = v; })
          }
          .width('100%')

          // 花销流水列表
          List({ space: 8 }) {
            ForEach(this.expenses, (item: ExpenseRecord) => {
              ListItem() {
                Row() {
                  Column({ space: 2 }) {
                    Text(item.category)
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppConstants.COLOR_TEXT_MAIN)
                    Text(item.notes)
                      .fontSize(12)
                      .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  }
                  .alignItems(HorizontalAlign.Start)

                  Blank()

                  Text(`¥ ${item.amount}`)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLOR_PRIMARY)
                }
                .width('100%')
                .padding(12)
                .backgroundColor(AppConstants.COLOR_CARD_BG)
                .borderRadius(12)
                .border({ width: 1, color: AppConstants.COLOR_BORDER })
              }
            }, (item: ExpenseRecord) => item.id)
          }
          .layoutWeight(1)
          .width('100%')
        }
        .width('94%')
        .layoutWeight(1)
      }

      // --- 子栏目 1: 月计划与作息排班（图二 P1 & P3-P33 特色） ---
      if (this.selectedSubTab === 1) {
        Column({ space: 12 }) {
          Column({ space: 6 }) {
            Text('⏰ 规律作息推荐安排（3~6月龄）')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
            Text('纸质日记本手绘推荐作息，帮助建立吃玩睡循环：')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            Row() {
              Text('🌅 07:00 晨起喝奶')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
              Blank()
              Text('配方奶/亲喂 150ml · 晒太阳/抚触')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FFF5F2')
            .borderRadius(10)

            Row() {
              Text('☀️ 09:00 晨间小睡')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
              Blank()
              Text('小睡约 1~1.5 小时 · 保持安静')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FAF5FF')
            .borderRadius(10)

            Row() {
              Text('🥣 11:30 辅食或喂奶')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
              Blank()
              Text('米粉/南瓜泥 + 奶量补足')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#EBF8FF')
            .borderRadius(10)

            Row() {
              Text('😴 13:00 午后小睡')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
              Blank()
              Text('深度小睡 1.5~2 小时')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FAF5FF')
            .borderRadius(10)

            Row() {
              Text('🌙 20:30 入睡程序')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
              Blank()
              Text('洗澡 · 抚触 · 奶睡/自主入眠')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#E6FFFA')
            .borderRadius(10)
          }
          .width('100%')
        }
        .width('94%')
        .padding(16)
        .backgroundColor(AppConstants.COLOR_CARD_BG)
        .borderRadius(16)
        .border({ width: 1, color: AppConstants.COLOR_BORDER })
      }

      // --- 子栏目 2: 父母寄语（图二封三） ---
      if (this.selectedSubTab === 2) {
        Column({ space: 14 }) {
          Row({ space: 8 }) {
            Text('💌 封三 · 父母给宝贝的爱心寄语')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
          }
          .width('100%')

          TextArea({ text: this.parentsMessage })
            .height(180)
            .fontSize(14)
            .lineHeight(22)
            .backgroundColor('#FFFBF5')
            .border({ width: 1, color: '#FFD4C2' })
            .borderRadius(12)
            .onChange((v: string) => { this.parentsMessage = v; })

          Row() {
            Blank()
            Text('—— 永远爱你的爸爸妈妈')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_PRIMARY)
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
        }
        .width('94%')
        .padding(16)
        .backgroundColor(AppConstants.COLOR_CARD_BG)
        .borderRadius(16)
        .border({ width: 1, color: AppConstants.COLOR_BORDER })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
