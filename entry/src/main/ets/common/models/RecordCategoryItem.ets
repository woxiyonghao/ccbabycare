export interface RecordCategoryItem {
  key: string;
  icon: string;
  title: string;
  desc: string;
  bgColor: string;
  badgeColor?: string;
}

export const ALL_RECORD_CATEGORIES: RecordCategoryItem[] = [
  { key: 'feeding', icon: '🍼', title: '喂养记录', desc: '配方奶/母乳/辅食', bgColor: '#FFF5F2', badgeColor: '#FF6B6B' },
  { key: 'elimination', icon: '💩', title: '排便排尿', desc: '性状颜色/异常标记', bgColor: '#E6FFFA', badgeColor: '#319795' },
  { key: 'sleep', icon: '🌙', title: '睡眠记录', desc: '小睡/夜长觉/夜醒', bgColor: '#FAF5FF', badgeColor: '#805AD5' },
  { key: 'growth', icon: '📈', title: '成长体检', desc: '发育评估实时比对', bgColor: '#EBF8FF', badgeColor: '#3182CE' },
  { key: 'vaccine', icon: '💉', title: '疫苗档案', desc: '国家免费一类/二类自费', bgColor: '#F0FFF4', badgeColor: '#38A169' },
  { key: 'expense', icon: '💰', title: '养娃账本', desc: '日常开销记账统计', bgColor: '#FFFBF0', badgeColor: '#D69E2E' },
  { key: 'routine', icon: '⏰', title: '规律作息', desc: '吃玩睡节律作息安排', bgColor: '#FDF2F8', badgeColor: '#D53F8C' },
  { key: 'message', icon: '💌', title: '父母寄语', desc: '成长爱心便签与温情寄语', bgColor: '#FFF7ED', badgeColor: '#DD6B20' }
];

export const DEFAULT_CATEGORY_KEYS: string[] = [
  'feeding',
  'elimination',
  'sleep',
  'growth',
  'vaccine',
  'expense',
  'routine',
  'message'
];

export function getCategoryByKey(key: string): RecordCategoryItem {
  for (let i = 0; i < ALL_RECORD_CATEGORIES.length; i++) {
    if (ALL_RECORD_CATEGORIES[i].key === key) {
      return ALL_RECORD_CATEGORIES[i];
    }
  }
  return ALL_RECORD_CATEGORIES[0];
}
