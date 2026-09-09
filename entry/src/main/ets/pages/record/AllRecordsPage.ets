import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { BabyModel } from '../../common/models/BabyModel';
import { FeedingRecord } from '../../common/models/FeedingRecord';
import { EliminationRecord } from '../../common/models/EliminationRecord';
import { SleepRecord } from '../../common/models/SleepRecord';
import { DateUtil } from '../../common/utils/DateUtil';
import { CaregiverConstants } from '../../common/constants/CaregiverConstants';
import { TimelineData } from '../../common/components/TimelineItemCard';
import { ArrowIcon } from '../../common/components/ArrowIcon';
import { GrowthRecord } from '../../common/models/GrowthRecord';
import { VaccineRecord } from '../../common/models/VaccineRecord';
import { ExpenseRecord } from '../../common/models/ExpenseRecord';
import { RoutineItem, ParentsMessageItem } from '../../common/database/DatabaseHelper';

/**
 * 每日流水记录分组信息
 */
export interface DateRecordGroup {
  dateKey: string;
  dateDisplay: string;
  relativeDay: string;
  timestamp: number;
  milkTotal: number;
  poopCount: number;
  sleepMinutes: number;
  items: TimelineData[];
}

/**
 * 扁平化列表行数据（支持日期组头与单条流水 Cell 独立排版，自带8vp间距）
 */
export interface FlatListRow {
  isHeader: boolean;
  headerData?: DateRecordGroup;
  recordData?: TimelineData;
  key: string;
}

export interface CategoryTabConfig {
  key: string;
  label: string;
  count: number;
}

/**
 * 全部流水记录全览页面
 * - 以每日日期为组头（Group Header）
 * - 呈现为精致的拟态流水表格（Table），每个 Cell 之间保持 8vp 间距
 * - 每个 Cell 均支持侧滑删除与长按删除，且伴有二次确认弹窗
 */
@Entry
@Component
struct AllRecordsPage {
  @State currentBaby: BabyModel = new BabyModel();
  @State allTimelineItems: TimelineData[] = [];
  @State filteredGroups: DateRecordGroup[] = [];
  @State flatRows: FlatListRow[] = [];
  @State selectedCategory: string = 'ALL'; // 'ALL' | 'FEEDING' | 'ELIMINATION' | 'SLEEP' ...
  @State totalCount: number = 0;
  @State feedingCount: number = 0;
  @State elimCount: number = 0;
  @State sleepCount: number = 0;
  @State growthCount: number = 0;
  @State vaccineCount: number = 0;
  @State expenseCount: number = 0;
  @State routineCount: number = 0;
  @State messageCount: number = 0;
  @State refreshVersion: number = 0;
  @StorageProp('APP_REFRESH_TRIGGER') @Watch('refreshData') refreshTrigger: number = 0;

  private categoryScroller: Scroller = new Scroller();

  private getCategoryTabs(): CategoryTabConfig[] {
    return [
      { key: 'ALL', label: '全部', count: this.totalCount },
      { key: 'FEEDING', label: '🍼 喂养', count: this.feedingCount },
      { key: 'ELIMINATION', label: '💩 排泄', count: this.elimCount },
      { key: 'SLEEP', label: '🌙 睡眠', count: this.sleepCount },
      { key: 'GROWTH', label: '📈 成长体检', count: this.growthCount },
      { key: 'VACCINE', label: '💉 疫苗', count: this.vaccineCount },
      { key: 'EXPENSE', label: '💰 账本', count: this.expenseCount },
      { key: 'ROUTINE', label: '⏰ 作息', count: this.routineCount },
      { key: 'MESSAGE', label: '💌 寄语', count: this.messageCount }
    ];
  }

  aboutToAppear() {
    this.readCategoryParam();
    this.refreshData();
  }

