import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper, RoutineItem } from '../../common/database/DatabaseHelper';
import promptAction from '@ohos.promptAction';

interface PresetRoutine {
  time: string;
  emoji: string;
  title: string;
  notes: string;
  colorTheme: string;
}

/**
 * 添加宝宝作息安排弹窗（紧凑高度设计，杜绝键盘弹起时弹窗被压缩变小）
 */
@CustomDialog
export struct AddRoutineDialog {
  controller: CustomDialogController;
  onSuccess?: () => void;

  @State timeStr: string = '07:00';
  @State emojiStr: string = '🌅';
  @State titleStr: string = '晨起喝奶';
  @State notesStr: string = '配方奶/亲喂 150ml · 晒太阳/抚触';
  @State selectedTheme: string = 'peach';

  private readonly presets: PresetRoutine[] = [
    { time: '07:00', emoji: '🌅', title: '晨起喝奶', notes: '配方奶/亲喂 150ml · 晒太阳/抚触', colorTheme: 'peach' },
    { time: '09:00', emoji: '☀️', title: '晨间小睡', notes: '小睡约 1~1.5 小时 · 保持安静遮光', colorTheme: 'purple' },
    { time: '11:30', emoji: '🥣', title: '辅食或喂奶', notes: '米粉/南瓜泥 + 奶量补足', colorTheme: 'blue' },
    { time: '13:00', emoji: '😴', title: '午后小睡', notes: '深度小睡 1.5~2 小时', colorTheme: 'purple' },
    { time: '16:00', emoji: '🎈', title: '亲子活动', notes: '趴卧抬头/黑白卡/亲子早教', colorTheme: 'amber' },
    { time: '19:30', emoji: '🛁', title: '沐浴抚触', notes: '温水洗澡 10 分钟 · 全身抚触', colorTheme: 'teal' },
    { time: '20:30', emoji: '🌙', title: '入睡程序', notes: '洗澡 · 抚触 · 奶睡/自主入眠', colorTheme: 'teal' }
  ];

  private readonly themes: string[] = ['peach', 'purple', 'blue', 'teal', 'amber'];

  private getThemeColor(theme: string): string {
    switch (theme) {
      case 'purple': return '#805AD5';
      case 'blue': return '#3182CE';
      case 'teal': return '#319795';
      case 'amber': return '#D69E2E';
      case 'peach':
      default: return '#FF7A59';
    }
  }

  private handleSelectPreset(preset: PresetRoutine): void {
    this.timeStr = preset.time;
    this.emojiStr = preset.emoji;
    this.titleStr = preset.title;
    this.notesStr = preset.notes;
    this.selectedTheme = preset.colorTheme;
  }

  private handleSave(): void {
    if (!this.titleStr.trim()) {
      try {
        promptAction.showToast({ message: '请输入作息事项标题' });
      } catch (e) {}
      return;
    }

    if (!this.timeStr.trim()) {
      try {
        promptAction.showToast({ message: '请输入作息时间（如 08:00）' });
      } catch (e) {}
      return;
    }

    const db = DatabaseHelper.getInstance();
    const item: RoutineItem = {
      id: 'routine_' + Date.now(),
      babyId: db.getCurrentBaby().id,
      time: this.timeStr.trim(),
      emoji: this.emojiStr.trim() || '⏰',
      title: this.titleStr.trim(),
      notes: this.notesStr.trim(),
      colorTheme: this.selectedTheme,
      createdAt: Date.now()
    };

    db.addRoutine(item);

    try {
      promptAction.showToast({ message: `已添加「${item.title}」作息` });
    } catch (e) {}

    if (this.onSuccess) {
      this.onSuccess();
    }
    this.controller.close();
  }

