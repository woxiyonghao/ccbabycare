import { AppConstants } from '../../common/constants/AppConstants';
import { FormulaProfile } from '../../common/models/FormulaProfile';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import promptAction from '@ohos.promptAction';

/**
 * 新增奶粉段位与冲调配比弹窗
 */
@CustomDialog
export struct AddFormulaDialog {
  controller: CustomDialogController;
  onSuccess?: () => void;

  @State stage: string = '';
  @State brand: string = '';
  @State waterPerScoopStr: string = '30';
  @State defaultAmountStr: string = '120';

  private presetStages: string[] = ['1段 (0-6个月)', '2段 (6-12个月)', '3段 (1-3岁)', '4段 (3岁+)', '早产/特殊配方'];

  private handleSave() {
    if (!this.stage.trim()) {
      try {
        promptAction.showToast({ message: '请选择或输入奶粉段位' });
      } catch (err) {}
      return;
    }

    const water = parseInt(this.waterPerScoopStr) || 30;
    const amount = parseInt(this.defaultAmountStr) || 120;

    const newProfile = new FormulaProfile(
      `fp_${Date.now()}`,
      this.stage.trim(),
      water,
      amount,
      this.brand.trim() || '常用配方奶',
      0
    );

    DatabaseHelper.getInstance().addFormulaProfile(newProfile);

    try {
      promptAction.showToast({ message: '新奶粉配比已添加' });
    } catch (err) {}
    if (this.onSuccess) {
      this.onSuccess();
    }
    this.controller.close();
  }

  build() {
    Column({ space: 14 }) {
      // 顶栏
      Row() {
        Text('🍼 添加奶粉段位与配比')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
        Blank()
        Text('✕')
          .fontSize(18)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .onClick(() => this.controller.close())
      }
      .width('100%')

      // 段位快捷选择
      Column({ space: 6 }) {
        Text('快捷段位选择')
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.presetStages, (st: string) => {
            Text(st)
              .fontSize(12)
              .fontWeight(this.stage === st ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.stage === st ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .margin({ right: 6, bottom: 6 })
              .backgroundColor(this.stage === st ? AppConstants.COLOR_PRIMARY_LIGHT : '#F3F4F6')
              .borderRadius(14)
              .border({
                width: 1,
                color: this.stage === st ? AppConstants.COLOR_PRIMARY : '#E5E7EB'
              })
              .onClick(() => {
                this.stage = st;
              })
          }, (st: string) => st)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 自定义段位名称
      Column({ space: 4 }) {
        Text('段位与适用月龄')
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
        TextInput({ text: this.stage, placeholder: '如：1段 (0-6个月)' })
          .height(38)
          .fontSize(14)
          .backgroundColor('#F7FAFC')
          .borderRadius(8)
          .onChange((v: string) => {
            this.stage = v;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 冲调比例设置
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text('每平勺兑水量 (ml)')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          TextInput({ text: this.waterPerScoopStr, placeholder: '30' })
            .height(38)
            .fontSize(14)
            .type(InputType.Number)
            .backgroundColor('#F7FAFC')
            .borderRadius(8)
            .onChange((v: string) => {
              this.waterPerScoopStr = v;
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 4 }) {
          Text('常用单次奶量 (ml)')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          TextInput({ text: this.defaultAmountStr, placeholder: '120' })
            .height(38)
            .fontSize(14)
            .type(InputType.Number)
            .backgroundColor('#F7FAFC')
            .borderRadius(8)
            .onChange((v: string) => {
              this.defaultAmountStr = v;
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // 保存按钮
      Button('确认添加配比')
        .width('100%')
        .height(42)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(AppConstants.COLOR_PRIMARY)
        .fontColor(Color.White)
        .borderRadius(21)
        .margin({ top: 8 })
        .onClick(() => {
          this.handleSave();
        })
    }
    .width('92%')
    .padding(18)
    .backgroundColor(AppConstants.COLOR_CARD_BG)
    .borderRadius(20)
  }
}
