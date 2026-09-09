import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { BabyModel } from '../../common/models/BabyModel';
import { FeedingRecord } from '../../common/models/FeedingRecord';
import { EliminationRecord } from '../../common/models/EliminationRecord';
import { SleepRecord } from '../../common/models/SleepRecord';
import { DateUtil } from '../../common/utils/DateUtil';
import { QuickRecordBar } from '../../common/components/QuickRecordBar';
import { TimelineItemCard, TimelineData } from '../../common/components/TimelineItemCard';
import { CaregiverConstants } from '../../common/constants/CaregiverConstants';
import { FeedingType } from '../../common/constants/FeedingConstants';
import { FeedingRecordDialog } from '../record/FeedingRecordDialog';
import { EliminationRecordDialog } from '../record/EliminationRecordDialog';
import { SleepRecordDialog } from '../record/SleepRecordDialog';
import { GrowthRecordDialog } from '../record/GrowthRecordDialog';
import { ArrowIcon } from '../../common/components/ArrowIcon';

/**
 * 首页：今日概览 + 3秒极速记录入口 + 今日时间轴流水
 */
@Component
export struct HomePage {
  @State currentBaby: BabyModel = new BabyModel();
  @State timelineItems: TimelineData[] = [];
  @State todayMilkTotal: number = 0;
  @State todayFeedCount: number = 0;
  @State todayPoopCount: number = 0;
  @State todayPeeCount: number = 0;
  @State todaySleepMinutes: number = 0;
  @State lastFeedElapsed: string = '刚刚';
  @State currentCaregiverId: string = 'MOM';
  @StorageProp('APP_REFRESH_TRIGGER') @Watch('refreshData') refreshTrigger: number = 0;
  @StorageProp('CACHE_BABY_INFO') @Watch('onBabyCacheChanged') cachedBabyJson: string = '';

