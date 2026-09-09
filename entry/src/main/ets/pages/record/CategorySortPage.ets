import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppConstants } from '../../common/constants/AppConstants';
import { ArrowIcon } from '../../common/components/ArrowIcon';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { RecordCategoryItem, ALL_RECORD_CATEGORIES, getCategoryByKey } from '../../common/models/RecordCategoryItem';

/**
 * 自定义分类排序页面
 * 支持长按进入编辑与流畅拖拽重排（严格参照 12001923_67f9410b63eea15447.gif）
 * 排在前 4 项的分类将自动展示在「记录中心」首页
 */
@Entry
@Component
struct CategorySortPage {
  @State categoryKeys: string[] = [];
  @State isEditMode: boolean = false;
  @State isDragging: boolean = false;
  @State activeDragKey: string = '';
  @State dragCardX: number = 0;
  @State dragCardY: number = 0;
  @State containerWidth: number = 340;
  @State isReady: boolean = false;

  private originCardX: number = 0;
  private originCardY: number = 0;
  private touchDownX: number = 0;
  private touchDownY: number = 0;
  private touchDownKey: string = '';
  private longPressTimer: number = -1;

  private readonly colGap: number = 10;
  private readonly rowGap: number = 10;
  private readonly cardHeight: number = 96;

  aboutToAppear() {
    this.reloadCategories();
  }

  aboutToDisappear() {
    DatabaseHelper.getInstance().saveCategoryOrder(this.categoryKeys);
    AppStorage.setOrCreate('CATEGORY_ORDER_TRIGGER', Date.now());
    AppStorage.setOrCreate('APP_REFRESH_TRIGGER', Date.now());
    if (this.longPressTimer !== -1) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = -1;
    }
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

