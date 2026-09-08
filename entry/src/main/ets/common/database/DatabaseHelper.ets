import relationalStore from '@ohos.data.relationalStore';
import dataPreferences from '@ohos.data.preferences';
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
 * 本地关系型数据库（RdbStore / SQLite）与 Preferences 极速缓存单例管理器
 * 实现真实的本地 SQLite 持久化存储与极速内存缓存秒开同步
 */
export class DatabaseHelper {
  private static instance: DatabaseHelper | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private pref: dataPreferences.Preferences | null = null;
  private isInitialized: boolean = false;
  private isUserOnboarded: boolean = false;
  private cachedBaby: BabyModel | null = null;

  // 内存快速缓存，保证界面实时秒开与无感响应
  private currentBabyId: string = '';
  private babyList: BabyModel[] = [];
  private feedingList: FeedingRecord[] = [];
  private eliminationList: EliminationRecord[] = [];
  private sleepList: SleepRecord[] = [];
  private vaccineList: VaccineRecord[] = [];
  private growthList: GrowthRecord[] = [];
  private expenseList: ExpenseRecord[] = [];
  private formulaProfiles: FormulaProfile[] = [];

  private constructor() {
    this.initReferenceDataInMemory();
  }

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }

  /**
   * 初始化 Preferences 极速缓存与 SQLite 数据库
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.isInitialized && this.rdbStore) {
      return;
    }

    // 1. 初始化 Preferences 快速恢复用户数据
    try {
      this.pref = await dataPreferences.getPreferences(context, 'ccbabycare_user_store');
      const hasUserPref = await this.pref.get('HAS_USER_DATA', false) as boolean;
      const cachedBabyStr = await this.pref.get('CACHED_BABY_INFO', '') as string;
      if (cachedBabyStr) {
        try {
          const parsed = JSON.parse(cachedBabyStr) as Record<string, Object>;
          this.cachedBaby = new BabyModel(
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
          AppStorage.setOrCreate('CACHE_BABY_INFO', cachedBabyStr);
        } catch (e) {}
      }
      this.isUserOnboarded = hasUserPref;
      AppStorage.setOrCreate('HAS_USER_DATA', hasUserPref);
    } catch (e) {
      console.warn('Preferences init error:', JSON.stringify(e));
    }

    // 2. 初始化 SQLite 数据库
    const config: relationalStore.StoreConfig = {
      name: AppConstants.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTables();
      await this.loadOrSeedDatabase();
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
   * 检查 SQLite 是否为空；若已有宝宝数据则加载到内存与极速缓存中，若为空则仅初始化基础字典
   */
  private async loadOrSeedDatabase(): Promise<void> {
    if (!this.rdbStore) return;

    try {
      const babyPred = new relationalStore.RdbPredicates(AppConstants.TABLE_BABY);
      const resultSet = await this.rdbStore.query(babyPred);
      const babyCount = resultSet.rowCount;
      resultSet.close();

      if (babyCount > 0) {
        // 从真实 SQLite 数据库加载全部数据
        await this.loadAllDataFromDb();
        if (this.babyList.length > 0 && !!this.babyList[0].name.trim()) {
          this.isUserOnboarded = true;
          this.cacheBabyProfile(this.babyList[0]);
        }
      } else {
        // 数据库首次创建或清空后：无宝宝档案
        this.babyList = [];
        this.currentBabyId = '';
        this.isUserOnboarded = false;
        await this.seedReferenceDataOnly();
      }
    } catch (err) {
      console.warn('loadOrSeedDatabase error:', JSON.stringify(err));
    }
  }

  /**
   * 将内存默认种子写入真实 SQLite
   */
  private async persistSeedDataToDb(): Promise<void> {
    if (!this.rdbStore) return;

    try {
      // 1. 宝宝
      for (const baby of this.babyList) {
        await this.insertBabyToDb(baby);
      }
      // 2. 喂养
      for (const f of this.feedingList) {
        await this.insertFeedingToDb(f);
      }
      // 3. 排泄
      for (const e of this.eliminationList) {
        await this.insertEliminationToDb(e);
      }
      // 4. 睡眠
      for (const s of this.sleepList) {
        await this.insertSleepToDb(s);
      }
      // 5. 疫苗
      for (const v of this.vaccineList) {
        await this.insertVaccineToDb(v);
      }
      // 6. 生长
      for (const g of this.growthList) {
        await this.insertGrowthToDb(g);
      }
      // 7. 花销
      for (const exp of this.expenseList) {
        await this.insertExpenseToDb(exp);
      }
      // 8. 奶粉库
      for (const fp of this.formulaProfiles) {
        await this.insertFormulaToDb(fp);
      }
    } catch (e) {
      console.warn('persistSeedDataToDb error:', JSON.stringify(e));
    }
  }

  /**
   * 从真实 SQLite 数据库加载所有数据
   */
  private async loadAllDataFromDb(): Promise<void> {
    if (!this.rdbStore) return;

    try {
      // 1. 宝宝
      const babyRs = await this.rdbStore.query(new relationalStore.RdbPredicates(AppConstants.TABLE_BABY));
      const babies: BabyModel[] = [];
      while (babyRs.goToNextRow()) {
        const b = new BabyModel(
          babyRs.getString(babyRs.getColumnIndex('id')),
          babyRs.getString(babyRs.getColumnIndex('name')),
          babyRs.getLong(babyRs.getColumnIndex('birthday')),
          babyRs.getString(babyRs.getColumnIndex('gender')),
          babyRs.getDouble(babyRs.getColumnIndex('birth_weight')),
          babyRs.getDouble(babyRs.getColumnIndex('birth_height')),
          babyRs.getString(babyRs.getColumnIndex('blood_type')),
          babyRs.getString(babyRs.getColumnIndex('avatar')),
          babyRs.getString(babyRs.getColumnIndex('notes')),
          babyRs.getLong(babyRs.getColumnIndex('is_default'))
        );
        babies.push(b);
      }
      babyRs.close();
      if (babies.length > 0) {
        this.babyList = babies;
        this.currentBabyId = babies[0].id;
      }

      // 2. 喂养
      const feedRs = await this.rdbStore.query(new relationalStore.RdbPredicates(AppConstants.TABLE_FEEDING));
      const feeds: FeedingRecord[] = [];
      while (feedRs.goToNextRow()) {
        const f = new FeedingRecord(
          feedRs.getString(feedRs.getColumnIndex('id')),
          feedRs.getString(feedRs.getColumnIndex('baby_id')),
          feedRs.getLong(feedRs.getColumnIndex('record_time')),
          feedRs.getString(feedRs.getColumnIndex('feeding_type')),
          feedRs.getDouble(feedRs.getColumnIndex('amount')),
          feedRs.getString(feedRs.getColumnIndex('amount_unit')),
          feedRs.getString(feedRs.getColumnIndex('caregiver_id'))
        );
        f.notes = feedRs.getString(feedRs.getColumnIndex('notes'));
        f.formulaStage = feedRs.getString(feedRs.getColumnIndex('formula_stage'));
        f.scoops = feedRs.getDouble(feedRs.getColumnIndex('scoops'));
        f.waterAmount = feedRs.getDouble(feedRs.getColumnIndex('water_amount'));
        f.leftDuration = feedRs.getDouble(feedRs.getColumnIndex('left_duration'));
        f.rightDuration = feedRs.getDouble(feedRs.getColumnIndex('right_duration'));
        f.solidsName = feedRs.getString(feedRs.getColumnIndex('solids_name'));
        feeds.push(f);
      }
      feedRs.close();
      this.feedingList = feeds;

      // 3. 排便
      const elimRs = await this.rdbStore.query(new relationalStore.RdbPredicates(AppConstants.TABLE_ELIMINATION));
      const elims: EliminationRecord[] = [];
      while (elimRs.goToNextRow()) {
        const e = new EliminationRecord(
          elimRs.getString(elimRs.getColumnIndex('id')),
          elimRs.getString(elimRs.getColumnIndex('baby_id')),
          elimRs.getLong(elimRs.getColumnIndex('record_time')),
          elimRs.getString(elimRs.getColumnIndex('elimination_type')),
          elimRs.getString(elimRs.getColumnIndex('caregiver_id'))
        );
        e.stoolTexture = elimRs.getString(elimRs.getColumnIndex('stool_texture'));
        e.stoolColor = elimRs.getString(elimRs.getColumnIndex('stool_color'));
        e.volume = elimRs.getString(elimRs.getColumnIndex('volume'));
        e.notes = elimRs.getString(elimRs.getColumnIndex('notes'));
        elims.push(e);
      }
      elimRs.close();
      this.eliminationList = elims;

      // 4. 睡眠
      const sleepRs = await this.rdbStore.query(new relationalStore.RdbPredicates(AppConstants.TABLE_SLEEP));
      const sleeps: SleepRecord[] = [];
      while (sleepRs.goToNextRow()) {
        const s = new SleepRecord(
          sleepRs.getString(sleepRs.getColumnIndex('id')),
          sleepRs.getString(sleepRs.getColumnIndex('baby_id')),
          sleepRs.getLong(sleepRs.getColumnIndex('start_time')),
          sleepRs.getLong(sleepRs.getColumnIndex('end_time')),
          sleepRs.getLong(sleepRs.getColumnIndex('duration_minutes')),
          sleepRs.getString(sleepRs.getColumnIndex('caregiver_id'))
        );
        s.sleepType = sleepRs.getString(sleepRs.getColumnIndex('sleep_type'));
        s.notes = sleepRs.getString(sleepRs.getColumnIndex('notes'));
        sleeps.push(s);
      }
      sleepRs.close();
      this.sleepList = sleeps;

      // 5. 疫苗
      const vacRs = await this.rdbStore.query(new relationalStore.RdbPredicates(AppConstants.TABLE_VACCINE));
      const vacs: VaccineRecord[] = [];
      while (vacRs.goToNextRow()) {
        const v = new VaccineRecord(
          vacRs.getString(vacRs.getColumnIndex('id')),
          vacRs.getString(vacRs.getColumnIndex('baby_id')),
          vacRs.getString(vacRs.getColumnIndex('vaccine_name')),
          vacRs.getString(vacRs.getColumnIndex('dose')),
          vacRs.getString(vacRs.getColumnIndex('month_label'))
        );
        v.isDone = vacRs.getLong(vacRs.getColumnIndex('is_done'));
        v.vaccinatedDate = vacRs.getLong(vacRs.getColumnIndex('vaccinated_date'));
        vacs.push(v);
      }
      vacRs.close();
      if (vacs.length > 0) {
        this.vaccineList = vacs;
      }

      // 6. 生长
      const grRs = await this.rdbStore.query(new relationalStore.RdbPredicates(AppConstants.TABLE_GROWTH));
      const growths: GrowthRecord[] = [];
      while (grRs.goToNextRow()) {
        const g = new GrowthRecord(
          grRs.getString(grRs.getColumnIndex('id')),
          grRs.getString(grRs.getColumnIndex('baby_id')),
          grRs.getLong(grRs.getColumnIndex('record_date')),
          grRs.getDouble(grRs.getColumnIndex('height')),
          grRs.getDouble(grRs.getColumnIndex('weight')),
          grRs.getLong(grRs.getColumnIndex('month_age'))
        );
        g.heightStatus = grRs.getString(grRs.getColumnIndex('height_status'));
        g.weightStatus = grRs.getString(grRs.getColumnIndex('weight_status'));
        g.percentileText = grRs.getString(grRs.getColumnIndex('percentile_text'));
        growths.push(g);
      }
      grRs.close();
      this.growthList = growths;

      // 7. 花销
      const expRs = await this.rdbStore.query(new relationalStore.RdbPredicates(AppConstants.TABLE_EXPENSE));
      const expenses: ExpenseRecord[] = [];
      while (expRs.goToNextRow()) {
        const exp = new ExpenseRecord(
          expRs.getString(expRs.getColumnIndex('id')),
          expRs.getString(expRs.getColumnIndex('baby_id')),
          expRs.getLong(expRs.getColumnIndex('expense_date')),
          expRs.getString(expRs.getColumnIndex('category')),
          expRs.getDouble(expRs.getColumnIndex('amount')),
          expRs.getString(expRs.getColumnIndex('notes'))
        );
        expenses.push(exp);
      }
      expRs.close();
      this.expenseList = expenses;

      // 8. 奶粉库
      const fpRs = await this.rdbStore.query(new relationalStore.RdbPredicates(AppConstants.TABLE_FORMULA_PROFILE));
      const formulas: FormulaProfile[] = [];
      while (fpRs.goToNextRow()) {
        const fp = new FormulaProfile(
          fpRs.getString(fpRs.getColumnIndex('id')),
          fpRs.getString(fpRs.getColumnIndex('stage')),
          fpRs.getDouble(fpRs.getColumnIndex('water_per_scoop')),
          fpRs.getDouble(fpRs.getColumnIndex('default_amount')),
          fpRs.getString(fpRs.getColumnIndex('brand_name')),
          fpRs.getLong(fpRs.getColumnIndex('is_default'))
        );
        formulas.push(fp);
      }
      fpRs.close();
      if (formulas.length > 0) {
        let hasDefault = false;
        for (let i = 0; i < formulas.length; i++) {
          if (formulas[i].isDefault === 1) {
            if (!hasDefault) {
              hasDefault = true;
            } else {
              formulas[i].isDefault = 0;
            }
          }
        }
        // 用户要求：不要有默认常用！如果用户未设置常用，则保持无常用状态
        this.formulaProfiles = formulas;
      }
    } catch (err) {
      console.warn('loadAllDataFromDb error:', JSON.stringify(err));
    }
  }

  /**
   * 初始化公共参考字典数据（奶粉库预设与疫苗计划表模板，不带虚拟宝宝，不设默认常用）
   */
  private initReferenceDataInMemory(): void {
    if (this.formulaProfiles.length === 0) {
      const fp1 = new FormulaProfile('fp_1', '1段 (0-6个月)', 30, 120, '常用配方', 0);
      const fp2 = new FormulaProfile('fp_2', '早产/特殊配方', 30, 120, '特殊配方', 0);
      const fp3 = new FormulaProfile('fp_3', '3段 (1-3岁)', 30, 120, '幼儿配方', 0);
      this.formulaProfiles = [fp1, fp2, fp3];
    }

    if (this.vaccineList.length === 0) {
      this.vaccineList = VaccineRecord.PRESET_VACCINES.map((p, idx) => {
        const v = new VaccineRecord(`v_${idx}`, '', p.name, p.dose, p.monthLabel);
        v.isDone = 0;
        v.vaccinatedDate = 0;
        return v;
      });
    }
  }

  /**
   * 将公共字典数据持久化到 SQLite
   */
  private async seedReferenceDataOnly(): Promise<void> {
    this.initReferenceDataInMemory();
    if (!this.rdbStore) return;

    try {
      // 检查奶粉库是否已有数据
      const fPred = new relationalStore.RdbPredicates(AppConstants.TABLE_FORMULA_PROFILE);
      const fSet = await this.rdbStore.query(fPred);
      const fCount = fSet.rowCount;
      fSet.close();
      if (fCount <= 0) {
        for (const fp of this.formulaProfiles) {
          await this.insertFormulaToDb(fp);
        }
      }

      // 检查疫苗库是否已有数据
      const vPred = new relationalStore.RdbPredicates(AppConstants.TABLE_VACCINE);
      const vSet = await this.rdbStore.query(vPred);
      const vCount = vSet.rowCount;
      vSet.close();
      if (vCount <= 0) {
        for (const v of this.vaccineList) {
          await this.insertVaccineToDb(v);
        }
      }
    } catch (e) {
      console.warn('seedReferenceDataOnly error:', JSON.stringify(e));
    }
  }

  // --- SQLite 写入私有辅助函数 ---
  private async insertBabyToDb(b: BabyModel): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        id: b.id,
        name: b.name,
        birthday: b.birthday,
        gender: b.gender,
        birth_weight: b.birthWeight,
        birth_height: b.birthHeight,
        blood_type: b.bloodType,
        avatar: b.avatar,
        notes: b.notes,
        is_default: b.isDefault,
        created_at: b.createdAt
      };
      await this.rdbStore.insert(AppConstants.TABLE_BABY, bucket);
    } catch (e) {
      console.warn('insertBabyToDb error:', JSON.stringify(e));
    }
  }

  private async insertFeedingToDb(f: FeedingRecord): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        id: f.id,
        baby_id: f.babyId,
        record_time: f.recordTime,
        feeding_type: f.feedingType,
        amount: f.amount,
        amount_unit: f.amountUnit,
        formula_stage: f.formulaStage,
        scoops: f.scoops,
        water_amount: f.waterAmount,
        left_duration: f.leftDuration,
        right_duration: f.rightDuration,
        suck_status: f.suckStatus,
        milk_source: f.milkSource,
        solids_name: f.solidsName,
        solids_ingredients: f.solidsIngredients,
        is_new_food: f.isNewFood ? 1 : 0,
        has_allergy: f.hasAllergy ? 1 : 0,
        allergy_note: f.allergyNote,
        caregiver_id: f.caregiverId,
        notes: f.notes,
        created_at: f.createdAt
      };
      await this.rdbStore.insert(AppConstants.TABLE_FEEDING, bucket);
    } catch (e) {
      console.warn('insertFeedingToDb error:', JSON.stringify(e));
    }
  }

  private async insertEliminationToDb(e: EliminationRecord): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        id: e.id,
        baby_id: e.babyId,
        record_time: e.recordTime,
        elimination_type: e.eliminationType,
        stool_texture: e.stoolTexture,
        stool_color: e.stoolColor,
        volume: e.volume,
        is_abnormal: e.isAbnormal ? 1 : 0,
        abnormal_notes: e.abnormalNotes,
        caregiver_id: e.caregiverId,
        notes: e.notes,
        created_at: e.createdAt
      };
      await this.rdbStore.insert(AppConstants.TABLE_ELIMINATION, bucket);
    } catch (err) {
      console.warn('insertEliminationToDb error:', JSON.stringify(err));
    }
  }

  private async insertSleepToDb(s: SleepRecord): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        id: s.id,
        baby_id: s.babyId,
        start_time: s.startTime,
        end_time: s.endTime,
        duration_minutes: s.durationMinutes,
        sleep_type: s.sleepType,
        method: s.method,
        night_wake_count: s.nightWakeCount,
        caregiver_id: s.caregiverId,
        notes: s.notes,
        created_at: s.createdAt
      };
      await this.rdbStore.insert(AppConstants.TABLE_SLEEP, bucket);
    } catch (err) {
      console.warn('insertSleepToDb error:', JSON.stringify(err));
    }
  }

  private async insertVaccineToDb(v: VaccineRecord): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        id: v.id,
        baby_id: v.babyId,
        vaccine_name: v.vaccineName,
        month_label: v.monthLabel,
        dose: v.dose,
        is_done: v.isDone,
        vaccinated_date: v.vaccinatedDate,
        organization: v.organization,
        batch_number: v.batchNumber,
        is_free: v.isFree,
        adverse_reaction: v.adverseReaction,
        reminder_date: v.reminderDate,
        notes: v.notes,
        created_at: v.createdAt
      };
      await this.rdbStore.insert(AppConstants.TABLE_VACCINE, bucket);
    } catch (err) {
      console.warn('insertVaccineToDb error:', JSON.stringify(err));
    }
  }

  private async insertGrowthToDb(g: GrowthRecord): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        id: g.id,
        baby_id: g.babyId,
        record_date: g.recordDate,
        month_age: g.monthAge,
        height: g.height,
        weight: g.weight,
        head_circumference: g.headCircumference,
        height_status: g.heightStatus,
        weight_status: g.weightStatus,
        percentile_text: g.percentileText,
        measure_location: g.measureLocation,
        caregiver_id: g.caregiverId,
        notes: g.notes,
        created_at: g.createdAt
      };
      await this.rdbStore.insert(AppConstants.TABLE_GROWTH, bucket);
    } catch (err) {
      console.warn('insertGrowthToDb error:', JSON.stringify(err));
    }
  }

  private async insertExpenseToDb(exp: ExpenseRecord): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        id: exp.id,
        baby_id: exp.babyId,
        expense_date: exp.expenseDate,
        category: exp.category,
        amount: exp.amount,
        notes: exp.notes,
        created_at: exp.createdAt
      };
      await this.rdbStore.insert(AppConstants.TABLE_EXPENSE, bucket);
    } catch (err) {
      console.warn('insertExpenseToDb error:', JSON.stringify(err));
    }
  }

  private async insertFormulaToDb(fp: FormulaProfile): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        id: fp.id,
        stage: fp.stage,
        water_per_scoop: fp.waterPerScoop,
        default_amount: fp.defaultAmount,
        brand_name: fp.brandName,
        is_default: fp.isDefault
      };
      await this.rdbStore.insert(AppConstants.TABLE_FORMULA_PROFILE, bucket);
    } catch (err) {
      console.warn('insertFormulaToDb error:', JSON.stringify(err));
    }
  }

  // --- 宝宝档案 CRUD 与用户系统极速缓存 ---
  /**
   * 判断是否存在用户数据（用于应用启动分流）
   */
  hasUserData(): boolean {
    if (this.isUserOnboarded && this.babyList.length > 0 && !!this.babyList[0].name.trim()) {
      return true;
    }
    if (this.cachedBaby && !!this.cachedBaby.name.trim()) {
      return true;
    }
    return false;
  }

  /**
   * 持久化缓存宝宝数据到 Preferences 与 AppStorage
   */
  cacheBabyProfile(baby: BabyModel): void {
    this.cachedBaby = baby;
    const jsonStr = JSON.stringify(baby);
    AppStorage.setOrCreate('CACHE_BABY_INFO', jsonStr);
    AppStorage.setOrCreate('HAS_USER_DATA', true);
    if (this.pref) {
      try {
        this.pref.putSync('HAS_USER_DATA', true);
        this.pref.putSync('CACHED_BABY_INFO', jsonStr);
        this.pref.flush();
      } catch (e) {
        console.warn('cacheBabyProfile pref error:', JSON.stringify(e));
      }
    }
  }

  /**
   * 获取极速缓存的宝宝对象（主页秒开专用）
   */
  getCachedBaby(): BabyModel | null {
    if (this.cachedBaby && !!this.cachedBaby.name.trim()) {
      return this.cachedBaby;
    }
    if (this.babyList.length > 0 && !!this.babyList[0].name.trim()) {
      return this.babyList[0];
    }
    return null;
  }

  getBabies(): BabyModel[] {
    if (this.babyList.length === 0 && this.cachedBaby && !!this.cachedBaby.name.trim()) {
      return [this.cachedBaby];
    }
    return this.babyList;
  }

  getCurrentBaby(): BabyModel {
    if (this.cachedBaby && !!this.cachedBaby.name.trim()) {
      return this.cachedBaby;
    }
    const found = this.babyList.find(b => b.id === this.currentBabyId);
    if (found) {
      return found;
    }
    if (this.babyList.length > 0) {
      return this.babyList[0];
    }
    // 兜底返回空对象，无虚拟假数据
    return new BabyModel('', '', 0, 'boy', 0, 0, '未知', '👶', '', 1, Date.now());
  }

  setCurrentBabyId(id: string): void {
    this.currentBabyId = id;
  }

  addBaby(baby: BabyModel): void {
    if (!baby.id) {
      baby.id = `baby_${Date.now()}`;
    }
    baby.isDefault = 1;
    this.babyList = [baby];
    this.currentBabyId = baby.id;
    this.isUserOnboarded = true;
    this.cacheBabyProfile(baby);
    this.insertBabyToDb(baby);
  }

  updateBaby(baby: BabyModel): void {
    if (!baby.id) {
      baby.id = this.currentBabyId || `baby_${Date.now()}`;
    }
    const idx = this.babyList.findIndex(b => b.id === baby.id);
    if (idx !== -1) {
      this.babyList[idx] = baby;
    } else {
      this.babyList.unshift(baby);
    }
    this.currentBabyId = baby.id;
    this.isUserOnboarded = true;
    this.cacheBabyProfile(baby);
    if (this.rdbStore) {
      try {
        const pred = new relationalStore.RdbPredicates(AppConstants.TABLE_BABY);
        pred.equalTo('id', baby.id);
        const bucket: relationalStore.ValuesBucket = {
          name: baby.name,
          gender: baby.gender,
          birthday: baby.birthday,
          birth_weight: baby.birthWeight,
          birth_height: baby.birthHeight,
          blood_type: baby.bloodType,
          avatar: baby.avatar,
          notes: baby.notes
        };
        this.rdbStore.update(bucket, pred);
      } catch (err) {
        console.warn('updateBaby error:', JSON.stringify(err));
      }
    }
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
    this.insertFeedingToDb(record);
  }

  deleteFeedingRecord(id: string): void {
    this.feedingList = this.feedingList.filter(r => r.id !== id);
    if (this.rdbStore) {
      try {
        this.rdbStore.executeSql(`DELETE FROM ${AppConstants.TABLE_FEEDING} WHERE id = '${id}'`);
      } catch (e) {
        console.warn('deleteFeedingRecord error:', JSON.stringify(e));
      }
    }
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
    this.insertEliminationToDb(record);
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
    this.insertSleepToDb(record);
  }

  // --- 疫苗记录 CRUD ---
  getVaccineRecords(babyId?: string): VaccineRecord[] {
    const targetId = babyId || this.currentBabyId;
    return this.vaccineList.filter(r => r.babyId === targetId);
  }

  updateVaccineStatus(id: string, isDone: number, date?: number): void {
    const item = this.vaccineList.find(v => v.id === id);
    if (item) {
      item.isDone = isDone;
      if (date) item.vaccinatedDate = date;
      if (this.rdbStore) {
        try {
          const pred = new relationalStore.RdbPredicates(AppConstants.TABLE_VACCINE);
          pred.equalTo('id', id);
          const bucket: relationalStore.ValuesBucket = {
            is_done: isDone,
            vaccinated_date: item.vaccinatedDate
          };
          this.rdbStore.update(bucket, pred);
        } catch (e) {
          console.warn('updateVaccineStatus error:', JSON.stringify(e));
        }
      }
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
    this.insertGrowthToDb(record);
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
    this.insertExpenseToDb(expense);
  }

  // --- 奶粉库 CRUD ---
  getFormulaProfiles(): FormulaProfile[] {
    return this.formulaProfiles.map((f: FormulaProfile) => new FormulaProfile(
      f.id,
      f.stage,
      f.waterPerScoop,
      f.defaultAmount,
      f.brandName,
      f.isDefault
    ));
  }

  addFormulaProfile(profile: FormulaProfile): void {
    if (profile.isDefault === 1) {
      this.formulaProfiles.forEach(f => {
        f.isDefault = 0;
      });
      if (this.rdbStore) {
        try {
          this.rdbStore.executeSql(`UPDATE ${AppConstants.TABLE_FORMULA_PROFILE} SET is_default = 0`);
        } catch (e) {}
      }
    }
    this.formulaProfiles.push(profile);
    this.insertFormulaToDb(profile);
  }

  /**
   * 设置唯一常用奶粉（互斥：只能设置一个为常用）
   */
  setDefaultFormula(formulaId: string): void {
    this.formulaProfiles = this.formulaProfiles.map((f: FormulaProfile) => {
      return new FormulaProfile(
        f.id,
        f.stage,
        f.waterPerScoop,
        f.defaultAmount,
        f.brandName,
        f.id === formulaId ? 1 : 0
      );
    });
    if (this.rdbStore) {
      try {
        this.rdbStore.executeSql(`UPDATE ${AppConstants.TABLE_FORMULA_PROFILE} SET is_default = 0`);
        this.rdbStore.executeSql(`UPDATE ${AppConstants.TABLE_FORMULA_PROFILE} SET is_default = 1 WHERE id = '${formulaId}'`);
      } catch (e) {
        console.warn('setDefaultFormula error:', JSON.stringify(e));
      }
    }
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

  /**
   * 清除所有本地记录数据（不可恢复，重置无默认常用）
   */
  clearAllData(): void {
    this.babyList = [];
    this.currentBabyId = '';
    this.isUserOnboarded = false;
    this.cachedBaby = null;
    this.feedingList = [];
    this.eliminationList = [];
    this.sleepList = [];
    this.growthList = [];
    this.expenseList = [];

    // 重置所有奶粉常用标记为 0（无默认常用）
    this.formulaProfiles.forEach(f => {
      f.isDefault = 0;
    });

    AppStorage.setOrCreate('CACHE_BABY_INFO', '');
    AppStorage.setOrCreate('HAS_USER_DATA', false);
    AppStorage.setOrCreate('APP_REFRESH_TRIGGER', Date.now());

    if (this.pref) {
      try {
        this.pref.clearSync();
        this.pref.flush();
      } catch (e) {}
    }

    if (this.rdbStore) {
      try {
        this.rdbStore.executeSql(`DELETE FROM ${AppConstants.TABLE_BABY}`);
        this.rdbStore.executeSql(`DELETE FROM ${AppConstants.TABLE_FEEDING}`);
        this.rdbStore.executeSql(`DELETE FROM ${AppConstants.TABLE_ELIMINATION}`);
        this.rdbStore.executeSql(`DELETE FROM ${AppConstants.TABLE_SLEEP}`);
        this.rdbStore.executeSql(`DELETE FROM ${AppConstants.TABLE_VACCINE}`);
        this.rdbStore.executeSql(`DELETE FROM ${AppConstants.TABLE_GROWTH}`);
        this.rdbStore.executeSql(`DELETE FROM ${AppConstants.TABLE_EXPENSE}`);
        this.rdbStore.executeSql(`UPDATE ${AppConstants.TABLE_FORMULA_PROFILE} SET is_default = 0`);
      } catch (err) {
        console.warn('clearAllData sql error:', JSON.stringify(err));
      }
    }
  }
}
