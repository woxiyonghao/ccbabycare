import { AppConstants } from '../constants/AppConstants';

export interface QuickRecordItem {
  typeKey: string;
  icon: string;
  label: string;
  bgColor: string;
  fontColor: string;
}

/**
 * 3秒极速记录快捷底栏（专为单手与夜间操作优化）
 */
@Component
export struct QuickRecordBar {
  onSelectAction?: (actionType: string) => void;

  private actionList: QuickRecordItem[] = [
    { typeKey: 'FORMULA', icon: '🍼', label: '配方奶', bgColor: '#FFF2EE', fontColor: '#E65100' },
    { typeKey: 'BREAST', icon: '🤱', label: '亲喂', bgColor: '#FFF8E6', fontColor: '#B7791F' },
    { typeKey: 'DIAPER', icon: '💩', label: '换尿布', bgColor: '#E6FFFA', fontColor: '#234E52' },
    { typeKey: 'SLEEP', icon: '🌙', label: '睡眠', bgColor: '#F4F0FF', fontColor: '#553C9A' },
    { typeKey: 'SOLIDS', icon: '🥣', label: '辅食', bgColor: '#EBF8FF', fontColor: '#2B6CB0' }
  ];

  build() {
    Column() {
      Row({ space: 8 }) {
        ForEach(this.actionList, (item: QuickRecordItem) => {
          Column({ space: 4 }) {
            Text(item.icon)
              .fontSize(24)
            Text(item.label)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(item.fontColor)
          }
          .layoutWeight(1)
          .padding({ top: 10, bottom: 10 })
          .backgroundColor(item.bgColor)
          .borderRadius(16)
          .border({ width: 1, color: '#F0ECE6' })
          .onClick(() => {
            if (this.onSelectAction) {
              this.onSelectAction(item.typeKey);
            }
          })
        }, (item: QuickRecordItem) => item.typeKey)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
  }
}
