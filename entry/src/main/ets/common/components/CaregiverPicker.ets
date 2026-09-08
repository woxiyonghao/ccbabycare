import { CaregiverConstants, CaregiverItem } from '../constants/CaregiverConstants';
import { AppConstants } from '../constants/AppConstants';

/**
 * 照护者角色切换选择器（参考图二手绘日记本角色标签）
 */
@Component
export struct CaregiverPicker {
  @Link selectedRoleId: string;
  onRoleChanged?: (roleId: string) => void;

  build() {
    Row({ space: 8 }) {
      ForEach(CaregiverConstants.DEFAULT_ROLES, (item: CaregiverItem) => {
        Row({ space: 4 }) {
          Text(item.avatarIcon)
            .fontSize(14)
          Text(item.name)
            .fontSize(12)
            .fontWeight(this.selectedRoleId === item.id ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedRoleId === item.id ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor(this.selectedRoleId === item.id ? AppConstants.COLOR_PRIMARY_LIGHT : '#F3F4F6')
        .borderRadius(16)
        .border({
          width: 1,
          color: this.selectedRoleId === item.id ? AppConstants.COLOR_PRIMARY : '#E5E7EB'
        })
        .onClick(() => {
          this.selectedRoleId = item.id;
          if (this.onRoleChanged) {
            this.onRoleChanged(item.id);
          }
        })
      }, (item: CaregiverItem) => item.id)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}