  build() {
    Column({ space: 10 }) {
      // 1. 标题栏
      Row() {
        Row({ space: 6 }) {
          Text('⏰')
            .fontSize(17)
          Text('添加宝宝作息安排')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
        }
        Blank()
        Text('✕')
          .fontSize(16)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .padding(4)
          .onClick(() => {
            this.controller.close();
          })
      }
      .width('100%')

      // 2. 常用推荐作息（单行横向滑动手势，高度仅30vp，绝不堆叠挤占垂直空间）
      List({ space: 6 }) {
        ForEach(this.presets, (item: PresetRoutine) => {
          ListItem() {
            Text(`${item.emoji} ${item.title}`)
              .fontSize(12)
              .fontWeight(this.titleStr === item.title ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.titleStr === item.title ? Color.White : AppConstants.COLOR_TEXT_MAIN)
              .backgroundColor(this.titleStr === item.title ? AppConstants.COLOR_PRIMARY : '#F5F5F5')
              .borderRadius(14)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .onClick(() => {
                this.handleSelectPreset(item);
              })
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .height(30)
      .width('100%')

      // 3. 作息事项 + 时间 + 图标（高效单排整合）
      Row({ space: 8 }) {
        // 事项名称
        Column({ space: 3 }) {
          Text('作息事项')
            .fontSize(11)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          TextInput({ text: this.titleStr, placeholder: '如：晨起喝奶' })
            .height(38)
            .fontSize(13)
            .backgroundColor('#F7FAFC')
            .borderRadius(8)
            .border({ width: 1, color: AppConstants.COLOR_BORDER })
            .padding({ left: 10, right: 10 })
            .onChange((v: string) => {
              this.titleStr = v;
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 时间
        Column({ space: 3 }) {
          Text('时间')
            .fontSize(11)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          TextInput({ text: this.timeStr, placeholder: '08:00' })
            .height(38)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColor(this.selectedTheme))
            .backgroundColor('#F7FAFC')
            .borderRadius(8)
            .border({ width: 1, color: AppConstants.COLOR_BORDER })
            .padding({ left: 8, right: 8 })
            .onChange((v: string) => {
              this.timeStr = v;
            })
        }
        .width(76)
        .alignItems(HorizontalAlign.Start)

        // 图标
        Column({ space: 3 }) {
          Text('图标')
            .fontSize(11)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          TextInput({ text: this.emojiStr, placeholder: '⏰' })
            .height(38)
            .fontSize(14)
            .textAlign(TextAlign.Center)
            .backgroundColor('#F7FAFC')
            .borderRadius(8)
            .border({ width: 1, color: AppConstants.COLOR_BORDER })
            .onChange((v: string) => {
              this.emojiStr = v;
            })
        }
        .width(48)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // 4. 详情与建议（选填）
      Column({ space: 3 }) {
        Text('详情与建议（选填）')
          .fontSize(11)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .width('100%')

        TextInput({ text: this.notesStr, placeholder: '如：配方奶/亲喂 150ml · 晒太阳/抚触' })
          .height(38)
          .fontSize(12)
          .backgroundColor('#F7FAFC')
          .borderRadius(8)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })
          .padding({ left: 10, right: 10 })
          .width('100%')
          .onChange((v: string) => {
            this.notesStr = v;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 5. 卡片色系
      Row({ space: 8 }) {
        Text('卡片色系')
          .fontSize(11)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)

        ForEach(this.themes, (th: string) => {
          Circle({ width: 20, height: 20 })
            .fill(this.getThemeColor(th))
            .stroke(this.selectedTheme === th ? AppConstants.COLOR_TEXT_MAIN : Color.Transparent)
            .strokeWidth(2)
            .onClick(() => {
              this.selectedTheme = th;
            })
        })
      }
      .width('100%')

      // 6. 操作按钮
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(13)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .backgroundColor('#F0ECE1')
          .height(40)
          .layoutWeight(1)
          .borderRadius(20)
          .onClick(() => {
            this.controller.close();
          })

        Button('保存作息')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(AppConstants.COLOR_PRIMARY)
          .height(40)
          .layoutWeight(2)
          .borderRadius(20)
          .shadow({ radius: 6, color: 'rgba(255, 122, 89, 0.35)', offsetY: 2 })
          .onClick(() => {
            this.handleSave();
          })
      }
      .width('100%')
      .margin({ top: 2 })
    }
    .width('90%')
    .padding({ left: 18, right: 18, top: 16, bottom: 16 })
    .backgroundColor(Color.White)
    .borderRadius(20)
  }
}
