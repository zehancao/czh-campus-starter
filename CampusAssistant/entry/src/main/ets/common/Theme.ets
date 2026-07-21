export class Theme {
  // ═══ 主色系 ═══
  static readonly primary: string = '#4F46E5';
  static readonly primaryLight: string = '#EEF2FF';
  static readonly primaryDark: string = '#3730A3';

  // ═══ 次色系 ═══
  static readonly secondary: string = '#F97316';
  static readonly secondaryLight: string = '#FFF7ED';
  static readonly secondaryDark: string = '#EA580C';

  // ═══ 语义色 ═══
  static readonly success: string = '#10B981';
  static readonly successLight: string = '#ECFDF5';
  static readonly warning: string = '#F59E0B';
  static readonly warningLight: string = '#FEF3C7';
  static readonly danger: string = '#EF4444';
  static readonly dangerLight: string = '#FEF2F2';
  static readonly info: string = '#0EA5E9';

  // ═══ 文字色 ═══
  static readonly textPrimary: string = '#4A5568';
  static readonly textSecondary: string = '#8E99A8';
  static readonly textTertiary: string = '#B0B7C3';
  static readonly textDisabled: string = '#CBD0D8';
  static readonly textWhite: string = '#FFFFFF';

  // ═══ 背景色 ═══
  // 新拟态：背景柔和灰白，托盘衬出纯白卡片的立体感
  static readonly bgPage: string = '#F0F3F6';
  static readonly bgCard: string = '#FFFFFF';
  static readonly bgInput: string = '#F4F5F7';
  static readonly bgHover: string = '#F0F1F3';

  // ═══ 边框/分割线 ═══
  static readonly border: string = '#C8CFDA';
  static readonly divider: string = '#D6DBE3';

  // ═══ 新拟态专用 ═══
  static readonly nmLight: string = '#FFFFFF';
  static readonly nmDark: string = '#A3B1C6';
  static readonly nmAccent: string = '#6B7FA3';
  // 高光侧色（左上）
  static readonly nmHighlight: string = '#FFFFFF';
  // 暗影侧色（右下）
  static readonly nmShadow: string = '#8B9BB4';

  // ═══ 字号阶梯（新增） ═══
  static readonly fsDisplay: number = 22;   // 大标题/首页问候
  static readonly fsTitle: number = 18;      // 页面标题
  static readonly fsSubtitle: number = 16;   // 区块标题
  static readonly fsBody: number = 15;       // 正文
  static readonly fsCaption: number = 13;    // 辅助说明
  static readonly fsSmall: number = 11;      // 极小文字/角标

  // ═══ 导航 ═══
  static readonly navHeight: number = 56;
  static readonly navBackSize: number = 24;
  static readonly navTitleSize: number = 18;

  // ═══ 圆角（语义别名） ═══
  static readonly radiusSm: number = 14;     // 标签/小元素
  static readonly radiusMd: number = 24;     // 卡片默认
  static readonly radiusLg: number = 32;     // 大卡/头图
  static readonly radiusPill: number = 30;   // 胶囊按钮

  // 别名 —— 代码中统一使用这些语义名
  static readonly cardRadius: number = Theme.radiusMd;
  static readonly heroRadius: number = Theme.radiusLg;
  static readonly chipRadius: number = Theme.radiusSm;

  // ═══ 间距 ═══
  static readonly cardPadding: number = 16;
  static readonly cardMarginBottom: number = 10;
  static readonly sectionGap: number = 12;
  static readonly inputHeight: number = 46;
  static readonly buttonHeight: number = 44;

  // ═══ 课表/个人卡片配色 ═══
  static readonly scheduleCardBg: string[] = ['#EEF2FF', '#CCFBF1', '#FEF3C7', '#FFE4E6', '#FCE7F3', '#F3E8FF'];
  static readonly scheduleCardFg: string[] = ['#4F46E5', '#059669', '#D97706', '#E11D48', '#DB2777', '#7C3AED'];
  static readonly personalCardBg: string[] = ['#FFF7ED', '#FEF3C7', '#FFE4E6', '#FCE7F3'];
  static readonly personalCardFg: string[] = ['#EA580C', '#D97706', '#E11D48', '#DB2777'];
}

export class ShadowStyle {
  // 新拟态凸起阴影（快捷入口等小卡片）
  static readonly nmRaised: ShadowOptions = { radius: 12, color: '#A3B1C690', offsetX: 0, offsetY: 4 };
  // 新拟态凸起阴影（大卡片 / 面板）
  static readonly nmRaisedLg: ShadowOptions = { radius: 20, color: '#A3B1C6A0', offsetX: 0, offsetY: 6 };
  // 新拟态按压阴影：更小更深的暗影，模拟按下
  static readonly nmPressed: ShadowOptions = { radius: 4, color: '#8B9BB480', offsetX: 0, offsetY: 2 };
  // 轻微阴影：用于小元素
  static readonly sm: ShadowOptions = { radius: 8, color: '#A3B1C660', offsetX: 0, offsetY: 3 };
  // 中阴影
  static readonly md: ShadowOptions = { radius: 14, color: '#A3B1C680', offsetX: 0, offsetY: 4 };
  // 大阴影
  static readonly lg: ShadowOptions = { radius: 22, color: '#8B9BB490', offsetX: 0, offsetY: 6 };
}
