export class Constants {
  static readonly APP_NAME: string = '智能校园助手';
  static readonly GRADE_OPTIONS: string[] = ['2023', '2024', '2025', '2026'];
  static readonly SCHEDULE_COLORS: string[] = [
    '#4A90D9', '#50C878', '#FF6B6B', '#FFB347', '#9B59B6',
    '#1ABC9C', '#E74C3C', '#3498DB', '#F39C12', '#2ECC71'
  ];
  static readonly SECTION_TIMES: string[][] = [
    ['08:30', '09:15'],
    ['09:20', '10:05'],
    ['10:25', '11:10'],
    ['11:15', '12:00'],
    ['14:30', '15:15'],
    ['15:20', '16:05'],
    ['16:25', '17:10'],
    ['17:15', '18:00'],
    ['19:30', '20:15'],
    ['20:20', '21:05']
  ];
  static readonly CAMPUS_LOCATIONS: string[] = ['1教', '2教', '3教', '4教', '5教', '食堂', '图书馆', '宿舍区'];
  static readonly CONDITION_OPTIONS: string[] = ['全新', '几乎全新', '轻微使用痕迹', '明显使用痕迹', '成色一般'];
  static readonly ANNOUNCEMENT_CATEGORIES: string[] = ['全部', '教务', '学工', '社团', '后勤', '紧急'];
  static readonly HOMETOWN_OPTIONS: string[] = [
    '北京', '天津', '上海', '重庆',
    '河北', '山西', '辽宁', '吉林', '黑龙江',
    '江苏', '浙江', '安徽', '福建', '江西', '山东',
    '河南', '湖北', '湖南', '广东', '海南',
    '四川', '贵州', '云南', '陕西',
    '甘肃', '青海', '台湾',
    '内蒙古自治区', '广西壮族自治区', '西藏自治区', '宁夏回族自治区', '新疆维吾尔自治区'
  ];
}