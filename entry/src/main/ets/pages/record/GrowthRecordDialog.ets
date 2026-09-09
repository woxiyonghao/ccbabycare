import { AppConstants } from '../../common/constants/AppConstants';
import { GrowthRecord } from '../../common/models/GrowthRecord';
import { DatabaseHelper } from '../../common/database/DatabaseHelper';
import { GrowthEvaluator, EvaluationResult } from '../../common/utils/GrowthEvaluator';

import promptAction from '@ohos.promptAction';

/**
 * 成长体检记录弹窗（结合2026儿童生长发育标准实时比对，图三规则）
 */
@CustomDialog
export struct GrowthRecordDialog {
  controller: CustomDialogController;
  onSuccess?: () => void;

  @State heightStr: string = '';
  @State weightStr: string = '';
  @State headCircStr: string = '';
  @State evaluationSummary: string = '请输入身高与体重，系统将实时比对2026标准';
  @State isNormal: boolean = true;
  @State location: string = '家庭测量';
  @State notes: string = '';

  aboutToAppear() {
    this.updateEvaluation();
  }

  /**
   * 过滤并净化输入的数字（禁止负号、非数字，规范小数点与前导零）
   */
  private sanitizeNumber(val: string): string {
    if (!val) return '';
    let clean = val.replace(/[^0-9.]/g, '');
    if (clean.startsWith('.')) {
      clean = '0' + clean;
    }
    const dotIndex = clean.indexOf('.');
    if (dotIndex !== -1) {
      const intPart = clean.substring(0, dotIndex);
      const decPart = clean.substring(dotIndex + 1).replace(/\./g, '');
      clean = intPart + '.' + decPart.substring(0, 2);
    }
    if (clean.length > 1 && clean.startsWith('0') && !clean.startsWith('0.')) {
      clean = clean.replace(/^0+/, '');
      if (clean === '') clean = '0';
    }
    return clean;
  }

  private updateEvaluation() {
    const db = DatabaseHelper.getInstance();
    const baby = db.getCurrentBaby();
    const h = parseFloat(this.heightStr);
    const w = parseFloat(this.weightStr);
    const monthAge = baby.getTotalMonthAge();

    if (!this.heightStr || !this.weightStr || isNaN(h) || isNaN(w) || h <= 0 || w <= 0) {
      this.evaluationSummary = '请输入身高与体重，系统将实时比对2026标准';
      this.isNormal = true;
      return;
    }

    const result: EvaluationResult = GrowthEvaluator.evaluate(baby.gender, monthAge, h, w);
    this.evaluationSummary = result.summaryText;
    this.isNormal = result.isAllNormal;
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Text('📈 记录成长 (2026儿童标准对照)')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
        Blank()
        Text('✕')
          .fontSize(20)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
          .onClick(() => this.controller.close())
      }
      .width('100%')

      // 2026 实时比对反馈提示卡片
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(this.isNormal ? '✅ 2026标准比对结果：' : '⚠️ 2026标准提示：')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isNormal ? '#03543F' : '#9B1C1C')
        }
        Text(this.evaluationSummary)
          .fontSize(12)
          .fontColor(this.isNormal ? '#046C4E' : '#C81E1E')
          .lineHeight(16)
      }
      .width('100%')
      .padding(10)
      .backgroundColor(this.isNormal ? '#DEF7EC' : '#FDE8E8')
      .borderRadius(12)

      // 输入项
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('身高 (cm)')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          TextInput({ text: this.heightStr })
            .type(InputType.NUMBER_DECIMAL)
            .inputFilter('[0-9.]')
            .onChange((v: string) => {
              this.heightStr = this.sanitizeNumber(v);
              this.updateEvaluation();
            })
        }
        .layoutWeight(1)

        Column({ space: 4 }) {
          Text('体重 (kg)')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          TextInput({ text: this.weightStr })
            .type(InputType.NUMBER_DECIMAL)
            .inputFilter('[0-9.]')
            .onChange((v: string) => {
              this.weightStr = this.sanitizeNumber(v);
              this.updateEvaluation();
            })
        }
        .layoutWeight(1)

        Column({ space: 4 }) {
          Text('头围 (cm)')
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_MUTED)
          TextInput({ text: this.headCircStr })
            .type(InputType.NUMBER_DECIMAL)
            .inputFilter('[0-9.]')
            .onChange((v: string) => {
              this.headCircStr = this.sanitizeNumber(v);
            })
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 测量地点
      Row({ space: 8 }) {
        Text('地点：')
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_MUTED)
        Text('家庭测量')
          .fontSize(12)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.location === '家庭测量' ? AppConstants.COLOR_PRIMARY_LIGHT : '#F3F4F6')
          .borderRadius(8)
          .onClick(() => { this.location = '家庭测量'; })
        Text('社区体检')
          .fontSize(12)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.location === '社区体检' ? AppConstants.COLOR_PRIMARY_LIGHT : '#F3F4F6')
          .borderRadius(8)
          .onClick(() => { this.location = '社区体检'; })
        Text('医院体检')
          .fontSize(12)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.location === '医院体检' ? AppConstants.COLOR_PRIMARY_LIGHT : '#F3F4F6')
          .borderRadius(8)
          .onClick(() => { this.location = '医院体检'; })
      }

      TextInput({ placeholder: '体检医生建议或备注...', text: this.notes })
        .fontSize(13)
        .onChange((v: string) => { this.notes = v; })

      Button('保存成长体检数据')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(AppConstants.COLOR_PRIMARY)
        .onClick(() => {
          const h = parseFloat(this.heightStr);
          const w = parseFloat(this.weightStr);
          if (!this.heightStr || !this.weightStr || isNaN(h) || isNaN(w) || h <= 0 || w <= 0) {
            try {
              promptAction.showToast({ message: '请输入有效的身长与体重数值' });
            } catch (e) {}
            return;
          }

          const db = DatabaseHelper.getInstance();
          const baby = db.getCurrentBaby();
          const head = parseFloat(this.headCircStr) || 0;
          const monthAge = baby.getTotalMonthAge();

          const evalRes = GrowthEvaluator.evaluate(baby.gender, monthAge, h, w);

          const rec = new GrowthRecord();
          rec.id = 'growth_' + Date.now();
          rec.babyId = baby.id;
          rec.recordDate = Date.now();
          rec.monthAge = monthAge;
          rec.height = h;
          rec.weight = w;
          rec.headCircumference = head;
          rec.heightStatus = evalRes.heightStatus;
          rec.weightStatus = evalRes.weightStatus;
          rec.percentileText = evalRes.summaryText;
          rec.measureLocation = this.location;
          rec.notes = this.notes;

          db.addGrowthRecord(rec);
          if (this.onSuccess) {
            this.onSuccess();
          }
          this.controller.close();
        })
    }
    .padding(20)
    .backgroundColor(AppConstants.COLOR_CARD_BG)
    .borderRadius(20)
    .width('92%')
  }
}
