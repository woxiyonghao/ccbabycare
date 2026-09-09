import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppConstants } from '../../common/constants/AppConstants';
import { ArrowIcon } from '../../common/components/ArrowIcon';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { RecordCategoryItem, ALL_RECORD_CATEGORIES, getCategoryByKey, DEFAULT_CATEGORY_KEYS } from '../../common/models/RecordCategoryItem';

/**
 * 自定义分类排序页面
 * 支持长按/拖拽平滑重排（参照 12001923_67f9410b63eea15447.gif）
 * 排在前 4 项的分类将自动展示在「记录中心」首页
 */
@Entry
@Component
struct CategorySortPage {
  @State categoryKeys: string[] = [];
  @State isDragging: boolean = false;
  @State activeDragKey: string = '';
  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;
  @State containerWidth: number = 340;
  @State isReady: boolean = false;

  private readonly colGap: number = 10;
  private readonly rowGap: number = 10;
  private readonly cardHeight: number = 102;

  aboutToAppear() {
    this.reloadCategories();
  }

  private reloadCategories(): void {
    this.categoryKeys = DatabaseHelper.getInstance().getCategoryOrder();
  }

  private getCardWidth(): number {
    return Math.max(120, (this.containerWidth - this.colGap) / 2);
  }

  private getSlotX(index: number): number {
    const col = index % 2;
    return col * (this.getCardWidth() + this.colGap);
  }

  private getSlotY(index: number): number {
    const row = Math.floor(index / 2);
    return row * (this.cardHeight + this.rowGap);
  }

  private handleDragStart(key: string): void {
    this.activeDragKey = key;
    this.isDragging = true;
    this.dragOffsetX = 0;
    this.dragOffsetY = 0;
  }

  private handleDragUpdate(key: string, offsetX: number, offsetY: number): void {
    if (!this.isDragging || this.activeDragKey !== key) {
      return;
    }
    this.dragOffsetX = offsetX;
    this.dragOffsetY = offsetY;

    const curIdx = this.categoryKeys.indexOf(key);
    if (curIdx < 0) {
      return;
    }

    const cardW = this.getCardWidth();
    const curSlotX = this.getSlotX(curIdx);
    const curSlotY = this.getSlotY(curIdx);
    const curCenterX = curSlotX + this.dragOffsetX + cardW / 2;
    const curCenterY = curSlotY + this.dragOffsetY + this.cardHeight / 2;

    let targetCol = Math.floor(curCenterX / (cardW + this.colGap));
    let targetRow = Math.floor(curCenterY / (this.cardHeight + this.rowGap));
    targetCol = Math.max(0, Math.min(1, targetCol));
    targetRow = Math.max(0, Math.min(3, targetRow));

    const targetIdx = targetRow * 2 + targetCol;
    if (targetIdx >= 0 && targetIdx < this.categoryKeys.length && targetIdx !== curIdx) {
      const oldSlotX = this.getSlotX(curIdx);
      const oldSlotY = this.getSlotY(curIdx);
      const newSlotX = this.getSlotX(targetIdx);
      const newSlotY = this.getSlotY(targetIdx);

      // 调整拖拽偏移量，使卡片保持在手指相对位置不变形
      this.dragOffsetX += (oldSlotX - newSlotX);
      this.dragOffsetY += (oldSlotY - newSlotY);

      const newKeys: string[] = [...this.categoryKeys];
      const removed = newKeys.splice(curIdx, 1);
      newKeys.splice(targetIdx, 0, removed[0]);
      this.categoryKeys = newKeys;
    }
  }

  private finishDrag(): void {
    if (!this.isDragging) {
      return;
    }
    this.isDragging = false;
    this.activeDragKey = '';
    this.dragOffsetX = 0;
    this.dragOffsetY = 0;
    DatabaseHelper.getInstance().saveCategoryOrder(this.categoryKeys);
    try {
      promptAction.showToast({ message: '分类顺序已保存' });
    } catch (e) {}
  }

  private moveCategory(key: string, delta: number): void {
    const curIdx = this.categoryKeys.indexOf(key);
    if (curIdx < 0) {
      return;
    }
    const newIdx = curIdx + delta;
    if (newIdx < 0 || newIdx >= this.categoryKeys.length) {
      return;
    }
    const newKeys: string[] = [...this.categoryKeys];
    const removed = newKeys.splice(curIdx, 1);
    newKeys.splice(newIdx, 0, removed[0]);
    this.categoryKeys = newKeys;
    DatabaseHelper.getInstance().saveCategoryOrder(this.categoryKeys);
    try {
      promptAction.showToast({ message: '分类顺序已调整' });
    } catch (e) {}
  }

  private resetToDefault(): void {
    DatabaseHelper.getInstance().resetCategoryOrder();
    this.reloadCategories();
    try {
      promptAction.showToast({ message: '已恢复默认分类排序' });
    } catch (e) {}
  }

  private getTopFourSummary(): string {
    return this.categoryKeys.slice(0, 4).map(k => {
      const item = getCategoryByKey(k);
      return `${item.icon} ${item.title.replace('记录', '').replace('档案', '').replace('账本', '')}`;
    }).join('、');
  }

