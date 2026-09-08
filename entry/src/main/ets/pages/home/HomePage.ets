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

  // 弹窗控制器
  private feedingDialogController: CustomDialogController = new CustomDialogController({
    builder: FeedingRecordDialog({
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    customStyle: true
  });

  private elimDialogController: CustomDialogController = new CustomDialogController({
    builder: EliminationRecordDialog({
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    customStyle: true
  });

  private sleepDialogController: CustomDialogController = new CustomDialogController({
    builder: SleepRecordDialog({
      onSuccess: () => {
        this.refreshData();
      }
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
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

    // 组合今日时间轴
    const items: TimelineData[] = [];

    feedings.forEach((f: FeedingRecord) => {
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
        amtDesc = `${f.amount} g`;
        detail = f.isNewFood ? '⭐ 首次添加新食材' : '正常辅食';
      }

      if (f.notes) {
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
      items.push({
        id: s.id,
        category: 'SLEEP',
        icon: '🌙',
        title: s.sleepType || '睡眠',
        amountDesc: `${s.durationMinutes} 分钟`,
        detailDesc: `${s.method || '自主'}入睡 · ${DateUtil.formatTime(s.startTime)} ~ ${DateUtil.formatTime(s.endTime)}`,
        timestamp: s.startTime,
        caregiverId: s.caregiverId,
        isAbnormal: false
      });
    });

    // 倒序排列
    items.sort((a, b) => b.timestamp - a.timestamp);
    this.timelineItems = items;
  }

  build() {
    Column() {
      // 1. 顶部宝宝信息卡片
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
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })
      .backgroundColor(AppConstants.COLOR_BG_CREAM)

      // 2. 今日关键指标概览卡片（手绘奶油风格）
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
          Blank()
          Row({ space: 3 }) {
            Text('今日喂养概况')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
            ArrowIcon({ arrowDirection: 'right', variant: 'gray', iconSize: 11 })
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')

        // 4格核心数据盘
        Row({ space: 8 }) {
          // 奶量
          Column({ space: 2 }) {
            Text('🍼 喝奶总量')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
            Row() {
              Text(`${this.todayMilkTotal}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_PRIMARY)
              Text(' ml')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            Text(`共 ${this.todayFeedCount} 次`)
              .fontSize(10)
              .fontColor('#A0AEC0')
          }
          .layoutWeight(1)
          .padding(8)
          .backgroundColor('#FFF5F2')
          .borderRadius(12)

          // 便便
          Column({ space: 2 }) {
            Text('💩 便便次数')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
            Row() {
              Text(`${this.todayPoopCount}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#319795')
              Text(' 次')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            Text('肠胃正常')
              .fontSize(10)
              .fontColor('#A0AEC0')
          }
          .layoutWeight(1)
          .padding(8)
          .backgroundColor('#E6FFFA')
          .borderRadius(12)

          // 嘘嘘
          Column({ space: 2 }) {
            Text('💧 嘘嘘次数')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
            Row() {
              Text(`${this.todayPeeCount}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#3182CE')
              Text(' 次')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            Text('换尿布顺畅')
              .fontSize(10)
              .fontColor('#A0AEC0')
          }
          .layoutWeight(1)
          .padding(8)
          .backgroundColor('#EBF8FF')
          .borderRadius(12)

          // 睡眠
          Column({ space: 2 }) {
            Text('🌙 累计睡眠')
              .fontSize(11)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
            Row() {
              Text(`${(this.todaySleepMinutes / 60).toFixed(1)}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_SECONDARY)
              Text(' h')
                .fontSize(11)
                .fontColor(AppConstants.COLOR_TEXT_MUTED)
            }
            Text(`${this.todaySleepMinutes} 分钟`)
              .fontSize(10)
              .fontColor('#A0AEC0')
          }
          .layoutWeight(1)
          .padding(8)
          .backgroundColor('#FAF5FF')
          .borderRadius(12)
        }
        .width('100%')
      }
      .width('94%')
      .padding(14)
      .backgroundColor(AppConstants.COLOR_CARD_BG)
      .borderRadius(18)
      .margin({ top: 4, bottom: 8 })
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetX: 0, offsetY: 2 })

      // 3. 极速记录快捷操作栏
      QuickRecordBar({
        onSelectAction: (typeKey: string) => {
          if (typeKey === 'FORMULA' || typeKey === 'BREAST') {
            this.feedingDialogController.open();
          } else if (typeKey === 'DIAPER') {
            this.elimDialogController.open();
          } else if (typeKey === 'SLEEP') {
            this.sleepDialogController.open();
          } else if (typeKey === 'SOLIDS') {
            this.feedingDialogController.open();
          }
        }
      })

      // 4. 今日时间轴标题
      Row() {
        Text('📖 今日喂养流水时间轴')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
        Blank()
        Row({ space: 3 }) {
          Text('全部流水')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_PRIMARY)
          ArrowIcon({ arrowDirection: 'right', variant: 'orange', iconSize: 11 })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('94%')
      .padding({ top: 10, bottom: 6 })

      // 5. 今日记录流列表
      List({ space: 8 }) {
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
        } else {
          ForEach(this.timelineItems, (item: TimelineData) => {
            ListItem() {
              TimelineItemCard({ item: item })
            }
          }, (item: TimelineData) => item.id)
        }
      }
      .layoutWeight(1)
      .width('94%')
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
