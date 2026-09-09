import { CaregiverConstants, CaregiverItem } from '../constants/CaregiverConstants';
import { AppConstants } from '../constants/AppConstants';

/**
 * 照护者角色切换选择器（均分单排自适应，彻底杜绝横向撑出与折行）
 */
@Component
export struct CaregiverPicker {
  @Link selectedRoleId: string;
  onRoleChanged?: (roleId: string) => void;

  build() {
    Row({ space: 6 }) {
      ForEach(CaregiverConstants.DEFAULT_ROLES, (item: CaregiverItem) => {
        Row({ space: 3 }) {
          Text(item.avatarIcon)
            .fontSize(13)
          Text(item.name)
            .fontSize(11)
            .fontWeight(this.selectedRoleId === item.id ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedRoleId === item.id ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MUTED)
            .maxLines(1)
        }
        .layoutWeight(1)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.selectedRoleId === item.id ? '#FFF0EB' : '#F3F4F6')
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
    .padding({ top: 2, bottom: 2 })
  }
}
