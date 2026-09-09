import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper, ParentsMessageItem } from '../../common/database/DatabaseHelper';
import promptAction from '@ohos.promptAction';

/**
 * 写下父母寄语弹窗（紧凑高度设计，杜绝键盘弹起时弹窗被压缩变小）
 */
@CustomDialog
export struct AddParentsMessageDialog {
  controller: CustomDialogController;
  onSuccess?: () => void;

  @State contentStr: string = '';
  @State signatureStr: string = '永远爱你的爸爸妈妈';

  private readonly quickPrompts: string[] = [
    '健康平安，快乐成长 🌱',
    '永远做你坚强的后盾与温暖港湾 🏡',
    '今天你第一次冲我笑了，那一刻世界都融化了 💕',
    '大口喝奶、香香睡觉，每天都在悄悄长大 🍼'
  ];

  private handleSave(): void {
    if (!this.contentStr.trim()) {
      try {
        promptAction.showToast({ message: '请写下对宝宝的寄语' });
      } catch (e) {}
      return;
    }

    const db = DatabaseHelper.getInstance();
    const item: ParentsMessageItem = {
      id: 'msg_' + Date.now(),
      babyId: db.getCurrentBaby().id,
      content: this.contentStr.trim().slice(0, 200),
      signature: (this.signatureStr.trim() || '永远爱你的爸爸妈妈').slice(0, 12),
      createdAt: Date.now()
    };

    db.addParentsMessage(item);

    try {
      promptAction.showToast({ message: '已存入成长手绘日记' });
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
          Text('💌')
            .fontSize(17)
          Text('写下给宝贝的寄语')
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

      // 2. 温暖灵感（单行横向滑动手势，高度仅30vp，绝不堆叠占用垂直高度）
      List({ space: 6 }) {
        ForEach(this.quickPrompts, (prompt: string) => {
          ListItem() {
            Text(prompt)
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
              .backgroundColor('#FFF5F2')
              .borderRadius(14)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .onClick(() => {
                let combined = '';
                if (this.contentStr.trim()) {
                  combined = this.contentStr + '\n' + prompt;
                } else {
                  combined = prompt;
                }
                if (combined.length > 200) {
                  combined = combined.slice(0, 200);
                  try {
                    promptAction.showToast({ message: '寄语内容最多输入200字' });
                  } catch (e) {}
                }
                this.contentStr = combined;
              })
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .height(30)
      .width('100%')

      // 3. 寄语正文输入框（限制200字，适度高度72vp，保障软键盘弹起有充足留白）
      Column({ space: 3 }) {
        Row() {
          Text('寄语内容')
            .fontSize(11)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          Blank()
          Text(`${this.contentStr.length}/200字`)
            .fontSize(11)
            .fontColor(this.contentStr.length >= 200 ? AppConstants.COLOR_DANGER : AppConstants.COLOR_TEXT_MUTED)
        }
        .width('100%')

        TextArea({ text: this.contentStr, placeholder: '写下想对宝贝说的话、今天的成长感动或美好期许...' })
          .maxLength(200)
          .height(72)
          .fontSize(13)
          .lineHeight(19)
          .backgroundColor('#FFFBF5')
          .border({ width: 1, color: '#FFD4C2' })
          .borderRadius(8)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .onChange((v: string) => {
            this.contentStr = v.length > 200 ? v.slice(0, 200) : v;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 4. 署名落款（限制12字）
      Column({ space: 3 }) {
        Row() {
          Text('落款署名')
            .fontSize(11)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          Blank()
          Text(`${this.signatureStr.length}/12字`)
            .fontSize(11)
            .fontColor(this.signatureStr.length >= 12 ? AppConstants.COLOR_DANGER : AppConstants.COLOR_TEXT_MUTED)
        }
        .width('100%')

        TextInput({ text: this.signatureStr, placeholder: '永远爱你的爸爸妈妈' })
          .maxLength(12)
          .height(38)
          .fontSize(13)
          .backgroundColor('#F7FAFC')
          .borderRadius(8)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })
          .padding({ left: 10, right: 10 })
          .width('100%')
          .onChange((v: string) => {
            this.signatureStr = v.length > 12 ? v.slice(0, 12) : v;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 5. 操作按钮
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

        Button('存入日记')
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
