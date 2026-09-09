import { AppConstants } from '../../common/constants/AppConstants';
import { SleepType, FallingAsleepMethod } from '../../common/constants/FeedingConstants';
import { SleepRecord } from '../../common/models/SleepRecord';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { CaregiverPicker } from '../../common/components/CaregiverPicker';

/**
 * 极速睡眠记录弹窗（支持计时与补录）
 */
@CustomDialog
export struct SleepRecordDialog {
  controller: CustomDialogController;
  onSuccess?: () => void;

  @State durationMinutes: number = 60;
  @State sleepType: SleepType = SleepType.NAP;
  @State method: FallingAsleepMethod = FallingAsleepMethod.SELF;
  @State caregiverId: string = 'MOM';
  @State nightWakeCount: number = 0;
  @State notes: string = '';

  private quickDurations: number[] = [30, 45, 60, 90, 120, 180];

  build() {
    Column({ space: 14 }) {
      Row() {
        Text('🌙 快速记录睡眠')
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

      // 睡眠类型
      Row({ space: 10 }) {
        Button('白天小睡 ☀️')
          .fontSize(13)
          .fontWeight(this.sleepType === SleepType.NAP ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.sleepType === SleepType.NAP ? AppConstants.COLOR_SECONDARY : '#F3F4F6')
          .fontColor(this.sleepType === SleepType.NAP ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .onClick(() => { this.sleepType = SleepType.NAP; })

        Button('夜间长觉 🌌')
          .fontSize(13)
          .fontWeight(this.sleepType === SleepType.NIGHT ? FontWeight.Bold : FontWeight.Normal)
          .backgroundColor(this.sleepType === SleepType.NIGHT ? AppConstants.COLOR_SECONDARY : '#F3F4F6')
          .fontColor(this.sleepType === SleepType.NIGHT ? Color.White : AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .onClick(() => { this.sleepType = SleepType.NIGHT; })
      }
      .width('100%')

      // 时长快捷选择
      Column({ space: 6 }) {
        Text('睡眠时长：')
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.quickDurations, (dur: number) => {
            Text(`${dur}分`)
              .fontSize(12)
              .fontWeight(this.durationMinutes === dur ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.durationMinutes === dur ? Color.White : AppConstants.COLOR_TEXT_MAIN)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .margin({ right: 6, bottom: 6 })
              .backgroundColor(this.durationMinutes === dur ? AppConstants.COLOR_SECONDARY : '#F7FAFC')
              .borderRadius(12)
              .onClick(() => {
                this.durationMinutes = dur;
              })
          }, (dur: number) => dur.toString())
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)

      // 入睡方式
      Row({ space: 6 }) {
        Text('入睡方式：')
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
        Text('自主')
          .fontSize(11)
          .padding(6)
          .backgroundColor(this.method === FallingAsleepMethod.SELF ? AppConstants.COLOR_SECONDARY_LIGHT : '#F7FAFC')
          .borderRadius(8)
          .onClick(() => { this.method = FallingAsleepMethod.SELF; })
        Text('抱睡')
          .fontSize(11)
          .padding(6)
          .backgroundColor(this.method === FallingAsleepMethod.HOLDING ? AppConstants.COLOR_SECONDARY_LIGHT : '#F7FAFC')
          .borderRadius(8)
          .onClick(() => { this.method = FallingAsleepMethod.HOLDING; })
        Text('奶睡')
          .fontSize(11)
          .padding(6)
          .backgroundColor(this.method === FallingAsleepMethod.NURSING ? AppConstants.COLOR_SECONDARY_LIGHT : '#F7FAFC')
          .borderRadius(8)
          .onClick(() => { this.method = FallingAsleepMethod.NURSING; })
      }

      // 备注
      TextInput({ placeholder: '备注（如：夜醒2次、哭闹情况）', text: this.notes })
        .fontSize(13)
        .onChange((v: string) => { this.notes = v; })

      // 保存
      Button('保存睡眠记录')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(AppConstants.COLOR_SECONDARY)
        .onClick(() => {
          const db = DatabaseHelper.getInstance();
          const baby = db.getCurrentBaby();
          const now = Date.now();
          const start = now - (this.durationMinutes * 60 * 1000);

          const rec = new SleepRecord();
          rec.id = 'sleep_' + Date.now();
          rec.babyId = baby.id;
          rec.startTime = start;
          rec.endTime = now;
          rec.durationMinutes = this.durationMinutes;
          rec.sleepType = this.sleepType;
          rec.method = this.method;
          rec.nightWakeCount = this.nightWakeCount;
          rec.caregiverId = this.caregiverId;
          rec.notes = this.notes;

          db.addSleepRecord(rec);
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
