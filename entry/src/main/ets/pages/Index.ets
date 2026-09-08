import { AppConstants } from '../common/constants/AppConstants';
import { HomePage } from './home/HomePage';
import { RecordHubPage } from './record/RecordHubPage';
import { DiaryBookPage } from './diary/DiaryBookPage';
import { StatisticsPage } from './statistics/StatisticsPage';
import { ProfilePage } from './profile/ProfilePage';

interface TabItemConfig {
  index: number;
  icon: string;
  title: string;
}

/**
 * 主程序入口：五大核心导航
 * 底部采用类似华为相册的悬浮毛玻璃胶囊风格（保持萌宝暖橙主色调）
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  private tabItems: TabItemConfig[] = [
    { index: 0, icon: '🍼', title: '首页' },
    { index: 1, icon: '📝', title: '记录' },
    { index: 2, icon: '📖', title: '日记本' },
    { index: 3, icon: '📈', title: '成长' },
    { index: 4, icon: '⚙️', title: '档案' }
  ];

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 内容区域：使用 Tabs 配合隐藏原生底栏
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
        TabContent() {
          HomePage()
        }

        TabContent() {
          RecordHubPage()
        }

        TabContent() {
          DiaryBookPage()
        }

        TabContent() {
          StatisticsPage()
        }

        TabContent() {
          ProfilePage()
        }
      }
      .scrollable(false)
      .barHeight(0) // 隐藏系统默认直角全宽底栏
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
      .padding({ bottom: 76 }) // 为底部悬浮胶囊预留间距，避免遮挡内容

      // 华为相册同款悬浮毛玻璃胶囊导航栏（保持温暖桃橙主色系）
      Row({ space: 4 }) {
        ForEach(this.tabItems, (item: TabItemConfig) => {
          Column({ space: 2 }) {
            Text(item.icon)
              .fontSize(18)
              .scale({
                x: this.currentIndex === item.index ? 1.15 : 1.0,
                y: this.currentIndex === item.index ? 1.15 : 1.0
              })
              .animation({ duration: 200, curve: Curve.EaseInOut })

            Text(item.title)
              .fontSize(11)
              .fontWeight(this.currentIndex === item.index ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentIndex === item.index ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .borderRadius(22)
          .backgroundColor(this.currentIndex === item.index ? 'rgba(255, 123, 84, 0.12)' : Color.Transparent)
          .onClick(() => {
            this.currentIndex = item.index;
            this.tabsController.changeIndex(item.index);
          })
        }, (item: TabItemConfig) => item.index.toString())
      }
      .width('90%')
      .height(58)
      .padding({ left: 6, right: 6, top: 4, bottom: 4 })
      .borderRadius(29) // 胶囊圆角
      .backgroundColor('rgba(255, 255, 255, 0.76)') // 半透明底色
      .backgroundBlurStyle(BlurStyle.Thin)           // 华为系统原生毛玻璃模糊特效
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.08)',
        offsetX: 0,
        offsetY: 4
      })
      .border({
        width: 1,
        color: 'rgba(255, 255, 255, 0.85)'
      })
      .margin({ bottom: 18 }) // 悬浮距底边距
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}