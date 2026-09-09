import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { ExpenseRecord } from '../../common/models/ExpenseRecord';
import promptAction from '@ohos.promptAction';

/**
 * 记一笔开销弹窗（支持分类选择、金额防呆校验、备注与提交）
 */
@CustomDialog
export struct AddExpenseDialog {
  controller: CustomDialogController;
  onSuccess?: () => void;

  @State selectedCategory: string = '纸尿裤';
  @State amountStr: string = '';
  @State notesStr: string = '';

  private readonly categories: string[] = [
    '纸尿裤',
    '奶粉配方',
    '辅食营养',
    '衣服童鞋',
    '玩具绘本',
    '医疗体检',
    '洗护喂哺',
    '其他开销'
  ];

  /**
   * 过滤金额输入（支持正小数，最多两位小数）
   */
  private sanitizeAmount(val: string): string {
    if (!val) return '';
    let clean = val.replace(/[^0-9.]/g, '');
    if (clean.startsWith('.')) {
      clean = '0' + clean;
    }
    const dotIndex = clean.indexOf('.');
    if (dotIndex !== -1) {
      const intPart = clean.substring(0, dotIndex);
      const decPart = clean.substring(dotIndex + 1).replace(/\./g, '');
      clean = intPart + '.' + decPart.substring(0, 2);
    }
    if (clean.length > 1 && clean.startsWith('0') && !clean.startsWith('0.')) {
      clean = clean.replace(/^0+/, '');
      if (clean === '') clean = '0';
    }
    return clean;
  }

  private handleSave(): void {
    if (!this.amountStr.trim()) {
      try {
        promptAction.showToast({ message: '请输入开销金额' });
      } catch (e) {}
      return;
    }
    const amt = parseFloat(this.amountStr);
    if (isNaN(amt) || amt <= 0) {
      try {
        promptAction.showToast({ message: '请输入大于0的有效金额' });
      } catch (e) {}
      return;
    }

    const db = DatabaseHelper.getInstance();
    const exp = new ExpenseRecord(
      'exp_' + Date.now(),
      db.getCurrentBaby().id,
      Date.now(),
      this.selectedCategory,
      amt,
      this.notesStr.trim() || this.selectedCategory
    );
    db.addExpense(exp);

    try {
      promptAction.showToast({ message: `已记一笔 ¥${amt.toFixed(2)}` });
    } catch (e) {}

    if (this.onSuccess) {
      this.onSuccess();
    }
    this.controller.close();
  }

  build() {
    Column({ space: 16 }) {
      // 标题栏
      Row() {
        Row({ space: 6 }) {
          Text('💰')
            .fontSize(18)
          Text('记一笔养娃开销')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
        }
        Blank()
        Text('✕')
          .fontSize(18)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .padding(4)
          .onClick(() => {
            this.controller.close();
          })
      }
      .width('100%')

      // 分类快捷标签选择
      Column({ space: 8 }) {
        Text('开销类别')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.categories, (cat: string) => {
            Text(cat)
              .fontSize(12)
              .fontWeight(this.selectedCategory === cat ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.selectedCategory === cat ? Color.White : AppConstants.COLOR_TEXT_MAIN)
              .backgroundColor(this.selectedCategory === cat ? AppConstants.COLOR_PRIMARY : '#F5F5F5')
              .borderRadius(14)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.selectedCategory = cat;
              })
          })
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 金额输入框
      Column({ space: 6 }) {
        Text('开销金额 (元)')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .width('100%')

        Row({ space: 6 }) {
          Text('¥')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_PRIMARY)
          TextInput({ placeholder: '0.00', text: this.amountStr })
            .type(InputType.NUMBER_DECIMAL)
            .inputFilter('[0-9.]')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_PRIMARY)
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .onChange((val: string) => {
              this.amountStr = this.sanitizeAmount(val);
            })
        }
        .width('100%')
        .height(44)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#F7FAFC')
        .borderRadius(10)
        .border({ width: 1, color: AppConstants.COLOR_BORDER })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 备注输入框
      Column({ space: 6 }) {
        Text('备注说明')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .width('100%')

        TextInput({ placeholder: '品牌、规格、购买渠道等（选填）', text: this.notesStr })
          .fontSize(13)
          .backgroundColor('#F7FAFC')
          .borderRadius(10)
          .height(42)
          .padding({ left: 12, right: 12 })
          .border({ width: 1, color: AppConstants.COLOR_BORDER })
          .onChange((val: string) => {
            this.notesStr = val;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 操作按钮
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .backgroundColor('#F0ECE1')
          .height(42)
          .layoutWeight(1)
          .borderRadius(21)
          .onClick(() => {
            this.controller.close();
          })

        Button('确认记一笔')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(AppConstants.COLOR_PRIMARY)
          .height(42)
          .layoutWeight(2)
          .borderRadius(21)
          .shadow({ radius: 6, color: 'rgba(255, 122, 89, 0.35)', offsetY: 2 })
          .onClick(() => {
            this.handleSave();
          })
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('90%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(20)
  }
}
