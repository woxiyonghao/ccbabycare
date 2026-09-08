/**
 * 照护者角色定义（参考图二手绘日记本角色交接体系）
 */

export interface CaregiverItem {
  id: string;
  name: string;
  avatarIcon: string;
  tagColor: string;
}

export class CaregiverConstants {
  static readonly ROLE_MOM: string = 'MOM';
  static readonly ROLE_DAD: string = 'DAD';
  static readonly ROLE_GRANDPARENT: string = 'GRANDPARENT';
  static readonly ROLE_NANNY: string = 'NANNY';

  static readonly DEFAULT_ROLES: CaregiverItem[] = [
    { id: 'MOM', name: '妈妈', avatarIcon: '👩', tagColor: '#FF7B54' },
    { id: 'DAD', name: '爸爸', avatarIcon: '👨', tagColor: '#4299E1' },
    { id: 'GRANDPARENT', name: '家中老人', avatarIcon: '👵', tagColor: '#9376E0' },
    { id: 'NANNY', name: '保姆阿姨', avatarIcon: '👩‍🍼', tagColor: '#48BB78' }
  ];

  static getRoleName(id: string): string {
    const found = CaregiverConstants.DEFAULT_ROLES.find(item => item.id === id);
    return found ? found.name : '照护者';
  }

  static getRoleIcon(id: string): string {
    const found = CaregiverConstants.DEFAULT_ROLES.find(item => item.id === id);
    return found ? found.avatarIcon : '👶';
  }
}
