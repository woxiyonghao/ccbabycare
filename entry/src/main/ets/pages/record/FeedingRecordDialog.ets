import { AppConstants } from '../../common/constants/AppConstants';
import { FeedingType, FormulaStage } from '../../common/constants/FeedingConstants';
import { FeedingRecord } from '../../common/models/FeedingRecord';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { CaregiverPicker } from '../../common/components/CaregiverPicker';

/**
 * 极速喂养记录弹窗（支持配方奶段位、亲喂双侧、母乳瓶喂、辅食）
 */
@CustomDialog
export struct FeedingRecordDialog {
  controller: CustomDialogController;
  onSuccess?: () => void;

  initialType: FeedingType = FeedingType.FORMULA;
  @State feedingType: FeedingType = FeedingType.FORMULA;
  @State amount: number = 120;
  @State selectedStage: FormulaStage = FormulaStage.STAGE_1;
  @State scoops: number = 4;
  @State waterAmount: number = 120;
  @State leftDuration: number = 15;
  @State rightDuration: number = 10;
  @State caregiverId: string = 'MOM';
  @State solidsName: string = '';
  @State isNewFood: boolean = false;
  @State notes: string = '';

  aboutToAppear() {
    if (this.initialType) {
      this.feedingType = this.initialType;
    }
  }

  private stages: FormulaStage[] = [
    FormulaStage.STAGE_1,
    FormulaStage.STAGE_2,
    FormulaStage.STAGE_3,
    FormulaStage.STAGE_4
  ];

  private quickAmounts: number[] = [60, 90, 120, 150, 180, 210];