  // 弹窗控制器（统一定位 Center 居中弹窗，彻底杜绝输入法弹出时缩小变形）
  private formulaDialogController: CustomDialogController = new CustomDialogController({
    builder: FeedingRecordDialog({
      initialType: FeedingType.FORMULA,
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private breastDialogController: CustomDialogController = new CustomDialogController({
    builder: FeedingRecordDialog({
      initialType: FeedingType.BREASTFEEDING,
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private solidsDialogController: CustomDialogController = new CustomDialogController({
    builder: FeedingRecordDialog({
      initialType: FeedingType.SOLIDS,
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private elimDialogController: CustomDialogController = new CustomDialogController({
    builder: EliminationRecordDialog({
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private sleepDialogController: CustomDialogController = new CustomDialogController({
    builder: SleepRecordDialog({
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  private growthDialogController: CustomDialogController = new CustomDialogController({
    builder: GrowthRecordDialog({
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear() {
    // 1. 优先从内存极速缓存中瞬时恢复宝宝数据，保障主页0延迟无闪烁
    this.restoreBabyFromCache();
    // 2. 刷新最新流水统计
    this.refreshData();
  }

  private restoreBabyFromCache(): void {
    if (this.cachedBabyJson) {
      this.parseBabyFromJson(this.cachedBabyJson);
      return;
    }
    const cached = DatabaseHelper.getInstance().getCachedBaby();
    if (cached && cached.name) {
      this.currentBaby = cached;
    }
  }

  private onBabyCacheChanged(): void {
    if (this.cachedBabyJson) {
      this.parseBabyFromJson(this.cachedBabyJson);
    }
  }

  private parseBabyFromJson(jsonStr: string): void {
    try {
      const parsed = JSON.parse(jsonStr) as Record<string, Object>;
      const b = new BabyModel(
        (parsed['id'] as string) || '',
        (parsed['name'] as string) || '',
        (parsed['birthday'] as number) || 0,
        (parsed['gender'] as string) || 'boy',
        (parsed['birthWeight'] !== undefined && parsed['birthWeight'] !== null ? (parsed['birthWeight'] as number) : 0),
        (parsed['birthHeight'] !== undefined && parsed['birthHeight'] !== null ? (parsed['birthHeight'] as number) : 0),
        (parsed['bloodType'] as string) || '未知',
        (parsed['avatar'] as string) || '👶',
        (parsed['notes'] as string) || '',
        (parsed['isDefault'] as number) || 1,
        (parsed['createdAt'] as number) || Date.now()
      );
      if (b.name) {
        this.currentBaby = b;
      }
    } catch (e) {}
  }

  public refreshData(): void {
    const db = DatabaseHelper.getInstance();
    const cached = db.getCachedBaby();
    if (cached && cached.name) {
      this.currentBaby = cached;
    } else {
      this.currentBaby = db.getCurrentBaby();
    }

    const feedings = db.getFeedingRecords();
    const elims = db.getEliminationRecords();
    const sleeps = db.getSleepRecords();

    // 计算今日统计
    const todayStart = DateUtil.getTodayStart();
    const todayEnd = DateUtil.getTodayEnd();

    let milkTotal = 0;
    let feedCount = 0;
    feedings.forEach((f: FeedingRecord) => {
      if (f.recordTime >= todayStart && f.recordTime <= todayEnd) {
        feedCount++;
        if (f.amountUnit === 'ml') {
          milkTotal += f.amount;
        }
      }
    });
    this.todayMilkTotal = milkTotal;
    this.todayFeedCount = feedCount;

    // 上次喂奶间隔
    if (feedings.length > 0) {
      this.lastFeedElapsed = DateUtil.getElapsedTimeDesc(feedings[0].recordTime);
    } else {
      this.lastFeedElapsed = '暂无记录';
    }

    // 排泄统计
    let poop = 0;
    let pee = 0;
    elims.forEach((e: EliminationRecord) => {
      if (e.recordTime >= todayStart && e.recordTime <= todayEnd) {
        if (e.eliminationType === 'POOP' || e.eliminationType === 'MIXED') {
          poop++;
        }
        if (e.eliminationType === 'PEE' || e.eliminationType === 'MIXED') {
          pee++;
        }
      }
    });
    this.todayPoopCount = poop;
    this.todayPeeCount = pee;

    // 睡眠统计
    let sleepMins = 0;
    sleeps.forEach((s: SleepRecord) => {
      if (s.startTime >= todayStart && s.startTime <= todayEnd) {
        sleepMins += s.durationMinutes;
      }
    });
    this.todaySleepMinutes = sleepMins;

    // 组合时间轴
    // 组合今日时间轴流水（首页严格仅展示今日）
    const items: TimelineData[] = [];

    feedings.forEach((f: FeedingRecord) => {
      if (f.recordTime < todayStart || f.recordTime > todayEnd) {
        return;
      }
      let icon = '🍼';
      let title = '配方奶';
      let amtDesc = `${f.amount} ml`;
      let detail = `${f.formulaStage || ''} (约${f.scoops || 0}勺)`;

      if (f.feedingType === 'BREASTFEEDING') {
        icon = '🤱';
        title = '母乳亲喂';
        amtDesc = `${f.amount} 分钟`;
        detail = `左侧 ${f.leftDuration}分 · 右侧 ${f.rightDuration}分`;
      } else if (f.feedingType === 'BOTTLE') {
        icon = '🍼';
        title = '母乳瓶喂';
        amtDesc = `${f.amount} ml`;
        detail = '母乳泵出瓶喂';
      } else if (f.feedingType === 'SOLIDS') {
        icon = '🥣';
        title = f.solidsName || '宝宝辅食';
        amtDesc = f.amount > 0 ? `${f.amount} g` : '';
        detail = f.isNewFood ? '⭐ 首次添加新食材' : (f.notes || '');
      }

      if (f.notes && f.feedingType !== 'SOLIDS') {
        detail += ` · ${f.notes}`;
      } else if (f.notes && f.feedingType === 'SOLIDS' && f.isNewFood) {
        detail += ` · ${f.notes}`;
      }

      items.push({
        id: f.id,
        category: 'FEEDING',
        icon: icon,
        title: title,
        amountDesc: amtDesc,
        detailDesc: detail,
        timestamp: f.recordTime,
        caregiverId: f.caregiverId,
        isAbnormal: false
      });
    });

    elims.forEach((e: EliminationRecord) => {
      if (e.recordTime < todayStart || e.recordTime > todayEnd) {
        return;
      }
      let icon = '💩';
      let title = '便便';
      if (e.eliminationType === 'PEE') {
        icon = '💧';
        title = '嘘嘘';
      } else if (e.eliminationType === 'MIXED') {
        icon = '💩💧';
        title = '便便+嘘嘘';
      }

      let detail = `${e.stoolTexture || ''} · ${e.stoolColor || ''}`;
      if (e.isAbnormal) {
        detail = `⚠️ 异常关注: ${e.stoolTexture} ${e.stoolColor}`;
      }
      if (e.notes) {
        detail += ` · ${e.notes}`;
      }

      items.push({
        id: e.id,
        category: 'ELIMINATION',
        icon: icon,
        title: title,
        amountDesc: e.volume || '中量',
        detailDesc: detail,
        timestamp: e.recordTime,
        caregiverId: e.caregiverId,
        isAbnormal: e.isAbnormal === 1
      });
    });

    sleeps.forEach((s: SleepRecord) => {
      if (s.startTime < todayStart || s.startTime > todayEnd) {
        return;
      }
      items.push({
        id: s.id,
        category: 'SLEEP',
        icon: '🌙',
        title: s.sleepType || '睡眠',
        amountDesc: `${s.durationMinutes} 分钟`,
        detailDesc: `${s.method || '自主'}入睡 · ${DateUtil.formatTime(s.startTime)} ~ ${DateUtil.formatTime(s.endTime)}`,
        timestamp: s.endTime,
        caregiverId: s.caregiverId,
        isAbnormal: false
      });
    });

    // 倒序排列
    items.sort((a, b) => b.timestamp - a.timestamp);
    this.timelineItems = items;
  }

  private showDeleteTimelineDialog(item: TimelineData): void {
    AlertDialog.show({
      title: '删除记录',
      message: `确定要删除此条「${item.title} (${item.amountDesc})」记录吗？删除后不可恢复。`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppConstants.COLOR_DANGER,
        action: () => {
          const db = DatabaseHelper.getInstance();
          if (item.category === 'FEEDING') {
            db.deleteFeedingRecord(item.id);
          } else if (item.category === 'ELIMINATION') {
            db.deleteEliminationRecord(item.id);
          } else if (item.category === 'SLEEP') {
            db.deleteSleepRecord(item.id);
          }
          this.refreshData();
          try {
            promptAction.showToast({ message: '已删除该条记录' });
          } catch (e) {}
        }
      }
    });
  }

  @Builder
  renderSwipeDeleteButton(item: TimelineData) {
    Row() {
      Button('删除', { type: ButtonType.Normal })
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor(AppConstants.COLOR_DANGER)
        .width(68)
        .height('100%')
        .borderRadius(14)
        .margin({ left: 6 })
        .onClick(() => {
          this.showDeleteTimelineDialog(item);
        })
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.End)
  }

  build() {
    List({ space: 8 }) {
      // 1. 顶部宝宝信息卡片（支持点击进入宝宝档案修改；去掉「档案 >」）
      ListItem() {
        Row({ space: 12 }) {
          Image($r('app.media.app_icon'))
            .width(52)
            .height(52)
            .borderRadius(16)
            .border({ width: 2, color: '#FFFFFF' })
            .shadow({ radius: 8, color: 'rgba(255,123,84,0.25)', offsetX: 0, offsetY: 4 })

          Column({ space: 4 }) {
            Row({ space: 8 }) {
              Text(this.currentBaby.name)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)

              Text(this.currentBaby.gender === 'boy' ? '👦 男宝' : '👧 女宝')
                .fontSize(11)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('#EBF8FF')
                .fontColor('#2B6CB0')
                .borderRadius(8)
            }

            Row({ space: 8 }) {
              Text(`🎂 月龄: ${this.currentBaby.getAgeString()}`)
                .fontSize(12)
                .fontColor(AppConstants.COLOR_PRIMARY)
                .fontWeight(FontWeight.Medium)
              Text(`⚖️ 出生: ${this.currentBaby.birthWeight}kg`)
                .fontSize(12)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 4 })
        .backgroundColor(AppConstants.COLOR_BG_CREAM)
      }

      // 2. 今日核心概览与极速记录（整体卡片设计；去掉「今日喂养概况 >」）
      ListItem() {
        Column({ space: 10 }) {
          // 距上次喂奶倒计时提示
          Row() {
            Text('⏱️ 距上次喂奶：')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
            Text(this.lastFeedElapsed)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_PRIMARY)
          }
          .width('100%')

          // 4格核心数据盘（点击各指标卡直达极速记录，防折行紧凑排版）
          Row({ space: 5 }) {
            // 奶量
            Column({ space: 2 }) {
              Row({ space: 2 }) {
                Text('🍼')
                  .fontSize(11)
                Text('喝奶总量')
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  .maxLines(1)
              }
              Row() {
                Text(`${this.todayMilkTotal}`)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_PRIMARY)
                Text(' ml')
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              Text(`共 ${this.todayFeedCount} 次`)
                .fontSize(10)
                .fontColor('#A0AEC0')
                .maxLines(1)
            }
            .layoutWeight(1)
            .padding({ left: 4, right: 4, top: 8, bottom: 8 })
            .backgroundColor('#FFF5F2')
            .borderRadius(12)

            // 便便
            Column({ space: 2 }) {
              Row({ space: 2 }) {
                Text('💩')
                  .fontSize(11)
                Text('便便次数')
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  .maxLines(1)
              }
              Row() {
                Text(`${this.todayPoopCount}`)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#319795')
                Text(' 次')
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              Text('肠胃正常')
                .fontSize(10)
                .fontColor('#A0AEC0')
                .maxLines(1)
            }
            .layoutWeight(1)
            .padding({ left: 4, right: 4, top: 8, bottom: 8 })
            .backgroundColor('#E6FFFA')
            .borderRadius(12)

            // 嘘嘘
            Column({ space: 2 }) {
              Row({ space: 2 }) {
                Text('💧')
                  .fontSize(11)
                Text('嘘嘘次数')
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  .maxLines(1)
              }
              Row() {
                Text(`${this.todayPeeCount}`)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#3182CE')
                Text(' 次')
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              Text('换尿布顺畅')
                .fontSize(10)
                .fontColor('#A0AEC0')
                .maxLines(1)
            }
            .layoutWeight(1)
            .padding({ left: 4, right: 4, top: 8, bottom: 8 })
            .backgroundColor('#EBF8FF')
            .borderRadius(12)

            // 睡眠
            Column({ space: 2 }) {
              Row({ space: 2 }) {
                Text('🌙')
                  .fontSize(11)
                Text('累计睡眠')
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
                  .maxLines(1)
              }
              Row() {
                Text(`${(this.todaySleepMinutes / 60).toFixed(1)}`)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_SECONDARY)
                Text(' h')
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              Text(`${this.todaySleepMinutes} 分钟`)
                .fontSize(10)
                .fontColor('#A0AEC0')
                .maxLines(1)
            }
            .layoutWeight(1)
            .padding({ left: 4, right: 4, top: 8, bottom: 8 })
            .backgroundColor('#FAF5FF')
            .borderRadius(12)
          }
          .width('100%')

          // 柔和优雅的分隔线
          Divider()
            .color('#F6F4EE')
            .strokeWidth(1)
            .margin({ top: 2, bottom: 2 })

          // 极速记录快捷操作栏（作为整体卡片的一部分）
          QuickRecordBar({
            onSelectAction: (typeKey: string) => {
              if (typeKey === 'FORMULA') {
                this.formulaDialogController.open();
              } else if (typeKey === 'BREAST') {
                this.breastDialogController.open();
              } else if (typeKey === 'DIAPER') {
                this.elimDialogController.open();
              } else if (typeKey === 'SLEEP') {
                this.sleepDialogController.open();
              } else if (typeKey === 'SOLIDS') {
                this.solidsDialogController.open();
              }
            }
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 12, bottom: 10 })
        .backgroundColor(AppConstants.COLOR_CARD_BG)
        .borderRadius(18)
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetX: 0, offsetY: 2 })
      }
      .padding({ left: '3%', right: '3%' })

      // 3. 今日喂养标题与进入全部流水入口（字样改为「今日喂养」）
      ListItem() {
        Row() {
          Text('今日喂养')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
          Blank()
          Row({ space: 3 }) {
            Text('全部')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppConstants.COLOR_PRIMARY)
            ArrowIcon({ arrowDirection: 'right', variant: 'orange', iconSize: 11 })
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor('#FFF5F2')
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            router.pushUrl({ url: 'pages/record/AllRecordsPage' });
          })
        }
        .width('100%')
        .padding({ top: 6, bottom: 2 })
      }
      .padding({ left: '3%', right: '3%' })

      // 4. 今日记录流列表（仅展示今日，支持侧滑删除与长按删除）
      if (this.timelineItems.length === 0) {
        ListItem() {
          Column({ space: 8 }) {
            Text('🍼')
              .fontSize(36)
            Text('今天还没有记录，点击上方快捷按钮开始记录吧~')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
          }
          .width('100%')
          .padding(40)
          .alignItems(HorizontalAlign.Center)
        }
        .padding({ left: '3%', right: '3%' })
      } else {
        ForEach(this.timelineItems, (item: TimelineData) => {
          ListItem() {
            TimelineItemCard({ item: item })
          }
          .padding({ left: '3%', right: '3%' })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/record/RecordDetailPage',
              params: {
                recordId: item.id,
                category: item.category
              }
            });
          })
          .swipeAction({
            end: {
              builder: () => {
                this.renderSwipeDeleteButton(item);
              }
            },
            edgeEffect: SwipeEdgeEffect.Spring
          })
          .gesture(
            LongPressGesture({ duration: 350 })
              .onAction(() => {
                this.showDeleteTimelineDialog(item);
              })
          )
        }, (item: TimelineData) => item.id)
      }

      // 底部 spacer，防止浮动 TabBar 遮挡最后一条
      ListItem() {
        Row().height(88)
      }
    }
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
