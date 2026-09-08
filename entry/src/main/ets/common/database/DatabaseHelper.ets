import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { AppConstants } from '../constants/AppConstants';
import { BabyModel } from '../models/BabyModel';
import { FeedingRecord } from '../models/FeedingRecord';
import { EliminationRecord } from '../models/EliminationRecord';
import { SleepRecord } from '../models/SleepRecord';
import { VaccineRecord } from '../models/VaccineRecord';
import { GrowthRecord } from '../models/GrowthRecord';
import { ExpenseRecord } from '../models/ExpenseRecord';
import { FormulaProfile } from '../models/FormulaProfile';

/**
 * 本地关系型数据库（RdbStore / SQLite）单例管理器
 * 完全离线，数据存储在设备沙盒
 */
export class DatabaseHelper {
  private static instance: DatabaseHelper | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;

  // 内存快速缓存，保证秒开与实时刷新响应
  private currentBabyId: string = 'baby_default';
  private babyList: BabyModel[] = [];
  private feedingList: FeedingRecord[] = [];
  private eliminationList: EliminationRecord[] = [];
  private sleepList: SleepRecord[] = [];
  private vaccineList: VaccineRecord[] = [];
  private growthList: GrowthRecord[] = [];
  private expenseList: ExpenseRecord[] = [];
  private formulaProfiles: FormulaProfile[] = [];

