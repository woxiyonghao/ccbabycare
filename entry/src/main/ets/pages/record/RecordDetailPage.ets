import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppConstants } from '../../common/constants/AppConstants';
import { DatabaseHelper, RoutineItem, ParentsMessageItem } from '../../common/database/DatabaseHelper';
import { FeedingRecord } from '../../common/models/FeedingRecord';
import { EliminationRecord } from '../../common/models/EliminationRecord';
import { SleepRecord } from '../../common/models/SleepRecord';
import { GrowthRecord } from '../../common/models/GrowthRecord';
import { VaccineRecord } from '../../common/models/VaccineRecord';
import { ExpenseRecord } from '../../common/models/ExpenseRecord';
import { DateUtil } from '../../common/utils/DateUtil';
import { CaregiverConstants } from '../../common/constants/CaregiverConstants';
import { ArrowIcon } from '../../common/components/ArrowIcon';

interface DetailFieldItem {
  label: string;
  value: string;
  isHighlight?: boolean;
  isWarning?: boolean;
}

/**
 * 记录详情全览页
 * 解决列表中详细字样、对照提示、备注信息被省略截断（...）的问题
 * 完整展示所有记录字段，提供长文本完整换行展示及便捷删除操作
 */
@Entry
@Component
struct RecordDetailPage {
  @State recordId: string = '';
  @State category: string = '';

