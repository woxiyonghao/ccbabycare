import router from '@ohos.router';
import { AppConstants } from '../../common/constants/AppConstants';

export interface CategoryCardItem {
  key: string;
  icon: string;
  title: string;
  desc: string;
  bgColor: string;
}

/**
 * 全部分类快捷记录面板（涵盖喂养、排便、睡眠、成长、疫苗、账本、作息、寄语）
 */
@CustomDialog
export struct AllCategoriesDialog {
  controller: CustomDialogController;
  onSelectCategory?: (key: string) => void;

  private readonly categories: CategoryCardItem[] = [
    { key: 'feeding', icon: '🍼', title: '喂养记录', desc: '配方奶/母乳亲喂/瓶喂/辅食', bgColor: '#FFF5F2' },
    { key: 'elimination', icon: '💩', title: '排便排尿', desc: '性状颜色/换尿布/异常标记', bgColor: '#E6FFFA' },
    { key: 'sleep', icon: '🌙', title: '睡眠记录', desc: '晨间小睡/夜长觉/惊醒安抚', bgColor: '#FAF5FF' },
    { key: 'growth', icon: '📈', title: '成长体检', desc: '身高/体重/头围/生长曲线', bgColor: '#EBF8FF' },
    { key: 'vaccine', icon: '💉', title: '疫苗档案', desc: '国家免费一类与二类自费接种', bgColor: '#F0FFF4' },
    { key: 'expense', icon: '💰', title: '养娃账本', desc: '奶粉/纸尿裤/营养等开支记账', bgColor: '#FFFBF0' },
    { key: 'routine', icon: '⏰', title: '规律作息', desc: '科学吃玩睡推荐节律与安排', bgColor: '#FDF2F8' },
    { key: 'message', icon: '💌', title: '父母寄语', desc: '写给宝贝的成长爱心便签与祝福', bgColor: '#FFF7ED' }
  ];

  build() {
    Column({ space: 14 }) {
      // 顶栏
      Row() {
        Row({ space: 6 }) {
          Text('📋')
            .fontSize(18)
          Column({ space: 2 }) {
            Text('全部分类记录导航')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
            Text('点击任意分类，即刻开启快捷记录')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
        }
        Blank()
        Text('✕')
          .fontSize(18)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .padding(4)
          .onClick(() => this.controller.close())
      }
      .width('100%')

      // 分类网格（2列整齐布局，点击秒开对应记录）
      Grid() {
        ForEach(this.categories, (item: CategoryCardItem) => {
          GridItem() {
            Row({ space: 10 }) {
              Text(item.icon)
                .fontSize(24)
              Column({ space: 2 }) {
                Text(item.title)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)
                Text(item.desc)
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  .maxLines(1)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 12, right: 10, top: 10, bottom: 10 })
            .backgroundColor(item.bgColor)
            .borderRadius(12)
            .onClick(() => {
              this.controller.close();
              if (this.onSelectCategory) {
                this.onSelectCategory(item.key);
              }
            })
          }
        }, (item: CategoryCardItem) => item.key)
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      .height(230)

      // 跳转排序调整
      Row({ space: 4 }) {
        Text('⚙️')
          .fontSize(13)
        Text('拖拽排序与调整首页展示 ›')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppConstants.COLOR_PRIMARY)
      }
      .padding({ top: 4, bottom: 2 })
      .onClick(() => {
        this.controller.close();
        router.pushUrl({ url: 'pages/record/CategorySortPage' });
      })
    }
    .width('92%')
    .padding(18)
    .backgroundColor(Color.White)
    .borderRadius(20)
  }
}