  private handleTouch(key: string, event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      if (event.touches.length > 0) {
        this.touchDownX = event.touches[0].windowX;
        this.touchDownY = event.touches[0].windowY;
        this.touchDownKey = key;

        if (this.longPressTimer !== -1) {
          clearTimeout(this.longPressTimer);
          this.longPressTimer = -1;
        }

        // 长按 220ms 触发编辑并进入拖拽；若已在编辑模式，只需短按 60ms
        const pressDuration = this.isEditMode ? 60 : 220;
        this.longPressTimer = setTimeout(() => {
          this.isEditMode = true;
          this.startDragging(key);
        }, pressDuration);
      }
    } else if (event.type === TouchType.Move) {
      if (event.touches.length > 0 && this.touchDownKey === key) {
        const curX = event.touches[0].windowX;
        const curY = event.touches[0].windowY;
        const deltaX = curX - this.touchDownX;
        const deltaY = curY - this.touchDownY;

        if (!this.isDragging) {
          // 未激活拖拽前，如果手指滑动超过 8vp，判定为正常滚动并取消长按
          if (Math.hypot(deltaX, deltaY) > 8) {
            if (this.longPressTimer !== -1) {
              clearTimeout(this.longPressTimer);
              this.longPressTimer = -1;
            }
          }
        } else {
          // 正在拖拽，实时追踪
          this.updateDragging(deltaX, deltaY);
        }
      }
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      if (this.longPressTimer !== -1) {
        clearTimeout(this.longPressTimer);
        this.longPressTimer = -1;
      }
      if (this.isDragging) {
        this.finishDragging();
      }
      this.touchDownKey = '';
    }
  }

  private startDragging(key: string): void {
    const curSlotIdx = this.categoryKeys.indexOf(key);
    if (curSlotIdx < 0) {
      return;
    }
    this.activeDragKey = key;
    this.isDragging = true;
    this.originCardX = this.getSlotX(curSlotIdx);
    this.originCardY = this.getSlotY(curSlotIdx);
    this.dragCardX = this.originCardX;
    this.dragCardY = this.originCardY;
  }

  private updateDragging(deltaX: number, deltaY: number): void {
    if (!this.isDragging || !this.activeDragKey) {
      return;
    }
    // 拖拽卡片直接严格跟随手指，1:1 定位无任何坐标漂移
    this.dragCardX = this.originCardX + deltaX;
    this.dragCardY = this.originCardY + deltaY;

    const cardW = this.getCardWidth();
    const centerX = this.dragCardX + cardW / 2;
    const centerY = this.dragCardY + this.cardHeight / 2;

    const curIdx = this.categoryKeys.indexOf(this.activeDragKey);
    if (curIdx < 0) {
      return;
    }

    // 寻找与当前卡片中心欧氏距离最近的目标插槽
    let closestSlot = curIdx;
    let minDistanceSq = Number.MAX_VALUE;

    for (let i = 0; i < this.categoryKeys.length; i++) {
      const slotCenterX = this.getSlotX(i) + cardW / 2;
      const slotCenterY = this.getSlotY(i) + this.cardHeight / 2;
      const dx = centerX - slotCenterX;
      const dy = centerY - slotCenterY;
      const distSq = dx * dx + dy * dy;

      if (distSq < minDistanceSq) {
        minDistanceSq = distSq;
        closestSlot = i;
      }
    }

    // 距离滞后判断：距离新目标插槽显著更近时才触发平滑滑位重排，防止边界闪烁
    if (closestSlot !== curIdx) {
      const curSlotCenterX = this.getSlotX(curIdx) + cardW / 2;
      const curSlotCenterY = this.getSlotY(curIdx) + this.cardHeight / 2;
      const curDx = centerX - curSlotCenterX;
      const curDy = centerY - curSlotCenterY;
      const curDistSq = curDx * curDx + curDy * curDy;

      if (minDistanceSq < curDistSq * 0.65) {
        const newKeys: string[] = [...this.categoryKeys];
        const removed = newKeys.splice(curIdx, 1);
        newKeys.splice(closestSlot, 0, removed[0]);
        this.categoryKeys = newKeys;
      }
    }
  }

  private finishDragging(): void {
    if (!this.isDragging) {
      return;
    }
    this.isDragging = false;
    this.activeDragKey = '';
    // 立即落位保存最新分类顺序
    DatabaseHelper.getInstance().saveCategoryOrder(this.categoryKeys);
    try {
      promptAction.showToast({ message: '分类顺序已更新' });
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
          DatabaseHelper.getInstance().saveCategoryOrder(this.categoryKeys);
          AppStorage.setOrCreate('CATEGORY_ORDER_TRIGGER', Date.now());
          AppStorage.setOrCreate('APP_REFRESH_TRIGGER', Date.now());
          router.back();
        })

        Text('自定义分类排序')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
          .margin({ left: 10 })

        Blank()

        if (this.isEditMode) {
          Text('完成')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor(AppConstants.COLOR_PRIMARY)
            .borderRadius(14)
            .onClick(() => {
              this.isEditMode = false;
              DatabaseHelper.getInstance().saveCategoryOrder(this.categoryKeys);
              try {
                promptAction.showToast({ message: '分类排序已保存' });
              } catch (e) {}
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })

      Scroll() {
        Column({ space: 14 }) {
          // 2. 核心说明卡片（清晰提示：长按可以进入编辑）
          Column({ space: 6 }) {
            Row({ space: 6 }) {
              Text('💡')
                .fontSize(16)
              Text('长按可以进入编辑')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
            }
            Text('长按卡片进入编辑模式，可自由拖拽调整顺序。排在第 1~4 位的分类将固定展示在「记录中心」首页。')
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

          // 3. 拖拽插槽网格容器 (Stack 动态插槽坐标布局，支持流畅丝滑的位移动画)
          Stack() {
            ForEach(ALL_RECORD_CATEGORIES, (item: RecordCategoryItem) => {
              this.renderCategoryCard(item)
            }, (item: RecordCategoryItem) => item.key)
          }
          .width('100%')
          .height(4 * this.cardHeight + 3 * this.rowGap + 12)
          .onAreaChange((oldVal: Area, newVal: Area) => {
            this.containerWidth = Number(newVal.width);
            if (!this.isReady) {
              setTimeout(() => {
                this.isReady = true;
              }, 50);
            }
          })
          .onTouch((event: TouchEvent) => {
            if (this.isDragging && event.touches.length > 0) {
              if (event.type === TouchType.Move) {
                const curX = event.touches[0].windowX;
                const curY = event.touches[0].windowY;
                this.updateDragging(curX - this.touchDownX, curY - this.touchDownY);
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.finishDragging();
              }
            }
          })
        }
        .width('92%')
        .padding({ top: 6, bottom: 30 })
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
   * 纯净原生卡片设计，去除多余按钮，完美还原记录中心美感
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
      x: (this.isDragging && this.activeDragKey === item.key) ?
        this.dragCardX : this.getSlotX(this.categoryKeys.indexOf(item.key)),
      y: (this.isDragging && this.activeDragKey === item.key) ?
        this.dragCardY : this.getSlotY(this.categoryKeys.indexOf(item.key))
    })
    .scale(this.isDragging && this.activeDragKey === item.key ? { x: 1.08, y: 1.08 } : { x: 1, y: 1 })
    .shadow(this.isDragging && this.activeDragKey === item.key ?
      { radius: 24, color: 'rgba(0, 0, 0, 0.28)', offsetY: 12 } :
      { radius: 0, color: 'transparent', offsetY: 0 })
    .zIndex(this.isDragging && this.activeDragKey === item.key ? 999 : 1)
    .animation(this.isReady && !(this.isDragging && this.activeDragKey === item.key) ? {
      duration: 250,
      curve: Curve.FastOutSlowIn
    } : null)
    .onTouch((event: TouchEvent) => {
      this.handleTouch(item.key, event);
    })
  }
}