  build() {
    Column({ space: 14 }) {
      // 顶栏标题
      Row() {
        Text('🍼 快速记录喂养')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
        Blank()
        Text('✕')
          .fontSize(20)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .onClick(() => this.controller.close())
      }
      .width('100%')

      // 照护人切换
      CaregiverPicker({ selectedRoleId: $caregiverId })

      // 喂养方式切换（精准控制内边距与字号，绝不折行或省略）
      Row({ space: 6 }) {
        Button('配方奶')
          .fontSize(11)
          .fontWeight(this.feedingType === FeedingType.FORMULA ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.feedingType === FeedingType.FORMULA ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.feedingType === FeedingType.FORMULA ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .height(34)
          .padding({ left: 2, right: 2 })
          .onClick(() => { this.feedingType = FeedingType.FORMULA; })

        Button('母乳亲喂')
          .fontSize(11)
          .fontWeight(this.feedingType === FeedingType.BREASTFEEDING ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.feedingType === FeedingType.BREASTFEEDING ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.feedingType === FeedingType.BREASTFEEDING ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .height(34)
          .padding({ left: 2, right: 2 })
          .onClick(() => { this.feedingType = FeedingType.BREASTFEEDING; })

        Button('母乳瓶喂')
          .fontSize(11)
          .fontWeight(this.feedingType === FeedingType.BOTTLE ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.feedingType === FeedingType.BOTTLE ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.feedingType === FeedingType.BOTTLE ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .height(34)
          .padding({ left: 2, right: 2 })
          .onClick(() => { this.feedingType = FeedingType.BOTTLE; })

        Button('辅食')
          .fontSize(11)
          .fontWeight(this.feedingType === FeedingType.SOLIDS ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.feedingType === FeedingType.SOLIDS ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.feedingType === FeedingType.SOLIDS ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .height(34)
          .padding({ left: 2, right: 2 })
          .onClick(() => { this.feedingType = FeedingType.SOLIDS; })
      }
      .width('100%')

      // --- 配方奶字段 ---
      if (this.feedingType === FeedingType.FORMULA) {
        Column({ space: 10 }) {
          // 段位选择
          Row({ space: 6 }) {
            ForEach(this.stages, (st: FormulaStage) => {
              Text(st.substring(0, 2))
                .fontSize(12)
                .fontWeight(this.selectedStage === st ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedStage === st ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedStage === st ? AppConstants.COLOR_PRIMARY_LIGHT : '#F7FAFC')
                .borderRadius(8)
                .border({ width: 1, color: this.selectedStage === st ? AppConstants.COLOR_PRIMARY : '#E2E8F0' })
                .onClick(() => { this.selectedStage = st; })
            }, (st: FormulaStage) => st)
          }

          // 奶量快捷选
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.quickAmounts, (amt: number) => {
              Text(`${amt}ml`)
                .fontSize(12)
                .fontWeight(this.amount === amt ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.amount === amt ? Color.White : AppConstants.COLOR_TEXT_MAIN)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .margin({ right: 6, bottom: 6 })
                .backgroundColor(this.amount === amt ? AppConstants.COLOR_PRIMARY : '#F7FAFC')
                .borderRadius(12)
                .onClick(() => {
                  this.amount = amt;
                  this.waterAmount = amt;
                  this.scoops = Math.round(amt / 30);
                })
            }, (amt: number) => amt.toString())
          }
          .width('100%')

          // 冲调微调
          Row({ space: 12 }) {
            Text(`总奶量: ${this.amount} ml`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_PRIMARY)
            Text(`(约 ${this.scoops} 勺 / ${this.waterAmount}ml 水)`)
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      // --- 母乳亲喂字段 ---
      if (this.feedingType === FeedingType.BREASTFEEDING) {
        Column({ space: 10 }) {
          Row({ space: 16 }) {
            Column({ space: 4 }) {
              Text('左侧时长 (分)')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
              TextInput({ text: this.leftDuration.toString() })
                .type(InputType.Number)
                .width(100)
                .onChange((val: string) => {
                  this.leftDuration = parseInt(val) || 0;
                })
            }

            Column({ space: 4 }) {
              Text('右侧时长 (分)')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
              TextInput({ text: this.rightDuration.toString() })
                .type(InputType.Number)
                .width(100)
                .onChange((val: string) => {
                  this.rightDuration = parseInt(val) || 0;
                })
            }
          }
          Text(`总计时长: ${this.leftDuration + this.rightDuration} 分钟`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_PRIMARY)
        }
        .alignItems(HorizontalAlign.Start)
      }

      // --- 辅食字段 ---
      if (this.feedingType === FeedingType.SOLIDS) {
        Column({ space: 8 }) {
          TextInput({ placeholder: '辅食名称（如：婴儿米粉、南瓜泥）', text: this.solidsName })
            .fontSize(13)
            .onChange((v: string) => { this.solidsName = v; })

          Row({ space: 8 }) {
            Checkbox()
              .select(this.isNewFood)
              .onChange((v: boolean) => { this.isNewFood = v; })
            Text('首次添加新食材（重点观察过敏）')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
        }
      }

      // 备注输入
      TextInput({ placeholder: '备注：如拍嗝情况、吐奶、情绪...', text: this.notes })
        .fontSize(13)
        .onChange((v: string) => { this.notes = v; })

      // 保存按钮
      Button('保存记录 (单手秒存)')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(AppConstants.COLOR_PRIMARY)
        .onClick(() => {
          const db = DatabaseHelper.getInstance();
          const baby = db.getCurrentBaby();
          const rec = new FeedingRecord();
          rec.id = 'feed_' + Date.now();
          rec.babyId = baby.id;
          rec.recordTime = Date.now();
          rec.feedingType = this.feedingType;
          rec.caregiverId = this.caregiverId;
          rec.notes = this.notes;

          if (this.feedingType === FeedingType.FORMULA) {
            rec.amount = this.amount;
            rec.amountUnit = 'ml';
            rec.formulaStage = this.selectedStage;
            rec.scoops = this.scoops;
            rec.waterAmount = this.waterAmount;
          } else if (this.feedingType === FeedingType.BREASTFEEDING) {
            rec.leftDuration = this.leftDuration;
            rec.rightDuration = this.rightDuration;
            rec.amount = this.leftDuration + this.rightDuration;
            rec.amountUnit = '分钟';
          } else if (this.feedingType === FeedingType.BOTTLE) {
            rec.amount = this.amount;
            rec.amountUnit = 'ml';
          } else if (this.feedingType === FeedingType.SOLIDS) {
            rec.solidsName = this.solidsName || '宝宝辅食';
            rec.isNewFood = this.isNewFood ? 1 : 0;
            rec.amount = 50;
            rec.amountUnit = 'g';
          }

          db.addFeedingRecord(rec);
          if (this.onSuccess) {
            this.onSuccess();
          }
          this.controller.close();
        })
    }
    .padding(20)
    .backgroundColor(AppConstants.COLOR_CARD_BG)
    .borderRadius(20)
    .width('92%')
  }
}