  // 基础展示数据
  @State icon: string = '📝';
  @State categoryTitle: string = '记录详情';
  @State highlightValue: string = '';
  @State recordTimestamp: number = 0;
  @State caregiverId: string = 'MOM';
  @State isAbnormal: boolean = false;
  @State fields: DetailFieldItem[] = [];

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      if (params.recordId) {
        this.recordId = params.recordId as string;
      }
      if (params.category) {
        this.category = params.category as string;
      }
    }
    this.loadRecordDetail();
  }

  private loadRecordDetail(): void {
    const db = DatabaseHelper.getInstance();

    if (this.category === 'GROWTH') {
      const records = db.getGrowthRecords();
      const r = records.find(item => item.id === this.recordId);
      if (r) {
        this.icon = '📈';
        this.categoryTitle = '成长体检记录';
        this.highlightValue = `${r.height} cm · ${r.weight} kg`;
        this.recordTimestamp = r.recordDate || r.createdAt;
        this.caregiverId = r.caregiverId || 'MOM';

        const fList: DetailFieldItem[] = [];
        fList.push({ label: '测量月龄', value: `${r.monthAge} 个月` });
        fList.push({ label: '宝宝身高', value: `${r.height} cm (状态: ${r.heightStatus || '正常'})` });
        fList.push({ label: '宝宝体重', value: `${r.weight} kg (状态: ${r.weightStatus || '正常'})` });
        if (r.headCircumference && r.headCircumference > 0) {
          fList.push({ label: '宝宝头围', value: `${r.headCircumference} cm` });
        }
        fList.push({ label: '测量地点', value: r.measureLocation || '家庭测量' });
        if (r.percentileText) {
          fList.push({ label: 'WHO标准比对评估', value: r.percentileText, isHighlight: true });
        }
        if (r.notes) {
          fList.push({ label: '体检详细备注', value: r.notes });
        }
        this.fields = fList;
        return;
      }
    }

    if (this.category === 'FEEDING') {
      const records = db.getFeedingRecords();
      const f = records.find(item => item.id === this.recordId);
      if (f) {
        this.icon = '🍼';
        this.recordTimestamp = f.recordTime;
        this.caregiverId = f.caregiverId;

        const fList: DetailFieldItem[] = [];
        if (f.feedingType === 'BREASTFEEDING') {
          this.icon = '🤱';
          this.categoryTitle = '母乳亲喂记录';
          this.highlightValue = `${f.amount} 分钟`;
          fList.push({ label: '喂养方式', value: '母乳亲喂' });
          fList.push({ label: '单侧时长', value: `左侧 ${f.leftDuration} 分钟 · 右侧 ${f.rightDuration} 分钟` });
          if (f.suckStatus) fList.push({ label: '吸吮状态', value: f.suckStatus });
        } else if (f.feedingType === 'BOTTLE') {
          this.categoryTitle = '母乳瓶喂记录';
          this.highlightValue = `${f.amount} ml`;
          fList.push({ label: '喂养方式', value: '母乳瓶喂' });
          fList.push({ label: '喂奶量', value: `${f.amount} ml` });
          if (f.milkSource) fList.push({ label: '母乳来源', value: f.milkSource });
        } else if (f.feedingType === 'SOLIDS') {
          this.icon = '🥣';
          this.categoryTitle = '宝宝辅食记录';
          this.highlightValue = f.amount > 0 ? `${f.amount} g` : (f.solidsName || '宝宝辅食');
          fList.push({ label: '辅食名称', value: f.solidsName || '辅食' });
          if (f.amount > 0) fList.push({ label: '摄入重量', value: `${f.amount} g` });
          if (f.solidsIngredients) fList.push({ label: '辅食食材组成', value: f.solidsIngredients });
          if (f.isNewFood) fList.push({ label: '新食材标记', value: '⭐ 首次添加的新食材', isHighlight: true });
          if (f.hasAllergy) {
            fList.push({ label: '过敏反应警告', value: `⚠️ ${f.allergyNote || '出现疑似过敏不适'}`, isWarning: true });
            this.isAbnormal = true;
          }
        } else {
          this.categoryTitle = '配方奶喂养记录';
          this.highlightValue = `${f.amount} ml`;
          fList.push({ label: '喂养方式', value: '配方奶' });
          fList.push({ label: '奶量', value: `${f.amount} ml` });
          if (f.formulaStage) fList.push({ label: '奶粉段位', value: f.formulaStage });
          if (f.scoops) fList.push({ label: '冲调奶粉勺数', value: `${f.scoops} 勺` });
          if (f.waterAmount) fList.push({ label: '冲调用水量', value: `${f.waterAmount} ml` });
        }
        if (f.notes) fList.push({ label: '详细备注说明', value: f.notes });
        this.fields = fList;
        return;
      }
    }

    if (this.category === 'ELIMINATION') {
      const records = db.getEliminationRecords();
      const e = records.find(item => item.id === this.recordId);
      if (e) {
        this.icon = e.eliminationType === 'PEE' ? '💧' : (e.eliminationType === 'MIXED' ? '💩💧' : '💩');
        this.categoryTitle = e.eliminationType === 'PEE' ? '排尿记录' : (e.eliminationType === 'MIXED' ? '排便+排尿记录' : '排便记录');
        this.highlightValue = `${e.volume || '中量'} · ${e.stoolTexture || '正常'}`;
        this.recordTimestamp = e.recordTime;
        this.caregiverId = e.caregiverId;
        this.isAbnormal = e.isAbnormal === 1;

        const fList: DetailFieldItem[] = [];
        fList.push({ label: '排泄类型', value: this.categoryTitle });
        fList.push({ label: '排泄量', value: e.volume || '中等量' });
        if (e.stoolTexture) fList.push({ label: '便便性状', value: e.stoolTexture });
        if (e.stoolColor) fList.push({ label: '便便颜色', value: e.stoolColor });
        if (e.isAbnormal === 1) {
          fList.push({ label: '异常状况警示', value: `⚠️ 标记为异常: ${e.abnormalNotes || '请注意宝宝消化吸收'}`, isWarning: true });
        }
        if (e.notes) fList.push({ label: '观察详细备注', value: e.notes });
        this.fields = fList;
        return;
      }
    }

    if (this.category === 'SLEEP') {
      const records = db.getSleepRecords();
      const s = records.find(item => item.id === this.recordId);
      if (s) {
        this.icon = '🌙';
        this.categoryTitle = '宝宝睡眠记录';
        this.highlightValue = `${s.durationMinutes} 分钟 (${(s.durationMinutes / 60).toFixed(1)}小时)`;
        this.recordTimestamp = s.startTime;
        this.caregiverId = s.caregiverId;

        const fList: DetailFieldItem[] = [];
        fList.push({ label: '睡眠类型', value: s.sleepType || '小睡' });
        fList.push({ label: '入睡时段', value: `${DateUtil.formatTime(s.startTime)} ~ ${DateUtil.formatTime(s.endTime)}` });
        fList.push({ label: '睡眠时长', value: `${s.durationMinutes} 分钟` });
        fList.push({ label: '入睡方式', value: s.method || '自主入睡' });
        if (s.nightWakeCount !== undefined && s.nightWakeCount > 0) {
          fList.push({ label: '期间夜醒次数', value: `${s.nightWakeCount} 次` });
        }
        if (s.notes) fList.push({ label: '睡眠状态备注', value: s.notes });
        this.fields = fList;
        return;
      }
    }

    if (this.category === 'VACCINE') {
      const records = db.getVaccineRecords();
      const v = records.find(item => item.id === this.recordId);
      if (v) {
        this.icon = '💉';
        this.categoryTitle = '疫苗接种详情';
        this.highlightValue = `${v.vaccineName} (${v.dose})`;
        this.recordTimestamp = v.vaccinatedDate || v.createdAt;

        const fList: DetailFieldItem[] = [];
        fList.push({ label: '疫苗全称', value: v.vaccineName });
        fList.push({ label: '接种剂次', value: v.dose });
        fList.push({ label: '接种状态', value: v.isDone === 1 ? '✅ 已接种完成' : '⏳ 待接种规划', isHighlight: v.isDone === 1 });
        fList.push({ label: '疫苗性质', value: v.isFree === 1 ? '免费第一类疫苗' : '自费第二类疫苗' });
        if (v.monthLabel) fList.push({ label: '推荐月龄/日期', value: v.monthLabel });
        if (v.organization) fList.push({ label: '接种门诊/机构', value: v.organization });
        if (v.batchNumber) fList.push({ label: '疫苗生产批号', value: v.batchNumber });
        if (v.adverseReaction) fList.push({ label: '不良反应记录', value: v.adverseReaction, isWarning: true });
        if (v.notes) fList.push({ label: '接种详细说明', value: v.notes });
        this.fields = fList;
        return;
      }
    }

    if (this.category === 'EXPENSE') {
      const records = db.getExpenses();
      const exp = records.find(item => item.id === this.recordId);
      if (exp) {
        this.icon = '💰';
        this.categoryTitle = '养娃账本开销';
        this.highlightValue = `¥ ${exp.amount.toFixed(2)}`;
        this.recordTimestamp = exp.expenseDate || exp.createdAt;

        const fList: DetailFieldItem[] = [];
        fList.push({ label: '支出类目', value: exp.category });
        fList.push({ label: '支出金额', value: `¥ ${exp.amount.toFixed(2)}`, isHighlight: true });
        if (exp.notes) fList.push({ label: '购买明细/备注', value: exp.notes });
        this.fields = fList;
        return;
      }
    }

    if (this.category === 'ROUTINE') {
      const records = db.getRoutines();
      const r = records.find(item => item.id === this.recordId);
      if (r) {
        this.icon = r.emoji || '⏰';
        this.categoryTitle = '规律作息详情';
        this.highlightValue = `${r.time} · ${r.title}`;
        this.recordTimestamp = r.createdAt;

        const fList: DetailFieldItem[] = [];
        fList.push({ label: '安排时点', value: r.time });
        fList.push({ label: '节律项目', value: r.title });
        if (r.notes) fList.push({ label: '详细作息指南', value: r.notes });
        this.fields = fList;
        return;
      }
    }

    if (this.category === 'MESSAGE') {
      const records = db.getParentsMessages();
      const m = records.find(item => item.id === this.recordId);
      if (m) {
        this.icon = '💌';
        this.categoryTitle = '父母爱心寄语';
        this.highlightValue = `落款：${m.signature || '爸爸妈妈'}`;
        this.recordTimestamp = m.createdAt;

        const fList: DetailFieldItem[] = [];
        fList.push({ label: '寄语内容', value: m.content, isHighlight: true });
        fList.push({ label: '亲情署名', value: m.signature || '永远爱你的爸爸妈妈' });
        this.fields = fList;
        return;
      }
    }
  }

  private confirmDeleteCurrentRecord(): void {
    AlertDialog.show({
      title: '删除此条记录',
      message: `确定要删除此条「${this.categoryTitle}」吗？删除后数据不可恢复。`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppConstants.COLOR_DANGER,
        action: () => {
          const db = DatabaseHelper.getInstance();
          if (this.category === 'FEEDING') {
            db.deleteFeedingRecord(this.recordId);
          } else if (this.category === 'ELIMINATION') {
            db.deleteEliminationRecord(this.recordId);
          } else if (this.category === 'SLEEP') {
            db.deleteSleepRecord(this.recordId);
          } else if (this.category === 'GROWTH') {
            db.deleteGrowthRecord(this.recordId);
          } else if (this.category === 'VACCINE') {
            db.deleteVaccineRecord(this.recordId);
          } else if (this.category === 'EXPENSE') {
            db.deleteExpense(this.recordId);
          } else if (this.category === 'ROUTINE') {
            db.deleteRoutine(this.recordId);
          } else if (this.category === 'MESSAGE') {
            db.deleteParentsMessage(this.recordId);
          }

          AppStorage.setOrCreate('APP_REFRESH_TRIGGER', Date.now());
          try {
            promptAction.showToast({ message: '已成功删除该条记录' });
          } catch (e) {}
          router.back();
        }
      }
    });
  }

  build() {
    Column() {
      // 1. 顶部导航栏
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
        .width(72)

        Text('记录详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 右侧留白保持标题居中对称（底部已有删除按钮）
        Row()
          .width(72)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor(AppConstants.COLOR_BG_CREAM)

      // 2. 详情内容展示区
      Scroll() {
        Column({ space: 14 }) {
          // 2.1 头部核心信息卡片
          Column({ space: 10 }) {
            Row({ space: 12 }) {
              Text(this.icon)
                .fontSize(38)

              Column({ space: 4 }) {
                Text(this.categoryTitle)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppConstants.COLOR_TEXT_MAIN)

                if (this.highlightValue) {
                  Text(this.highlightValue)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppConstants.COLOR_PRIMARY)
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')

            Divider()
              .color('#F0ECE4')
              .strokeWidth(1)

            // 时间与记录人信息条
            Row() {
              Row({ space: 4 }) {
                Text('🕒')
                  .fontSize(12)
                Text(this.recordTimestamp > 0 ? `${DateUtil.formatDate(this.recordTimestamp)} ${DateUtil.formatTime(this.recordTimestamp)}` : '刚才')
                  .fontSize(12)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }

              Blank()

              Row({ space: 4 }) {
                Text(CaregiverConstants.getRoleIcon(this.caregiverId))
                  .fontSize(11)
                Text(`${CaregiverConstants.getRoleName(this.caregiverId)} 记录`)
                  .fontSize(11)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)
              }
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .backgroundColor('#F3F4F6')
              .borderRadius(8)
            }
            .width('100%')
          }
          .width('100%')
          .padding(18)
          .backgroundColor(this.isAbnormal ? '#FFF5F5' : AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: this.isAbnormal ? '#FEB2B2' : AppConstants.COLOR_BORDER })
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.03)', offsetY: 2 })

          // 2.2 详细指标列表（完整展示所有字段，绝不截断省略）
          Column({ space: 12 }) {
            Row() {
              Text('📋 完整记录明细')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
              Blank()
            }
            .width('100%')
            .padding({ bottom: 4 })

            ForEach(this.fields, (field: DetailFieldItem) => {
              Column({ space: 4 }) {
                Text(field.label)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppConstants.COLOR_TEXT_MUTED)

                // 完整展示文本，支持多行自然换行，不设任何 maxLines 或省略
                Text(field.value)
                  .fontSize(14)
                  .lineHeight(22)
                  .fontColor(field.isWarning ? AppConstants.COLOR_DANGER : (field.isHighlight ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_MAIN))
                  .fontWeight(field.isHighlight ? FontWeight.Medium : FontWeight.Normal)
                  .width('100%')
              }
              .width('100%')
              .padding({ left: 14, right: 14, top: 10, bottom: 10 })
              .backgroundColor(field.isWarning ? '#FFF5F5' : '#FAFAFA')
              .borderRadius(10)
              .border({ width: 1, color: field.isWarning ? '#FED7D7' : '#F0ECE4' })
              .alignItems(HorizontalAlign.Start)
            })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 2.3 底部删除操作按钮
          Button('删除该条记录', { type: ButtonType.Normal })
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppConstants.COLOR_DANGER)
            .backgroundColor('#FFF5F5')
            .border({ width: 1, color: '#FEB2B2' })
            .borderRadius(12)
            .margin({ top: 8, bottom: 24 })
            .onClick(() => {
              this.confirmDeleteCurrentRecord();
            })
        }
        .width('94%')
        .padding({ top: 6, bottom: 40 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
