import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { VaccineRecord } from '../../common/models/VaccineRecord';
import promptAction from '@ohos.promptAction';

/**
 * 记一笔疫苗接种弹窗（支持快捷疫苗推荐、剂次、类别、日期、机构及备注输入）
 */
@CustomDialog
export struct AddVaccineDialog {
  controller: CustomDialogController;
  onSuccess?: () => void;

  @State vaccineName: string = '';
  @State selectedDose: string = '第1针';
  @State isFree: number = 1; // 1 一类免费, 0 二类自费
  @State isDone: number = 1; // 1 已接种, 0 待接种
  @State dateStr: string = '';
  @State organization: string = '';
  @State notes: string = '';

  private readonly quickVaccines: string[] = [
    '乙肝疫苗',
    '卡介苗',
    '脊灰疫苗',
    '百白破疫苗',
    '麻腮风疫苗',
    '乙脑减毒疫苗',
    '流脑疫苗',
    '水痘疫苗',
    '13价肺炎',
    '轮状病毒',
    '流感疫苗'
  ];

  private readonly doses: string[] = ['第1针', '第2针', '第3针', '第4针', '加强针'];

  aboutToAppear() {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    this.dateStr = `${year}-${month}-${day}`;
  }

  private handleSave(): void {
    const name = this.vaccineName.trim();
    if (!name) {
      try {
        promptAction.showToast({ message: '请输入或选择疫苗名称' });
      } catch (e) {}
      return;
    }

    const db = DatabaseHelper.getInstance();
    const baby = db.getCurrentBaby();
    const vac = new VaccineRecord(
      'vac_' + Date.now(),
      baby ? baby.id : '',
      name,
      this.selectedDose,
      this.dateStr.trim() || '按期接种'
    );
    vac.isDone = this.isDone;
    vac.isFree = this.isFree;
    vac.vaccinatedDate = this.isDone === 1 ? Date.now() : 0;
    vac.organization = this.organization.trim();
    vac.notes = this.notes.trim();
    vac.createdAt = Date.now();

    db.addVaccineRecord(vac);

    try {
      promptAction.showToast({
        message: `已记录「${name} (${this.selectedDose})」`
      });
    } catch (e) {}

    if (this.onSuccess) {
      this.onSuccess();
    }
    this.controller.close();
  }

