import { AppConstants } from '../../common/constants/AppConstants';
import { EliminationType, StoolTexture, StoolColor, EliminationVolume } from '../../common/constants/FeedingConstants';
import { EliminationRecord } from '../../common/models/EliminationRecord';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { CaregiverPicker } from '../../common/components/CaregiverPicker';

/**
 * 极速排便排尿与换尿布弹窗
 */
@CustomDialog
export struct EliminationRecordDialog {
  controller: CustomDialogController;
  onSuccess?: () => void;

  @State eliminationType: EliminationType = EliminationType.POOP;
  @State stoolTexture: StoolTexture = StoolTexture.SOFT;
  @State stoolColor: StoolColor = StoolColor.GOLDEN;
  @State volume: EliminationVolume = EliminationVolume.MEDIUM;
  @State isAbnormal: boolean = false;
  @State caregiverId: string = 'MOM';
  @State notes: string = '';

  private textures: StoolTexture[] = [
    StoolTexture.SOFT,
    StoolTexture.PASTY,
    StoolTexture.WATERY,
    StoolTexture.HARD,
    StoolTexture.FORMED
  ];

  private colors: StoolColor[] = [
    StoolColor.GOLDEN,
    StoolColor.YELLOW_GREEN,
    StoolColor.DARK_GREEN,
    StoolColor.BROWN,
    StoolColor.BLOOD_STREAK,
    StoolColor.ABNORMAL
  ];

  build() {
    Column({ space: 14 }) {
      // 顶栏
      Row() {
        Text('💩 快速记录排泄 / 换尿布')
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

      // 排泄类型
      Row({ space: 8 }) {
        Button('便便 💩')
          .fontSize(12)
          .fontWeight(this.eliminationType === EliminationType.POOP ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.eliminationType === EliminationType.POOP ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.eliminationType === EliminationType.POOP ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .onClick(() => { this.eliminationType = EliminationType.POOP; })

        Button('嘘嘘 💧')
          .fontSize(12)
          .fontWeight(this.eliminationType === EliminationType.PEE ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.eliminationType === EliminationType.PEE ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.eliminationType === EliminationType.PEE ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .onClick(() => { this.eliminationType = EliminationType.PEE; })

        Button('混合 💩+💧')
          .fontSize(12)
          .fontWeight(this.eliminationType === EliminationType.MIXED ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.eliminationType === EliminationType.MIXED ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
          .fontColor(this.eliminationType === EliminationType.MIXED ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .onClick(() => { this.eliminationType = EliminationType.MIXED; })
      }
      .width('100%')

      // 便便性状选择
      if (this.eliminationType !== EliminationType.PEE) {
        Column({ space: 6 }) {
          Text('便便性状：')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          Row({ space: 6 }) {
            ForEach(this.textures, (t: StoolTexture) => {
              Text(t)
                .fontSize(11)
                .fontWeight(this.stoolTexture === t ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.stoolTexture === t ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MAIN)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(this.stoolTexture === t ? AppConstants.COLOR_PRIMARY_LIGHT : '#F7FAFC')
                .borderRadius(8)
                .border({ width: 1, color: this.stoolTexture === t ? AppConstants.COLOR_PRIMARY : '#E2E8F0' })
                .onClick(() => { this.stoolTexture = t; })
            }, (t: StoolTexture) => t)
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      // 便便颜色选择
      if (this.eliminationType !== EliminationType.PEE) {
        Column({ space: 6 }) {
          Text('便便颜色：')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          Row({ space: 6 }) {
            ForEach(this.colors, (c: StoolColor) => {
              Text(c)
                .fontSize(11)
                .fontWeight(this.stoolColor === c ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.stoolColor === c ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MAIN)
                .padding({ left: 6, right: 6, top: 4, bottom: 4 })
                .backgroundColor(this.stoolColor === c ? AppConstants.COLOR_PRIMARY_LIGHT : '#F7FAFC')
                .borderRadius(8)
                .border({ width: 1, color: this.stoolColor === c ? AppConstants.COLOR_PRIMARY : '#E2E8F0' })
                .onClick(() => {
                  this.stoolColor = c;
                  if (c === StoolColor.BLOOD_STREAK || c === StoolColor.ABNORMAL) {
                    this.isAbnormal = true;
                  }
                })
            }, (c: StoolColor) => c)
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      // 异常警示标记勾选
      Row({ space: 8 }) {
        Checkbox()
          .select(this.isAbnormal)
          .selectedColor(AppConstants.COLOR_DANGER)
          .onChange((v: boolean) => { this.isAbnormal = v; })
        Text('标记为异常情况 (如血丝、果酱状、腹泻)')
          .fontSize(12)
          .fontWeight(this.isAbnormal ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.isAbnormal ? AppConstants.COLOR_DANGER : AppConstants.COLOR_TEXT_MUTED)
      }

      // 备注
      TextInput({ placeholder: '备注（如：气味、泡沫、换纸尿裤情况）', text: this.notes })
        .fontSize(13)
        .onChange((v: string) => { this.notes = v; })

      // 保存
      Button('保存记录')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.isAbnormal ? AppConstants.COLOR_DANGER : AppConstants.COLOR_PRIMARY)
        .onClick(() => {
          const db = DatabaseHelper.getInstance();
          const baby = db.getCurrentBaby();
          const rec = new EliminationRecord();
          rec.id = 'elim_' + Date.now();
          rec.babyId = baby.id;
          rec.recordTime = Date.now();
          rec.eliminationType = this.eliminationType;
          rec.stoolTexture = this.stoolTexture;
          rec.stoolColor = this.stoolColor;
          rec.volume = this.volume;
          rec.isAbnormal = this.isAbnormal ? 1 : 0;
          rec.caregiverId = this.caregiverId;
          rec.notes = this.notes;

          db.addEliminationRecord(rec);
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
