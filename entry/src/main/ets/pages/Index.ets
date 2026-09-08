import { AppConstants } from '../common/constants/AppConstants';
import { HomePage } from './home/HomePage';
import { RecordHubPage } from './record/RecordHubPage';
import { DiaryBookPage } from './diary/DiaryBookPage';
import { StatisticsPage } from './statistics/StatisticsPage';
import { ProfilePage } from './profile/ProfilePage';

/**
 * 主程序入口：五大核心底部导航
 * 1. 首页今日概览
 * 2. 极速记录中心
 * 3. 手绘日记本（花销/作息/寄语）
 * 4. 2026生长曲线与统计
 * 5. 档案与离线备份
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  @Builder
  TabBuilder(index: number, icon: string, title: string) {
    Column({ space: 3 }) {
      Text(icon)
        .fontSize(20)
      Text(title)
        .fontSize(11)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      // Tab 1: 首页
      TabContent() {
        HomePage()
      }
      .tabBar(this.TabBuilder(0, '🍼', '首页'))

      // Tab 2: 记录中心
      TabContent() {
        RecordHubPage()
      }
      .tabBar(this.TabBuilder(1, '📝', '记录'))

      // Tab 3: 手绘日记本
      TabContent() {
        DiaryBookPage()
      }
      .tabBar(this.TabBuilder(2, '📖', '日记本'))

      // Tab 4: 成长统计
      TabContent() {
        StatisticsPage()
      }
      .tabBar(this.TabBuilder(3, '📈', '成长曲线'))

      // Tab 5: 档案设置
      TabContent() {
        ProfilePage()
      }
      .tabBar(this.TabBuilder(4, '⚙️', '我的档案'))
    }
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
    .barHeight(56)
    .barBackgroundColor('#FFFFFF')
    .barMode(BarMode.Fixed)
  }
}