  build() {
    Column() {
      // 1. 顶栏导航条
      Row() {
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

        Text('自定义分类排序')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
          .margin({ left: 10 })

        Blank()

        Text('恢复默认')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppConstants.COLOR_PRIMARY)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#FFF5F2')
          .borderRadius(14)
          .onClick(() => {
            this.resetToDefault();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })

      Scroll() {
        Column({ space: 14 }) {
          // 2. 核心说明卡片
          Column({ space: 6 }) {
            Row({ space: 6 }) {
              Text('💡')
                .fontSize(16)
              Text('长按或拖拽卡片自由排序')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
            }
            Text('排在第 1~4 位的分类将固定展示在「记录中心」首页，点击即可极速录入；松手后自动保存生效。')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .lineHeight(17)

            Row({ space: 6 }) {
              Text('当前首页展示:')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_PRIMARY)
              Text(this.getTopFourSummary())
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
                .fontWeight(FontWeight.Medium)
            }
            .margin({ top: 4 })
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('rgba(255, 122, 69, 0.08)')
            .borderRadius(8)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .border({ width: 1, color: '#F0EBE1' })

          // 3. 拖拽插槽网格容器 (Stack 动态插槽坐标布局，支持流畅的位移动画)
          Stack() {
            ForEach(ALL_RECORD_CATEGORIES, (item: RecordCategoryItem) => {
              this.renderCategoryCard(item)
            }, (item: RecordCategoryItem) => item.key)
          }
          .width('100%')
          .height(4 * this.cardHeight + 3 * this.rowGap + 10)
          .onAreaChange((oldVal: Area, newVal: Area) => {
            this.containerWidth = Number(newVal.width);
            if (!this.isReady) {
              setTimeout(() => {
                this.isReady = true;
              }, 50);
            }
          })

          // 4. 底部友好提示
          Row({ space: 6 }) {
            Text('ℹ️')
              .fontSize(13)
            Text('支持手指拖拽换位，也可直接点击卡片上的 ⬆ ⬇ 快速微调')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
          .margin({ top: 6, bottom: 24 })
        }
        .width('92%')
        .padding({ top: 6, bottom: 20 })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }

  /**
   * 渲染单个分类卡片
   * 保持与记录中心首页完全一致的高质感马卡龙配色和排版
   */
  @Builder
  renderCategoryCard(item: RecordCategoryItem) {
    Column({ space: 4 }) {
      Row() {
        // 展示位标签（前4位为首页展示，后4位为待选分类）
        Row({ space: 3 }) {
          Text(this.categoryKeys.indexOf(item.key) < 4 ? '★ 首页' : '待选')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.categoryKeys.indexOf(item.key) < 4 ? Color.White : '#718096')
          Text(`${this.categoryKeys.indexOf(item.key) + 1}`)
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.categoryKeys.indexOf(item.key) < 4 ? Color.White : '#718096')
        }
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor(this.categoryKeys.indexOf(item.key) < 4 ? AppConstants.COLOR_PRIMARY : '#E2E8F0')
        .borderRadius(6)

        Blank()

        // 快速微调上移/下移按钮 + 拖拽手柄符号
        Row({ space: 4 }) {
          if (this.categoryKeys.indexOf(item.key) > 0) {
            Text('▲')
              .fontSize(10)
              .fontColor('#718096')
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .backgroundColor('rgba(255, 255, 255, 0.6)')
              .borderRadius(4)
              .onClick(() => {
                this.moveCategory(item.key, -1);
              })
          }

          if (this.categoryKeys.indexOf(item.key) < this.categoryKeys.length - 1) {
            Text('▼')
              .fontSize(10)
              .fontColor('#718096')
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .backgroundColor('rgba(255, 255, 255, 0.6)')
              .borderRadius(4)
              .onClick(() => {
                this.moveCategory(item.key, 1);
              })
          }

          Text('⠿')
            .fontSize(15)
            .fontColor('rgba(0, 0, 0, 0.3)')
            .margin({ left: 2 })
        }
        .hitTestBehavior(HitTestMode.Block)
      }
      .width('100%')

      Row({ space: 8 }) {
        Text(item.icon)
          .fontSize(26)

        Column({ space: 2 }) {
          Text(item.title)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
          Text(item.desc)
            .fontSize(10)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width(this.getCardWidth())
    .height(this.cardHeight)
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(item.bgColor)
    .borderRadius(14)
    .border({
      width: this.categoryKeys.indexOf(item.key) < 4 ? 1.5 : 1,
      color: this.categoryKeys.indexOf(item.key) < 4 ? 'rgba(255, 122, 69, 0.35)' : 'rgba(0, 0, 0, 0.05)'
    })
    .position({
      x: this.getSlotX(this.categoryKeys.indexOf(item.key)) +
        (this.isDragging && this.activeDragKey === item.key ? this.dragOffsetX : 0),
      y: this.getSlotY(this.categoryKeys.indexOf(item.key)) +
        (this.isDragging && this.activeDragKey === item.key ? this.dragOffsetY : 0)
    })
    .scale(this.isDragging && this.activeDragKey === item.key ? { x: 1.07, y: 1.07 } : { x: 1, y: 1 })
    .shadow(this.isDragging && this.activeDragKey === item.key ?
      { radius: 20, color: 'rgba(0, 0, 0, 0.22)', offsetY: 10 } :
      { radius: 0, color: 'transparent', offsetY: 0 })
    .zIndex(this.isDragging && this.activeDragKey === item.key ? 999 : 1)
    .animation(this.isReady && !(this.isDragging && this.activeDragKey === item.key) ? {
      duration: 250,
      curve: Curve.FastOutSlowIn
    } : null)
    .gesture(
      PanGesture({ direction: PanDirection.All, distance: 4 })
        .onActionStart((event: GestureEvent) => {
          this.handleDragStart(item.key);
        })
        .onActionUpdate((event: GestureEvent) => {
          this.handleDragUpdate(item.key, event.offsetX, event.offsetY);
        })
        .onActionEnd(() => {
          this.finishDrag();
        })
        .onActionCancel(() => {
          this.finishDrag();
        })
    )
  }
}