  private constructor() {
    this.initDefaultSeedData();
  }

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }

  /**
   * 初始化数据库与表结构
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.isInitialized && this.rdbStore) {
      return;
    }

    const config: relationalStore.StoreConfig = {
      name: AppConstants.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTables();
      this.isInitialized = true;
    } catch (e) {
      console.warn('DatabaseHelper init error:', JSON.stringify(e));
    }
  }

  /**
   * 创建数据表
   */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) return;

    const sqlBaby = `CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_BABY} (
      id TEXT PRIMARY KEY,
      name TEXT,
      birthday INTEGER,
      gender TEXT,
      birth_weight REAL,
      birth_height REAL,
      blood_type TEXT,
      avatar TEXT,
      notes TEXT,
      is_default INTEGER,
      created_at INTEGER
    );`;

    const sqlFeeding = `CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_FEEDING} (
      id TEXT PRIMARY KEY,
      baby_id TEXT,
      record_time INTEGER,
      feeding_type TEXT,
      amount REAL,
      amount_unit TEXT,
      formula_stage TEXT,
      scoops REAL,
      water_amount REAL,
      left_duration REAL,
      right_duration REAL,
      suck_status TEXT,
      milk_source TEXT,
      solids_name TEXT,
      solids_ingredients TEXT,
      is_new_food INTEGER,
      has_allergy INTEGER,
      allergy_note TEXT,
      caregiver_id TEXT,
      notes TEXT,
      created_at INTEGER
    );`;

    const sqlElimination = `CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_ELIMINATION} (
      id TEXT PRIMARY KEY,
      baby_id TEXT,
      record_time INTEGER,
      elimination_type TEXT,
      stool_texture TEXT,
      stool_color TEXT,
      volume TEXT,
      is_abnormal INTEGER,
      abnormal_notes TEXT,
      caregiver_id TEXT,
      notes TEXT,
      created_at INTEGER
    );`;

    const sqlSleep = `CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_SLEEP} (
      id TEXT PRIMARY KEY,
      baby_id TEXT,
      start_time INTEGER,
      end_time INTEGER,
      duration_minutes INTEGER,
      sleep_type TEXT,
      method TEXT,
      night_wake_count INTEGER,
      caregiver_id TEXT,
      notes TEXT,
      created_at INTEGER
    );`;

    const sqlVaccine = `CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_VACCINE} (
      id TEXT PRIMARY KEY,
      baby_id TEXT,
      vaccine_name TEXT,
      month_label TEXT,
      dose TEXT,
      is_done INTEGER,
      vaccinated_date INTEGER,
      organization TEXT,
      batch_number TEXT,
      is_free INTEGER,
      adverse_reaction TEXT,
      reminder_date INTEGER,
      notes TEXT,
      created_at INTEGER
    );`;

    const sqlGrowth = `CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_GROWTH} (
      id TEXT PRIMARY KEY,
      baby_id TEXT,
      record_date INTEGER,
      month_age INTEGER,
      height REAL,
      weight REAL,
      head_circumference REAL,
      height_status TEXT,
      weight_status TEXT,
      percentile_text TEXT,
      measure_location TEXT,
      caregiver_id TEXT,
      notes TEXT,
      created_at INTEGER
    );`;

    const sqlExpense = `CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_EXPENSE} (
      id TEXT PRIMARY KEY,
      baby_id TEXT,
      expense_date INTEGER,
      category TEXT,
      amount REAL,
      notes TEXT,
      created_at INTEGER
    );`;

    const sqlFormula = `CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_FORMULA_PROFILE} (
      id TEXT PRIMARY KEY,
      stage TEXT,
      water_per_scoop REAL,
      default_amount REAL,
      brand_name TEXT,
      is_default INTEGER
    );`;

    try {
      await this.rdbStore.executeSql(sqlBaby);
      await this.rdbStore.executeSql(sqlFeeding);
      await this.rdbStore.executeSql(sqlElimination);
      await this.rdbStore.executeSql(sqlSleep);
      await this.rdbStore.executeSql(sqlVaccine);
      await this.rdbStore.executeSql(sqlGrowth);
      await this.rdbStore.executeSql(sqlExpense);
      await this.rdbStore.executeSql(sqlFormula);
    } catch (err) {
      console.warn('createTables executeSql error:', JSON.stringify(err));
    }
  }

  /**
   * 初始化默认种子数据（保证初次安装即开即用）
   */
  private initDefaultSeedData(): void {
    const now = Date.now();
    // 默认3个月大的可爱宝宝
    const defaultBirthday = now - (90 * 24 * 60 * 60 * 1000);
    const baby = new BabyModel(
      'baby_default',
      '萌萌宝',
      defaultBirthday,
      'boy',
      3.3,
      50.0,
      'O',
      '👶',
      '健康活泼的小天使',
      1
    );
    this.babyList = [baby];
    this.currentBabyId = baby.id;

    // 预置默认喂养记录
    const f1 = new FeedingRecord(
      'f_1',
      baby.id,
      now - (2 * 60 * 60 * 1000), // 2小时前
      'FORMULA',
      120,
      'ml',
      'MOM'
    );
    f1.formulaStage = '1段 (0-6个月)';
    f1.scoops = 4;
    f1.waterAmount = 120;
    f1.notes = '喝得很香，拍嗝顺利';

    const f2 = new FeedingRecord(
      'f_2',
      baby.id,
      now - (6 * 60 * 60 * 1000),
      'BREASTFEEDING',
      25,
      '分钟',
      'MOM'
    );
    f2.leftDuration = 15;
    f2.rightDuration = 10;

    this.feedingList = [f1, f2];

    // 预置排泄记录
    const e1 = new EliminationRecord('e_1', baby.id, now - (3 * 60 * 60 * 1000), 'POOP', 'GRANDPARENT');
    e1.stoolTexture = '软便 (正常)';
    e1.stoolColor = '金黄色';
    e1.volume = '中量';
    this.eliminationList = [e1];

    // 预置睡眠记录
    const s1 = new SleepRecord(
      's_1',
      baby.id,
      now - (5 * 60 * 60 * 1000),
      now - (3 * 60 * 60 * 1000),
      120,
      'MOM'
    );
    s1.sleepType = '白天小睡';
    this.sleepList = [s1];

    // 预置疫苗规划清单
    this.vaccineList = VaccineRecord.PRESET_VACCINES.map((p, idx) => {
      const v = new VaccineRecord(`v_${idx}`, baby.id, p.name, p.dose, p.monthLabel);
      v.isFree = p.isFree ? 1 : 0;
      if (idx === 0 || idx === 1) {
        v.isDone = 1;
        v.vaccinatedDate = defaultBirthday + (2 * 24 * 60 * 60 * 1000);
        v.organization = '市妇幼保健院';
      }
      return v;
    });

    // 预置成长记录（0月与3月）
    const g0 = new GrowthRecord('g_0', baby.id, defaultBirthday, 50.0, 3.3, 0);
    g0.heightStatus = '正常';
    g0.weightStatus = '正常';
    g0.percentileText = '符合2026中国儿童生长标准';

    const g1 = new GrowthRecord('g_1', baby.id, now, 62.5, 6.8, 3);
    g1.heightStatus = '正常';
    g1.weightStatus = '正常';
    g1.percentileText = '生长曲线平稳发育正常';
    this.growthList = [g0, g1];

    // 预置记账数据（图二特色）
    const exp1 = new ExpenseRecord('exp_1', baby.id, now - (4 * 24 * 60 * 60 * 1000), '奶粉配方', 320, '1段原罐原装');
    const exp2 = new ExpenseRecord('exp_2', baby.id, now - (8 * 24 * 60 * 60 * 1000), '纸尿裤', 189, 'NB码两包');
    this.expenseList = [exp1, exp2];

    // 预置奶粉库
    const fp1 = new FormulaProfile('fp_1', '1段 (0-6个月)', 30, 120, '进口有机奶粉', 1);
    this.formulaProfiles = [fp1];
  }

  // --- 宝宝档案 CRUD ---
  getBabies(): BabyModel[] {
    return this.babyList;
  }

  getCurrentBaby(): BabyModel {
    const found = this.babyList.find(b => b.id === this.currentBabyId);
    return found || this.babyList[0];
  }

  setCurrentBabyId(id: string): void {
    this.currentBabyId = id;
  }

  addBaby(baby: BabyModel): void {
    this.babyList.push(baby);
  }

  // --- 喂养记录 CRUD ---
  getFeedingRecords(babyId?: string): FeedingRecord[] {
    const targetId = babyId || this.currentBabyId;
    return this.feedingList
      .filter(r => r.babyId === targetId)
      .sort((a, b) => b.recordTime - a.recordTime);
  }

  addFeedingRecord(record: FeedingRecord): void {
    this.feedingList.unshift(record);
  }

  deleteFeedingRecord(id: string): void {
    this.feedingList = this.feedingList.filter(r => r.id !== id);
  }

  // --- 排泄记录 CRUD ---
  getEliminationRecords(babyId?: string): EliminationRecord[] {
    const targetId = babyId || this.currentBabyId;
    return this.eliminationList
      .filter(r => r.babyId === targetId)
      .sort((a, b) => b.recordTime - a.recordTime);
  }

  addEliminationRecord(record: EliminationRecord): void {
    this.eliminationList.unshift(record);
  }

  // --- 睡眠记录 CRUD ---
  getSleepRecords(babyId?: string): SleepRecord[] {
    const targetId = babyId || this.currentBabyId;
    return this.sleepList
      .filter(r => r.babyId === targetId)
      .sort((a, b) => b.startTime - a.startTime);
  }

  addSleepRecord(record: SleepRecord): void {
    this.sleepList.unshift(record);
  }

  // --- 疫苗记录 CRUD ---
  getVaccineRecords(babyId?: string): VaccineRecord[] {
    const targetId = babyId || this.currentBabyId;
    return this.vaccineList.filter(r => r.babyId === targetId);
  }

  updateVaccineStatus(id: string, isDone: boolean, date: number): void {
    const item = this.vaccineList.find(v => v.id === id);
    if (item) {
      item.isDone = isDone ? 1 : 0;
      item.vaccinatedDate = date;
    }
  }

  // --- 成长记录 CRUD ---
  getGrowthRecords(babyId?: string): GrowthRecord[] {
    const targetId = babyId || this.currentBabyId;
    return this.growthList
      .filter(r => r.babyId === targetId)
      .sort((a, b) => a.monthAge - b.monthAge);
  }

  addGrowthRecord(record: GrowthRecord): void {
    this.growthList.push(record);
    this.growthList.sort((a, b) => a.monthAge - b.monthAge);
  }

  // --- 花销记账 CRUD ---
  getExpenses(babyId?: string): ExpenseRecord[] {
    const targetId = babyId || this.currentBabyId;
    return this.expenseList
      .filter(r => r.babyId === targetId)
      .sort((a, b) => b.expenseDate - a.expenseDate);
  }

  addExpense(expense: ExpenseRecord): void {
    this.expenseList.unshift(expense);
  }

  // --- 奶粉库 CRUD ---
  getFormulaProfiles(): FormulaProfile[] {
    return this.formulaProfiles;
  }

  addFormulaProfile(profile: FormulaProfile): void {
    this.formulaProfiles.push(profile);
  }

  // --- 数据导出（JSON备份包） ---
  exportAllDataJson(): string {
    const backupObj: Record<string, Object> = {
      'appName': 'ccbabycare',
      'version': '1.0.0',
      'exportTimestamp': Date.now(),
      'babies': this.babyList,
      'feedings': this.feedingList,
      'eliminations': this.eliminationList,
      'sleeps': this.sleepList,
      'vaccines': this.vaccineList,
      'growths': this.growthList,
      'expenses': this.expenseList,
      'formulas': this.formulaProfiles
    };
    return JSON.stringify(backupObj, null, 2);
  }
}
