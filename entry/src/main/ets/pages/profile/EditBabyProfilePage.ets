import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppConstants } from '../../common/constants/AppConstants';
import { BabyModel } from '../../common/models/BabyModel';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { ArrowIcon } from '../../common/components/ArrowIcon';

/**
 * 独立页面：编辑宝宝档案
 * 支持修改宝宝昵称、性别、出生体重、出生身长、血型与头像
 */
@Entry
@Component
struct EditBabyProfilePage {
  @State name: string = '';
  @State gender: string = 'boy';
  @State birthWeightStr: string = '';
  @State birthHeightStr: string = '';
  @State bloodType: string = 'O';
  @State avatar: string = '👶';
  @State notes: string = '';
  @State isFirstSetup: boolean = false;

  private bloodOptions: string[] = ['A', 'B', 'AB', 'O', '未知'];
  private avatarOptions: string[] = ['👶', '👦', '👧', '🍼', '👼', '🧸', '🦁', '🐰', '🐼'];

  aboutToAppear() {
    let isFirst = !DatabaseHelper.getInstance().hasUserData();
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params && params['isFirstSetup'] !== undefined) {
        isFirst = params['isFirstSetup'] as boolean;
      }
    } catch (e) {}
    this.isFirstSetup = isFirst;

    if (this.isFirstSetup) {
      // 首次创建：全新空白表单，绝不填入任何伪造/默认数值
      this.name = '';
      this.gender = 'boy';
      this.birthWeightStr = '';
      this.birthHeightStr = '';
      this.bloodType = '未知';
      this.avatar = '👶';
      this.notes = '';
    } else {
      // 修改已有：从当前宝宝档案载入
      const baby = DatabaseHelper.getInstance().getCurrentBaby();
      if (baby.name) {
        this.name = baby.name.length > 6 ? baby.name.substring(0, 6) : baby.name;
      } else {
        this.name = '';
      }
      this.gender = baby.gender || 'boy';
      this.birthWeightStr = baby.birthWeight > 0 ? baby.birthWeight.toString() : '';
      this.birthHeightStr = baby.birthHeight > 0 ? baby.birthHeight.toString() : '';
      this.bloodType = baby.bloodType || '未知';
      this.avatar = baby.avatar || '👶';
      if (baby.notes) {
        this.notes = baby.notes.length > 100 ? baby.notes.substring(0, 100) : baby.notes;
      } else {
        this.notes = '';
      }
    }
  }

  private handleSave(): void {
    const trimmedName = this.name.trim();
    if (!trimmedName) {
      try {
        promptAction.showToast({ message: '请输入宝宝昵称' });
      } catch (e) {}
      return;
    }

    if (trimmedName.length > 6) {
      try {
        promptAction.showToast({ message: '宝宝昵称不能超过6个字' });
      } catch (e) {}
      return;
    }

    if (this.notes.length > 100) {
      try {
        promptAction.showToast({ message: '注意事项与备注不能超过100个字' });
      } catch (e) {}
      return;
    }

    const w = parseFloat(this.birthWeightStr) || 0;
    const h = parseFloat(this.birthHeightStr) || 0;

    if (this.isFirstSetup) {
      const newBaby = new BabyModel(
        `baby_${Date.now()}`,
        trimmedName,
        Date.now(), // 出生日期默认为当前（0天），不预置虚拟月龄
        this.gender,
        w,
        h,
        this.bloodType || '未知',
        this.avatar || '👶',
        this.notes.trim(),
        1,
        Date.now()
      );
      DatabaseHelper.getInstance().addBaby(newBaby);
      try {
        promptAction.showToast({ message: '宝宝档案已创建，开启记录之旅' });
      } catch (e) {}
      try {
        router.replaceUrl({
          url: 'pages/Index'
        });
      } catch (e) {
        console.warn('router.replaceUrl error:', JSON.stringify(e));
      }
    } else {
      const baby = DatabaseHelper.getInstance().getCurrentBaby();
      baby.name = trimmedName;
      baby.gender = this.gender;
      baby.birthWeight = w;
      baby.birthHeight = h;
      baby.bloodType = this.bloodType;
      baby.avatar = this.avatar;
      baby.notes = this.notes.trim();

      DatabaseHelper.getInstance().updateBaby(baby);
      try {
        promptAction.showToast({ message: '宝宝档案已成功更新' });
      } catch (e) {}
      try {
        router.back();
      } catch (e) {
        console.warn('router.back error:', JSON.stringify(e));
      }
    }
  }

  build() {
    Column() {
      // 1. 顶栏导航
      Row({ space: 12 }) {
        if (!this.isFirstSetup) {
          Row() {
            ArrowIcon({ arrowDirection: 'left', variant: 'dark', iconSize: 18 })
          }
          .width(36)
          .height(36)
          .justifyContent(FlexAlign.Center)
          .borderRadius(18)
          .backgroundColor('rgba(0, 0, 0, 0.05)')
          .onClick(() => {
            router.back();
          })
        }

        Column({ space: 2 }) {
          Text(this.isFirstSetup ? '设置宝宝档案' : '编辑宝宝档案')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
          if (this.isFirstSetup) {
            Text('欢迎使用！请先设置宝宝档案开始记录成长')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 2. 表单内容区
      Scroll() {
        Column({ space: 16 }) {
          // 头像选择
          Column({ space: 8 }) {
            Text('选择宝宝头像')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.avatarOptions, (av: string) => {
                Text(av)
                  .fontSize(28)
                  .padding(8)
                  .margin({ right: 10, bottom: 8 })
                  .backgroundColor(this.avatar === av ? AppConstants.COLOR_PRIMARY_LIGHT : '#F7FAFC')
                  .borderRadius(16)
                  .border({
                    width: 2,
                    color: this.avatar === av ? AppConstants.COLOR_PRIMARY : '#E2E8F0'
                  })
                  .onClick(() => {
                    this.avatar = av;
                  })
              }, (av: string) => av)
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })
          .alignItems(HorizontalAlign.Start)

          // 基础信息卡片
          Column({ space: 14 }) {
            // 宝宝昵称（限制最多6个字）
            Column({ space: 6 }) {
              Row() {
                Text('宝宝昵称 *')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                Blank()
                Text(`${this.name.length}/6`)
                  .fontSize(11)
                  .fontColor(this.name.length >= 6 ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
              }
              .width('100%')

              TextInput({ text: this.name, placeholder: '请输入宝宝昵称（最多6个字）' })
                .maxLength(6)
                .height(42)
                .fontSize(15)
                .backgroundColor('#F7FAFC')
                .borderRadius(10)
                .onChange((v: string) => {
                  this.name = v.length > 6 ? v.substring(0, 6) : v;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 性别
            Column({ space: 6 }) {
              Text('宝宝性别')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
              Row({ space: 12 }) {
                Button('👦 男童')
                  .fontSize(14)
                  .fontWeight(this.gender === 'boy' ? FontWeight.Bold : FontWeight.Normal)
                  .backgroundColor(this.gender === 'boy' ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
                  .fontColor(this.gender === 'boy' ? Color.White : AppConstants.COLOR_TEXT_MAIN)
                  .layoutWeight(1)
                  .height(40)
                  .onClick(() => { this.gender = 'boy'; })

                Button('👧 女童')
                  .fontSize(14)
                  .fontWeight(this.gender === 'girl' ? FontWeight.Bold : FontWeight.Normal)
                  .backgroundColor(this.gender === 'girl' ? AppConstants.COLOR_PRIMARY : '#F3F4F6')
                  .fontColor(this.gender === 'girl' ? Color.White : AppConstants.COLOR_TEXT_MAIN)
                  .layoutWeight(1)
                  .height(40)
                  .onClick(() => { this.gender = 'girl'; })
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 出生体重与身长
            Row({ space: 12 }) {
              Column({ space: 6 }) {
                Text('出生体重 (kg)')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                TextInput({ text: this.birthWeightStr, placeholder: '如 3.3' })
                  .height(42)
                  .fontSize(14)
                  .type(InputType.Number)
                  .backgroundColor('#F7FAFC')
                  .borderRadius(10)
                  .onChange((v: string) => {
                    this.birthWeightStr = v;
                  })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Column({ space: 6 }) {
                Text('出生身长 (cm)')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                TextInput({ text: this.birthHeightStr, placeholder: '如 50.0' })
                  .height(42)
                  .fontSize(14)
                  .type(InputType.Number)
                  .backgroundColor('#F7FAFC')
                  .borderRadius(10)
                  .onChange((v: string) => {
                    this.birthHeightStr = v;
                  })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')

            // 血型
            Column({ space: 6 }) {
              Text('血型')
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
              Row({ space: 8 }) {
                ForEach(this.bloodOptions, (opt: string) => {
                  Text(opt)
                    .fontSize(13)
                    .fontWeight(this.bloodType === opt ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.bloodType === opt ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .backgroundColor(this.bloodType === opt ? AppConstants.COLOR_PRIMARY_LIGHT : '#F3F4F6')
                    .borderRadius(16)
                    .border({
                      width: 1,
                      color: this.bloodType === opt ? AppConstants.COLOR_PRIMARY : '#E5E7EB'
                    })
                    .onClick(() => {
                      this.bloodType = opt;
                    })
                }, (opt: string) => opt)
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 备注（限制最多100个字）
            Column({ space: 6 }) {
              Row() {
                Text('注意事项与备注')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                Blank()
                Text(`${this.notes.length}/100`)
                  .fontSize(11)
                  .fontColor(this.notes.length >= 100 ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
              }
              .width('100%')

              TextInput({ text: this.notes, placeholder: '如过敏史、注意事项等（最多100个字）' })
                .maxLength(100)
                .height(42)
                .fontSize(14)
                .backgroundColor('#F7FAFC')
                .borderRadius(10)
                .onChange((v: string) => {
                  this.notes = v.length > 100 ? v.substring(0, 100) : v;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 保存按钮
          Button(this.isFirstSetup ? '完成设置，开启记录' : '保存修改')
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppConstants.COLOR_PRIMARY)
            .fontColor(Color.White)
            .borderRadius(23)
            .margin({ top: 10, bottom: 36 })
            .onClick(() => {
              this.handleSave();
            })
        }
        .width('94%')
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