  private readCategoryParam(): void {
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params && params['category'] !== undefined) {
        const category = params['category'] as string;
        const validKeys: string[] = [
          'ALL', 'FEEDING', 'ELIMINATION', 'SLEEP', 'GROWTH',
          'VACCINE', 'EXPENSE', 'ROUTINE', 'MESSAGE'
        ];
        if (validKeys.indexOf(category) >= 0) {
          this.selectedCategory = category;
        }
      }
    } catch (e) {}
  }

  private refreshData(): void {
    const db = DatabaseHelper.getInstance();
    const cached = db.getCachedBaby();
    if (cached && cached.name) {
      this.currentBaby = cached;
    } else {
      this.currentBaby = db.getCurrentBaby();
    }

    // 获取系统全部分类记录数据
    const feedings: FeedingRecord[] = db.getFeedingRecords();
    const elims: EliminationRecord[] = db.getEliminationRecords();
    const sleeps: SleepRecord[] = db.getSleepRecords();
    const growths: GrowthRecord[] = db.getGrowthRecords();
    const vaccines: VaccineRecord[] = db.getVaccineRecords();
    const expenses: ExpenseRecord[] = db.getExpenses();
    const routines: RoutineItem[] = db.getRoutines();
    const messages: ParentsMessageItem[] = db.getParentsMessages();

    const items: TimelineData[] = [];
    let fCount = 0;
    let eCount = 0;
    let sCount = 0;
    let gCount = 0;
    let vCount = 0;
    let expCount = 0;
    let rCount = 0;
    let mCount = 0;

    // 1. 喂养记录
    feedings.forEach((f: FeedingRecord) => {
      fCount++;
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

    // 2. 排泄记录
    elims.forEach((e: EliminationRecord) => {
      eCount++;
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
        detail = `⚠️ 异常: ${e.stoolTexture} ${e.stoolColor}`;
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

    // 3. 睡眠记录
    sleeps.forEach((s: SleepRecord) => {
      sCount++;
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

    // 4. 成长体检记录
    growths.forEach((g: GrowthRecord) => {
      gCount++;
      let amt = `${g.height}cm · ${g.weight}kg`;
      let detail = `${g.monthAge}月龄 · ${g.measureLocation || '家庭测量'}`;
      if (g.percentileText) {
        detail += ` · ${g.percentileText}`;
      }
      if (g.notes) {
        detail += ` · ${g.notes}`;
      }
      items.push({
        id: g.id,
        category: 'GROWTH',
        icon: '📈',
        title: '成长体检',
        amountDesc: amt,
        detailDesc: detail,
        timestamp: g.recordDate || g.createdAt || Date.now(),
        caregiverId: g.caregiverId || 'MOM',
        isAbnormal: false
      });
    });

    // 5. 疫苗接种档案
    vaccines.forEach((v: VaccineRecord) => {
      vCount++;
      let amt = v.dose || '第1针';
      let detail = (v.isDone === 1 ? '✅ 已接种' : '⏳ 待接种') + (v.isFree === 1 ? ' · 免费一类' : ' · 自费二类');
      if (v.organization) {
        detail += ` · ${v.organization}`;
      }
      items.push({
        id: v.id,
        category: 'VACCINE',
        icon: '💉',
        title: v.vaccineName,
        amountDesc: amt,
        detailDesc: detail,
        timestamp: v.vaccinatedDate || v.createdAt || Date.now(),
        caregiverId: 'MOM',
        isAbnormal: false
      });
    });

    // 6. 养娃账本开销
    expenses.forEach((e: ExpenseRecord) => {
      expCount++;
      items.push({
        id: e.id,
        category: 'EXPENSE',
        icon: '💰',
        title: e.category || '日常开销',
        amountDesc: `¥${e.amount.toFixed(2)}`,
        detailDesc: e.notes || '养娃支出',
        timestamp: e.expenseDate || e.createdAt || Date.now(),
        caregiverId: 'MOM',
        isAbnormal: false
      });
    });

    // 7. 规律作息
    routines.forEach((r: RoutineItem) => {
      rCount++;
      items.push({
        id: r.id,
        category: 'ROUTINE',
        icon: r.emoji || '⏰',
        title: r.title,
        amountDesc: r.time,
        detailDesc: r.notes || '规律作息',
        timestamp: r.createdAt || Date.now(),
        caregiverId: 'MOM',
        isAbnormal: false
      });
    });

    // 8. 父母寄语
    messages.forEach((m: ParentsMessageItem) => {
      mCount++;
      items.push({
        id: m.id,
        category: 'MESSAGE',
        icon: '💌',
        title: '父母寄语',
        amountDesc: m.signature || '爸爸妈妈',
        detailDesc: m.content,
        timestamp: m.createdAt || Date.now(),
        caregiverId: 'MOM',
        isAbnormal: false
      });
    });

    // 倒序排列
    items.sort((a, b) => b.timestamp - a.timestamp);
    this.allTimelineItems = items;
    this.totalCount = items.length;
    this.feedingCount = fCount;
    this.elimCount = eCount;
    this.sleepCount = sCount;
    this.growthCount = gCount;
    this.vaccineCount = vCount;
    this.expenseCount = expCount;
    this.routineCount = rCount;
    this.messageCount = mCount;

    this.rebuildGroups();
  }

  private rebuildGroups(): void {
    let list = this.allTimelineItems;
    if (this.selectedCategory !== 'ALL') {
      list = list.filter((item: TimelineData) => item.category === this.selectedCategory);
    }

    const groupMap = new Map<string, DateRecordGroup>();

    list.forEach((item: TimelineData) => {
      const dateKey = DateUtil.formatDateKey(item.timestamp);
      if (!groupMap.has(dateKey)) {
        const d = new Date(item.timestamp);
        const y = d.getFullYear();
        const m = (d.getMonth() + 1).toString().padStart(2, '0');
        const day = d.getDate().toString().padStart(2, '0');
        const dateDisplay = `${y}年${m}月${day}日`;
        const relativeDay = DateUtil.getRelativeDayDesc(item.timestamp);

        groupMap.set(dateKey, {
          dateKey: dateKey,
          dateDisplay: dateDisplay,
          relativeDay: relativeDay,
          timestamp: item.timestamp,
          milkTotal: 0,
          poopCount: 0,
          sleepMinutes: 0,
          items: []
        });
      }

      const grp = groupMap.get(dateKey)!;
      grp.items.push(item);

      if (item.category === 'FEEDING' && item.amountDesc && item.amountDesc.endsWith('ml')) {
        const amt = parseInt(item.amountDesc);
        if (!isNaN(amt)) {
          grp.milkTotal += amt;
        }
      }
      if (item.category === 'ELIMINATION' && (item.title.includes('便') || item.icon.includes('💩'))) {
        grp.poopCount++;
      }
      if (item.category === 'SLEEP' && item.amountDesc && item.amountDesc.includes('分钟')) {
        const sMins = parseInt(item.amountDesc);
        if (!isNaN(sMins)) {
          grp.sleepMinutes += sMins;
        }
      }
    });

    const groups = Array.from(groupMap.values());
    groups.sort((a, b) => b.timestamp - a.timestamp);
    this.filteredGroups = groups;

    // 扁平化行结构：每一天有组头，接着是该日的所有Cell，完美支持 cell 间 8 的上下间距
    const rows: FlatListRow[] = [];
    groups.forEach((group: DateRecordGroup) => {
      rows.push({
        isHeader: true,
        headerData: group,
        key: `hdr_${group.dateKey}_${group.items.length}`
      });
      group.items.forEach((item: TimelineData) => {
        rows.push({
          isHeader: false,
          recordData: item,
          key: `cell_${item.id}`
        });
      });
    });

    this.refreshVersion++;
    this.flatRows = rows;
  }

  private confirmDeleteItem(item: TimelineData): void {
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
          } else if (item.category === 'GROWTH') {
            db.deleteGrowthRecord(item.id);
          } else if (item.category === 'VACCINE') {
            db.deleteVaccineRecord(item.id);
          } else if (item.category === 'EXPENSE') {
            db.deleteExpense(item.id);
          } else if (item.category === 'ROUTINE') {
            db.deleteRoutine(item.id);
          } else if (item.category === 'MESSAGE') {
            db.deleteParentsMessage(item.id);
          }
          this.refreshData();
          AppStorage.setOrCreate('APP_REFRESH_TRIGGER', Date.now());
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
          this.confirmDeleteItem(item);
        })
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.End)
  }

  @Builder
  renderGroupHeader(group: DateRecordGroup) {
    Row() {
      Row({ space: 6 }) {
        Text('📅')
          .fontSize(14)
        Text(group.dateDisplay)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
        if (group.relativeDay) {
          Text(group.relativeDay)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(group.relativeDay === '今天' ? '#FFFFFF' : AppConstants.COLOR_PRIMARY)
            .backgroundColor(group.relativeDay === '今天' ? AppConstants.COLOR_PRIMARY : '#FFF0EB')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(6)
        }
      }
      .alignItems(VerticalAlign.Center)

      Blank()

      Row({ space: 6 }) {
        if (group.milkTotal > 0 && (this.selectedCategory === 'ALL' || this.selectedCategory === 'FEEDING')) {
          Text(`🍼 ${group.milkTotal}ml`)
            .fontSize(11)
            .fontColor(AppConstants.COLOR_PRIMARY)
            .fontWeight(FontWeight.Medium)
        }
        if (group.poopCount > 0 && (this.selectedCategory === 'ALL' || this.selectedCategory === 'ELIMINATION')) {
          Text(`💩 ${group.poopCount}次`)
            .fontSize(11)
            .fontColor('#319795')
            .fontWeight(FontWeight.Medium)
        }
        if (group.sleepMinutes > 0 && (this.selectedCategory === 'ALL' || this.selectedCategory === 'SLEEP')) {
          Text(`🌙 ${(group.sleepMinutes / 60).toFixed(1)}h`)
            .fontSize(11)
            .fontColor(AppConstants.COLOR_SECONDARY)
            .fontWeight(FontWeight.Medium)
        }
        Text(`共 ${group.items.length} 条`)
          .fontSize(11)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 12, bottom: 4 })
  }

  @Builder
  renderTableCell(item: TimelineData) {
    Row({ space: 10 }) {
      // 1. 时间列
      Text(DateUtil.formatTime(item.timestamp))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppConstants.COLOR_TEXT_MAIN)
        .width(44)

      // 2. 类别 Emoji 图标
      Text(item.icon)
        .fontSize(20)

      // 3. 详细描述与核心数值
      Column({ space: 3 }) {
        Row({ space: 6 }) {
          Text(item.title)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)

          if (item.amountDesc) {
            Text(item.amountDesc)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_PRIMARY)
          }
        }

        if (item.detailDesc) {
          if (item.detailDesc.includes('首次添加新食材')) {
            Row() {
              Text(item.detailDesc)
                .fontSize(10)
                .fontWeight(FontWeight.Medium)
                .fontColor('#D97706')
            }
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .backgroundColor('#FEF3C7')
            .borderRadius(4)
          } else {
            Text(item.detailDesc)
              .fontSize(11)
              .fontColor(item.isAbnormal ? AppConstants.COLOR_DANGER : AppConstants.COLOR_TEXT_MUTED)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 4. 照护人标签与进入详情箭头
      Row({ space: 6 }) {
        Row({ space: 2 }) {
          Text(CaregiverConstants.getRoleIcon(item.caregiverId))
            .fontSize(10)
          Text(CaregiverConstants.getRoleName(item.caregiverId))
            .fontSize(10)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
        }
        .padding({ left: 6, right: 6, top: 3, bottom: 3 })
        .backgroundColor('#F3F4F6')
        .borderRadius(8)

        ArrowIcon({ arrowDirection: 'right', variant: 'gray', iconSize: 11 })
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(item.isAbnormal ? '#FFF5F5' : Color.White)
    .alignItems(VerticalAlign.Center)
    .borderRadius(14)
    .border({ width: 1, color: item.isAbnormal ? '#FEB2B2' : '#EFEBE4' })
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.03)', offsetX: 0, offsetY: 2 })
  }

  @Builder
  renderFilterChip(key: string, label: string, count: number, index: number) {
    Row({ space: 5 }) {
      Text(label)
        .fontSize(12)
        .fontWeight(this.selectedCategory === key ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.selectedCategory === key ? Color.White : AppConstants.COLOR_TEXT_MUTED)

      Text(`${count}`)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedCategory === key ? '#FFE8E0' : '#A0AEC0')
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(this.selectedCategory === key ? AppConstants.COLOR_PRIMARY : Color.White)
    .borderRadius(16)
    .scale({
      x: this.selectedCategory === key ? 1.05 : 1.0,
      y: this.selectedCategory === key ? 1.05 : 1.0
    })
    .shadow(this.selectedCategory === key ? {
      radius: 8,
      color: 'rgba(255, 122, 89, 0.28)',
      offsetY: 2
    } : { radius: 0, color: Color.Transparent })
    .border({
      width: 1,
      color: this.selectedCategory === key ? AppConstants.COLOR_PRIMARY : '#E2E8F0'
    })
    .animation({ duration: 220, curve: Curve.FastOutSlowIn })
    .onClick(() => {
      this.selectedCategory = key;
      this.rebuildGroups();
      this.categoryScroller.scrollToIndex(index, true, ScrollAlign.CENTER);
    })
  }

  build() {
    Column() {
      // 1. 顶部标题栏（移除共5条，保持标题优雅居中）
      Row() {
        Row({ space: 6 }) {
          ArrowIcon({ arrowDirection: 'left', variant: 'gray', iconSize: 14 })
          Text('返回')
            .fontSize(14)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
        }
        .padding({ left: 4, right: 8, top: 6, bottom: 6 })
        .onClick(() => {
          router.back();
        })
        .width(64)

        Text('全部记录')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 右侧留白保持标题居中对称
        Row()
          .width(64)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor(AppConstants.COLOR_BG_CREAM)

      // 2. 顶部分类筛选过滤栏（横向动态平滑滚动，带自适应居中对齐与切换动画）
      List({ space: 8, scroller: this.categoryScroller }) {
        ForEach(this.getCategoryTabs(), (tab: CategoryTabConfig, index: number) => {
          ListItem() {
            this.renderFilterChip(tab.key, tab.label, tab.count, index)
          }
        }, (tab: CategoryTabConfig) => `${tab.key}_${tab.count}`)
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16, top: 2, bottom: 4 })

      // 3. 每日流水分组表格列表（严格支持 cell 之间 8 的上下间距）
      if (this.flatRows.length === 0) {
        Column({ space: 12 }) {
          Text('📜')
            .fontSize(44)
          Text('暂无对应流水记录')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppConstants.COLOR_TEXT_MAIN)
          Text('记录宝宝的日常，历史记录将自动按天整理在此处')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.flatRows, (row: FlatListRow) => {
            if (row.isHeader && row.headerData) {
              ListItem() {
                this.renderGroupHeader(row.headerData)
              }
            } else if (!row.isHeader && row.recordData) {
              ListItem() {
                this.renderTableCell(row.recordData)
              }
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/record/RecordDetailPage',
                  params: {
                    recordId: row.recordData!.id,
                    category: row.recordData!.category
                  }
                });
              })
              .swipeAction({
                end: {
                  builder: () => {
                    this.renderSwipeDeleteButton(row.recordData!);
                  }
                },
                edgeEffect: SwipeEdgeEffect.Spring
              })
              .gesture(
                LongPressGesture({ duration: 350 })
                  .onAction(() => {
                    this.confirmDeleteItem(row.recordData!);
                  })
              )
            }
          }, (row: FlatListRow) => `${this.refreshVersion}_${this.selectedCategory}_${row.key}`)

          // 底部 spacer，防止浮动 TabBar 遮挡最后一条
          ListItem() {
            Row().height(88)
          }
        }
        .layoutWeight(1)
        .width('94%')
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
