import { AppConstants } from '../constants/AppConstants';
import { CaregiverConstants } from '../constants/CaregiverConstants';
import { DateUtil } from '../utils/DateUtil';

export interface TimelineData {
  id: string;
  category: string;         // 'FEEDING' | 'ELIMINATION' | 'SLEEP' | 'GROWTH' | 'VACCINE'
  icon: string;
  title: string;
  amountDesc: string;
  detailDesc: string;
  timestamp: number;
  caregiverId: string;
  isAbnormal?: boolean;
}

/**
 * 今日时间轴单条记录卡片（手绘日记风格）
 */
@Component
export struct TimelineItemCard {
  @Prop item: TimelineData;
  onItemClick?: (id: string) => void;

  build() {
    Row({ space: 12 }) {
      // 左侧时间戳
      Column({ space: 2 }) {
        if (this.item.timestamp < DateUtil.getTodayStart() || this.item.timestamp > DateUtil.getTodayEnd()) {
          Text(`${new Date(this.item.timestamp).getMonth() + 1}/${new Date(this.item.timestamp).getDate()}`)
            .fontSize(10)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
        }
        Text(DateUtil.formatTime(this.item.timestamp))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
        Text(this.item.icon)
          .fontSize(20)
      }
      .width(54)
      .alignItems(HorizontalAlign.Center)

      // 右侧信息卡片
      Column({ space: 6 }) {
        Row() {
          Text(this.item.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
          
          Blank()

          // 核心数值突显
          if (this.item.amountDesc) {
            Text(this.item.amountDesc)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_PRIMARY)
          }

          // 照护人标签
          Row({ space: 2 }) {
            Text(CaregiverConstants.getRoleIcon(this.item.caregiverId))
              .fontSize(11)
            Text(CaregiverConstants.getRoleName(this.item.caregiverId))
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
          .margin({ left: 6 })
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#F3F4F6')
          .borderRadius(10)
        }
        .width('100%')

        // 详细描述
        if (this.item.detailDesc) {
          if (this.item.detailDesc.includes('首次添加新食材')) {
            Row({ space: 4 }) {
              Text(this.item.detailDesc)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor('#D97706')
            }
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#FEF3C7')
            .borderRadius(6)
          } else {
            Text(this.item.detailDesc)
              .fontSize(12)
              .fontColor(this.item.isAbnormal ? AppConstants.COLOR_DANGER : AppConstants.COLOR_TEXT_MUTED)
              .lineHeight(16)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding(12)
      .backgroundColor(this.item.isAbnormal ? '#FFF5F5' : AppConstants.COLOR_CARD_BG)
      .borderRadius(14)
      .border({
        width: 1,
        color: this.item.isAbnormal ? '#FEB2B2' : AppConstants.COLOR_BORDER
      })
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.03)', offsetX: 0, offsetY: 2 })
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .onClick(() => {
      if (this.onItemClick) {
        this.onItemClick(this.item.id);
      }
    })
  }
}