  build() {
    Column({ space: 14 }) {
      // 1. 顶栏标题
      Row() {
        Row({ space: 6 }) {
          Text('💉')
            .fontSize(18)
          Text('记一笔疫苗接种')
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

      Scroll() {
        Column({ space: 12 }) {
          // 2. 疫苗名称输入与快捷标签
          Column({ space: 6 }) {
            Text('疫苗名称')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .width('100%')

            TextInput({ placeholder: '例如：乙肝疫苗、卡介苗、水痘等', text: this.vaccineName })
              .fontSize(13)
              .height(40)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F7FAFC')
              .borderRadius(10)
              .border({ width: 1, color: AppConstants.COLOR_BORDER })
              .onChange((val: string) => {
                this.vaccineName = val;
              })

            // 快捷常备疫苗气泡（单行横向滚动，不占纵向高度）
            Scroll() {
              Row({ space: 6 }) {
                ForEach(this.quickVaccines, (vac: string) => {
                  Text(vac)
                    .fontSize(11)
                    .fontWeight(this.vaccineName === vac ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.vaccineName === vac ? Color.White : AppConstants.COLOR_TEXT_MAIN)
                    .backgroundColor(this.vaccineName === vac ? AppConstants.COLOR_PRIMARY : '#F5F5F5')
                    .borderRadius(12)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.vaccineName = vac;
                    })
                })
              }
              .padding({ top: 2, bottom: 2 })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 3. 针次选择
          Column({ space: 6 }) {
            Text('接种剂次')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .width('100%')

            Row({ space: 6 }) {
              ForEach(this.doses, (d: string) => {
                Text(d)
                  .fontSize(11)
                  .fontWeight(this.selectedDose === d ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.selectedDose === d ? Color.White : AppConstants.COLOR_TEXT_MAIN)
                  .backgroundColor(this.selectedDose === d ? AppConstants.COLOR_PRIMARY : '#F5F5F5')
                  .borderRadius(12)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .onClick(() => {
                    this.selectedDose = d;
                  })
              })
            }
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 4. 类别与状态（双胶囊并排）
          Row({ space: 10 }) {
            // 免费 / 自费
            Column({ space: 4 }) {
              Text('疫苗类型')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
              Row({ space: 4 }) {
                Text('免费一类')
                  .fontSize(11)
                  .fontWeight(this.isFree === 1 ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.isFree === 1 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
                  .backgroundColor(this.isFree === 1 ? AppConstants.COLOR_SUCCESS : '#F0ECE1')
                  .borderRadius(10)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .onClick(() => { this.isFree = 1; })

                Text('自费二类')
                  .fontSize(11)
                  .fontWeight(this.isFree === 0 ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.isFree === 0 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
                  .backgroundColor(this.isFree === 0 ? '#DD6B20' : '#F0ECE1')
                  .borderRadius(10)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .onClick(() => { this.isFree = 0; })
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            // 接种状态
            Column({ space: 4 }) {
              Text('当前状态')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
              Row({ space: 4 }) {
                Text('✅ 已接种')
                  .fontSize(11)
                  .fontWeight(this.isDone === 1 ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.isDone === 1 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
                  .backgroundColor(this.isDone === 1 ? AppConstants.COLOR_PRIMARY : '#F0ECE1')
                  .borderRadius(10)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .onClick(() => { this.isDone = 1; })

                Text('⏳ 待接种')
                  .fontSize(11)
                  .fontWeight(this.isDone === 0 ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.isDone === 0 ? Color.White : AppConstants.COLOR_TEXT_MUTED)
                  .backgroundColor(this.isDone === 0 ? AppConstants.COLOR_PRIMARY : '#F0ECE1')
                  .borderRadius(10)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .onClick(() => { this.isDone = 0; })
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          // 5. 日期与接种点
          Row({ space: 8 }) {
            Column({ space: 4 }) {
              Text('接种/推荐日期')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
              TextInput({ placeholder: '如：2026-09-09', text: this.dateStr })
                .fontSize(12)
                .height(38)
                .padding({ left: 8, right: 8 })
                .backgroundColor('#F7FAFC')
                .borderRadius(8)
                .border({ width: 1, color: AppConstants.COLOR_BORDER })
                .onChange((val: string) => {
                  this.dateStr = val;
                })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 4 }) {
              Text('接种机构 (选填)')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
              TextInput({ placeholder: '如：社区卫生服务中心', text: this.organization })
                .fontSize(12)
                .height(38)
                .padding({ left: 8, right: 8 })
                .backgroundColor('#F7FAFC')
                .borderRadius(8)
                .border({ width: 1, color: AppConstants.COLOR_BORDER })
                .onChange((val: string) => {
                  this.organization = val;
                })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          // 6. 备注说明
          Column({ space: 4 }) {
            Text('备注说明 (选填)')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
            TextInput({ placeholder: '接种部位、批号、注意事项等', text: this.notes })
              .fontSize(12)
              .height(38)
              .padding({ left: 8, right: 8 })
              .backgroundColor('#F7FAFC')
              .borderRadius(8)
              .border({ width: 1, color: AppConstants.COLOR_BORDER })
              .onChange((val: string) => {
                this.notes = val;
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .width('100%')
      .constraintSize({ maxHeight: 320 })

      // 7. 操作按钮
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .backgroundColor('#F0ECE1')
          .height(40)
          .layoutWeight(1)
          .borderRadius(20)
          .onClick(() => {
            this.controller.close();
          })

        Button('确认记一笔')
          .fontSize(14)
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
    }
    .width('90%')
    .padding(18)
    .backgroundColor(Color.White)
    .borderRadius(20)
  }
}
