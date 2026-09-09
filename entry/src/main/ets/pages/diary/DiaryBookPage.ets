import promptAction from '@ohos.promptAction';
import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper, RoutineItem, ParentsMessageItem } from '../../common/database/DatabaseHelper';
import { ExpenseRecord } from '../../common/models/ExpenseRecord';
import { AddExpenseDialog } from './AddExpenseDialog';
import { AddRoutineDialog } from './AddRoutineDialog';
import { AddParentsMessageDialog } from './AddParentsMessageDialog';

interface RoutineColorStyle {
  text: string;
  bg: string;
}

/**
 * 手绘喂养日记本（毛玻璃分段切换、养娃账本弹窗记账、规律作息专属Cell样式、父母温情寄语）
 */
@Component
export struct DiaryBookPage {
  @State selectedSubTab: number = 0; // 0 养娃账本, 1 规律作息, 2 父母寄语
  @State tabContainerWidth: number = 0;
  @State expenses: ExpenseRecord[] = [];
  @State totalExpense: number = 0;
  @State routines: RoutineItem[] = [];
  @State messages: ParentsMessageItem[] = [];
  @StorageProp('APP_REFRESH_TRIGGER') @Watch('refreshAll') refreshTrigger: number = 0;

  // 记一笔开销弹窗控制器
  private expenseDialogController: CustomDialogController = new CustomDialogController({
    builder: AddExpenseDialog({
      onSuccess: () => {
        this.refreshExpenses();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 添加作息安排弹窗控制器
  private routineDialogController: CustomDialogController = new CustomDialogController({
    builder: AddRoutineDialog({
      onSuccess: () => {
        this.refreshRoutines();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // 写下寄语弹窗控制器
  private messageDialogController: CustomDialogController = new CustomDialogController({
    builder: AddParentsMessageDialog({
      onSuccess: () => {
        this.refreshMessages();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear() {
    this.refreshAll();
  }

  private refreshAll(): void {
    this.refreshExpenses();
    this.refreshRoutines();
    this.refreshMessages();
  }

  private refreshExpenses(): void {
    const db = DatabaseHelper.getInstance();
    this.expenses = db.getExpenses();
    let sum = 0;
    this.expenses.forEach(e => {
      sum += e.amount;
    });
    this.totalExpense = sum;
  }

  private refreshRoutines(): void {
    const db = DatabaseHelper.getInstance();
    this.routines = db.getRoutines();
  }

  private refreshMessages(): void {
    const db = DatabaseHelper.getInstance();
    this.messages = db.getParentsMessages();
  }

  /**
   * 格式化寄语发布时间
   */
  private formatMessageDate(timestamp: number): string {
    const d = new Date(timestamp);
    const month = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    const hours = d.getHours().toString().padStart(2, '0');
    const minutes = d.getMinutes().toString().padStart(2, '0');
    return `${d.getFullYear()}年${month}月${day}日 ${hours}:${minutes}`;
  }

  /**
   * 获取截图五对应的五套专属作息配色方案
   */
  private getRoutineTheme(theme: string, index: number): RoutineColorStyle {
    const themes: RoutineColorStyle[] = [
      { text: '#FF7A59', bg: '#FFF5F2' }, // 晨曦珊瑚橙
      { text: '#805AD5', bg: '#FAF5FF' }, // 梦幻柔紫
      { text: '#3182CE', bg: '#EBF8FF' }, // 晴空蔚蓝
      { text: '#319795', bg: '#E6FFFA' }, // 清新薄荷
      { text: '#D69E2E', bg: '#FEFCBF' }  // 温暖暖金
    ];
    if (theme === 'peach') return themes[0];
    if (theme === 'purple') return themes[1];
    if (theme === 'blue') return themes[2];
    if (theme === 'teal') return themes[3];
    if (theme === 'amber') return themes[4];
    return themes[index % themes.length];
  }

  /**
   * 悬浮按钮点击响应
   */
  private handleFabClick(): void {
    if (this.selectedSubTab === 0) {
      this.expenseDialogController.open();
    } else if (this.selectedSubTab === 1) {
      this.routineDialogController.open();
    } else if (this.selectedSubTab === 2) {
      this.messageDialogController.open();
    }
  }

  /**
   * 删除开销确认弹窗
   */
  private showDeleteExpenseDialog(item: ExpenseRecord): void {
    AlertDialog.show({
      title: '删除开销记录',
      message: `确定要删除「${item.category} ¥${item.amount.toFixed(2)}」吗？`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppConstants.COLOR_DANGER,
        action: () => {
          DatabaseHelper.getInstance().deleteExpense(item.id);
          this.refreshExpenses();
          try {
            promptAction.showToast({ message: '已删除该开销记录' });
          } catch (e) {}
        }
      }
    });
  }

  /**
   * 删除作息确认弹窗
   */
  private showDeleteRoutineDialog(item: RoutineItem): void {
    AlertDialog.show({
      title: '删除作息安排',
      message: `确定要删除「${item.time} ${item.title}」吗？`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppConstants.COLOR_DANGER,
        action: () => {
          DatabaseHelper.getInstance().deleteRoutine(item.id);
          this.refreshRoutines();
          try {
            promptAction.showToast({ message: '已删除该作息安排' });
          } catch (e) {}
        }
      }
    });
  }

  /**
   * 删除父母寄语确认弹窗
   */
  private showDeleteMessageDialog(item: ParentsMessageItem): void {
    AlertDialog.show({
      title: '删除父母寄语',
      message: '确定要删除这条珍贵的寄语记录吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppConstants.COLOR_DANGER,
        action: () => {
          DatabaseHelper.getInstance().deleteParentsMessage(item.id);
          this.refreshMessages();
          try {
            promptAction.showToast({ message: '已删除该寄语' });
          } catch (e) {}
        }
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 主内容流
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
        .padding({ top: 16, bottom: 2 })

        // 2. 日记栏目分段胶囊切换（截图一：毛玻璃质感 + 平滑滑动动效）
        Stack({ alignContent: Alignment.Start }) {
          // 平滑滑动的白色高亮胶囊指示块
          if (this.tabContainerWidth > 0) {
            Row()
              .width((this.tabContainerWidth - 6) / 3)
              .height(34)
              .backgroundColor(Color.White)
              .borderRadius(17)
              .shadow({ radius: 4, color: 'rgba(0,0,0,0.08)', offsetY: 1 })
              .translate({ x: 3 + this.selectedSubTab * ((this.tabContainerWidth - 6) / 3) })
              .animation({ duration: 250, curve: Curve.FastOutSlowIn })
          }

          // 三个分段选项
          Row() {
            // Tab 0: 养娃账本
            Row({ space: 4 }) {
              Text('💰')
                .fontSize(13)
              Text('养娃账本')
                .fontSize(12)
                .fontWeight(this.selectedSubTab === 0 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedSubTab === 0 ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
            }
            .layoutWeight(1)
            .height(34)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.selectedSubTab = 0;
            })

            // Tab 1: 规律作息
            Row({ space: 4 }) {
              Text('📅')
                .fontSize(13)
              Text('规律作息')
                .fontSize(12)
                .fontWeight(this.selectedSubTab === 1 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedSubTab === 1 ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
            }
            .layoutWeight(1)
            .height(34)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.selectedSubTab = 1;
            })

            // Tab 2: 父母寄语
            Row({ space: 4 }) {
              Text('💌')
                .fontSize(13)
              Text('父母寄语')
                .fontSize(12)
                .fontWeight(this.selectedSubTab === 2 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedSubTab === 2 ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
            }
            .layoutWeight(1)
            .height(34)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.selectedSubTab = 2;
            })
          }
          .width('100%')
        }
        .width('94%')
        .padding(3)
        .backgroundColor('rgba(236, 231, 222, 0.72)')
        .backgroundBlurStyle(BlurStyle.Thin)
        .borderRadius(20)
        .border({ width: 1, color: 'rgba(255, 255, 255, 0.6)' })
        .onAreaChange((oldVal: Area, newVal: Area) => {
          this.tabContainerWidth = Number(newVal.width);
        })

        // --- 子栏目 0: 养娃账本 ---
        if (this.selectedSubTab === 0) {
          Column({ space: 10 }) {
            // 1. 本月总开销看板
            Row() {
              Column({ space: 3 }) {
                Text('本月养娃总开销')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                Row({ space: 2 }) {
                  Text('¥')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLOR_PRIMARY)
                  Text(`${this.totalExpense.toFixed(2)}`)
                    .fontSize(26)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLOR_PRIMARY)
                }
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Text(`已记 ${this.expenses.length} 笔`)
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor('#FFF5F2')
                .borderRadius(12)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor(AppConstants.COLOR_CARD_BG)
            .borderRadius(16)
            .border({ width: 1, color: AppConstants.COLOR_BORDER })

            // 2. 开销流水列表或空数据状态（纯粹空态卡片，通过右下角「+」记账）
            if (this.expenses.length === 0) {
              Column({ space: 8 }) {
                Text('🧾')
                  .fontSize(38)
                Text('暂无养娃开销记录')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Text('轻触右下角「+」记下宝宝每一笔支出')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .width('100%')
              .padding({ top: 36, bottom: 36 })
              .backgroundColor(AppConstants.COLOR_CARD_BG)
              .borderRadius(16)
              .border({ width: 1, color: AppConstants.COLOR_BORDER })
              .alignItems(HorizontalAlign.Center)
            } else {
              List({ space: 8 }) {
                ForEach(this.expenses, (item: ExpenseRecord) => {
                  ListItem() {
                    Row({ space: 8 }) {
                      Column({ space: 3 }) {
                        Text(item.category)
                          .fontSize(14)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(AppConstants.COLOR_TEXT_MAIN)
                        Text(item.notes)
                          .fontSize(11)
                          .fontColor(AppConstants.COLOR_TEXT_MUTED)
                          .maxLines(1)
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Text(`¥ ${item.amount.toFixed(2)}`)
                        .fontSize(15)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(AppConstants.COLOR_PRIMARY)

                      // 删除按钮
                      Text('✕')
                        .fontSize(13)
                        .fontColor(AppConstants.COLOR_TEXT_MUTED)
                        .padding({ left: 8, right: 4, top: 4, bottom: 4 })
                        .onClick(() => {
                          this.showDeleteExpenseDialog(item);
                        })
                    }
                    .width('100%')
                    .padding({ left: 14, right: 12, top: 12, bottom: 12 })
                    .backgroundColor(AppConstants.COLOR_CARD_BG)
                    .borderRadius(12)
                    .border({ width: 1, color: AppConstants.COLOR_BORDER })
                  }
                }, (item: ExpenseRecord) => item.id)
              }
              .layoutWeight(1)
              .width('100%')
            }
          }
          .width('94%')
          .layoutWeight(1)
        }

        // --- 子栏目 1: 规律作息（无 mock 数据，保留截图五 Cell 样式） ---
        if (this.selectedSubTab === 1) {
          Column({ space: 10 }) {
            if (this.routines.length === 0) {
              Column({ space: 8 }) {
                Text('⏰')
                  .fontSize(38)
                Text('暂无规律作息安排')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Text('轻触右下角「+」为宝宝建立规律吃玩睡')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .width('100%')
              .padding({ top: 36, bottom: 36 })
              .backgroundColor(AppConstants.COLOR_CARD_BG)
              .borderRadius(16)
              .border({ width: 1, color: AppConstants.COLOR_BORDER })
              .alignItems(HorizontalAlign.Center)
            } else {
              Row() {
                Text(`⏰ 宝宝规律作息推荐安排（${this.routines.length}项）`)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Blank()
              }
              .width('100%')
              .padding({ left: 4, right: 4 })

              List({ space: 8 }) {
                ForEach(this.routines, (item: RoutineItem, idx: number) => {
                  ListItem() {
                    // 100% 还原截图五高质感 Cell 样式
                    Row({ space: 10 }) {
                      // 左侧色彩大字时间
                      Text(item.time)
                        .fontSize(15)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.getRoutineTheme(item.colorTheme, idx).text)
                        .width(52)

                      // 右侧图标、主标题与详情
                      Column({ space: 3 }) {
                        Text(`${item.emoji} ${item.title}`)
                          .fontSize(14)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(AppConstants.COLOR_TEXT_MAIN)
                        if (item.notes) {
                          Text(item.notes)
                            .fontSize(11)
                            .fontColor(AppConstants.COLOR_TEXT_MUTED)
                            .maxLines(2)
                        }
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      // 删除按钮
                      Text('✕')
                        .fontSize(12)
                        .fontColor(AppConstants.COLOR_TEXT_MUTED)
                        .padding({ left: 6, right: 4, top: 4, bottom: 4 })
                        .onClick(() => {
                          this.showDeleteRoutineDialog(item);
                        })
                    }
                    .width('100%')
                    .padding({ left: 14, right: 12, top: 12, bottom: 12 })
                    .backgroundColor(this.getRoutineTheme(item.colorTheme, idx).bg)
                    .borderRadius(10)
                  }
                }, (item: RoutineItem) => item.id)
              }
              .layoutWeight(1)
              .width('100%')
            }
          }
          .width('94%')
          .layoutWeight(1)
        }

        // --- 子栏目 2: 父母寄语（无默认 mock，空数据卡片，寄语流呈现） ---
        if (this.selectedSubTab === 2) {
          Column({ space: 10 }) {
            if (this.messages.length === 0) {
              Column({ space: 8 }) {
                Text('💌')
                  .fontSize(38)
                Text('暂无父母寄语')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Text('轻触右下角「+」记录写给宝贝的爱与祝福')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .width('100%')
              .padding({ top: 36, bottom: 36 })
              .backgroundColor(AppConstants.COLOR_CARD_BG)
              .borderRadius(16)
              .border({ width: 1, color: AppConstants.COLOR_BORDER })
              .alignItems(HorizontalAlign.Center)
            } else {
              Row() {
                Text(`💌 父母爱心寄语便签（${this.messages.length}篇）`)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Blank()
              }
              .width('100%')
              .padding({ left: 4, right: 4 })

              List({ space: 10 }) {
                ForEach(this.messages, (item: ParentsMessageItem) => {
                  ListItem() {
                    Column({ space: 8 }) {
                      Row() {
                        Row({ space: 4 }) {
                          Text('💌')
                            .fontSize(13)
                          Text(this.formatMessageDate(item.createdAt))
                            .fontSize(11)
                            .fontColor(AppConstants.COLOR_TEXT_MUTED)
                        }

                        Blank()

                        Text('✕')
                          .fontSize(12)
                          .fontColor(AppConstants.COLOR_TEXT_MUTED)
                          .padding(4)
                          .onClick(() => {
                            this.showDeleteMessageDialog(item);
                          })
                      }
                      .width('100%')

                      Text(item.content)
                        .fontSize(13)
                        .lineHeight(20)
                        .fontColor(AppConstants.COLOR_TEXT_MAIN)
                        .width('100%')

                      Row() {
                        Blank()
                        Text(`—— ${item.signature || '永远爱你的爸爸妈妈'}`)
                          .fontSize(12)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(AppConstants.COLOR_PRIMARY)
                      }
                      .width('100%')
                    }
                    .width('100%')
                    .padding(14)
                    .backgroundColor('#FFFBF5')
                    .border({ width: 1, color: '#FFE3D6' })
                    .borderRadius(14)
                  }
                }, (item: ParentsMessageItem) => item.id)
              }
              .layoutWeight(1)
              .width('100%')
            }
          }
          .width('94%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')

      // 右下角常驻悬浮按钮（截图三：悬浮 + 按钮，点击按当前 Tab 呼出对应记录弹窗）
      Button({ type: ButtonType.Circle }) {
        Text('+')
          .fontSize(30)
          .fontWeight(FontWeight.Regular)
          .fontColor(Color.White)
          .margin({ bottom: 3 })
      }
      .width(52)
      .height(52)
      .backgroundColor(AppConstants.COLOR_PRIMARY)
      .shadow({ radius: 8, color: 'rgba(255, 122, 89, 0.45)', offsetY: 4 })
      .margin({ right: 20, bottom: 20 })
      .onClick(() => {
        this.handleFabClick();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
