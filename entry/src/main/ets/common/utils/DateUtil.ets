/**
 * 日期与时间工具类
 */
export class DateUtil {
  /**
   * 格式化时间：14:35
   */
  static formatTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '--:--';
    }
    const d = new Date(timestamp);
    const h = d.getHours().toString().padStart(2, '0');
    const m = d.getMinutes().toString().padStart(2, '0');
    return `${h}:${m}`;
  }

  /**
   * 格式化完整日期：2026年9月8日
   */
  static formatDate(timestamp: number): string {
    if (timestamp <= 0) {
      return '';
    }
    const d = new Date(timestamp);
    const y = d.getFullYear();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return `${y}年${m}月${day}日`;
  }

  /**
   * 格式化日期与时间：9月8日 14:35
   */
  static formatMonthDateTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '';
    }
    const d = new Date(timestamp);
    const m = d.getMonth() + 1;
    const day = d.getDate();
    const h = d.getHours().toString().padStart(2, '0');
    const min = d.getMinutes().toString().padStart(2, '0');
    return `${m}月${day}日 ${h}:${min}`;
  }

  /**
   * 计算与上次事件的间隔时长（例如：2小时15分钟前）
   */
  static getElapsedTimeDesc(pastTimestamp: number): string {
    if (pastTimestamp <= 0) {
      return '暂无记录';
    }
    const diffMs = Math.max(0, Date.now() - pastTimestamp);
    const diffMins = Math.floor(diffMs / (1000 * 60));

    if (diffMins < 1) {
      return '刚刚';
    }
    if (diffMins < 60) {
      return `${diffMins}分钟前`;
    }
    const hours = Math.floor(diffMins / 60);
    const mins = diffMins % 60;
    if (mins === 0) {
      return `${hours}小时前`;
    }
    return `${hours}小时${mins}分前`;
  }

  /**
   * 获取今日 00:00:00 时间戳
   */
  static getTodayStart(): number {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).getTime();
  }

  /**
   * 获取今日 23:59:59 时间戳
   */
  static getTodayEnd(): number {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999).getTime();
  }

  /**
   * 判断两个时间戳是否为同一自然天
   */
  static isSameDay(t1: number, t2: number): boolean {
    const d1 = new Date(t1);
    const d2 = new Date(t2);
    return d1.getFullYear() === d2.getFullYear() &&
           d1.getMonth() === d2.getMonth() &&
           d1.getDate() === d2.getDate();
  }
}
