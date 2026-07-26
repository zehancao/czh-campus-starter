export class Theme {
  // ═══ 主色系 ═══ 暖橙
  static readonly primary: string = '#FF8C42';
  static readonly primaryLight: string = '#FFF4E6';
  static readonly primaryDark: string = '#FF6B2C';

  // ═══ 次色系 ═══ 海洋蓝
  static readonly secondary: string = '#06AED5';
  static readonly secondaryLight: string = '#E0F7FF';
  static readonly secondaryDark: string = '#0288D1';

  // ═══ 语义色 ═══
  static readonly success: string = '#22C55E';
  static readonly successLight: string = '#E6F9F0';
  static readonly warning: string = '#F59E0B';
  static readonly warningLight: string = '#FFF9E6';
  static readonly danger: string = '#EF4444';
  static readonly dangerLight: string = '#FEE2E2';
  static readonly info: string = '#06AED5';

  // ═══ 文字色 ═══
  static readonly textPrimary: string = '#2D2A26';
  static readonly textSecondary: string = '#6B6660';
  static readonly textTertiary: string = '#A8A39D';
  static readonly textDisabled: string = '#C4BFBA';
  static readonly textWhite: string = '#FFFFFF';

  // ═══ 背景色 ═══
  // 阳光校园：奶油白底衬纯白卡片
  static readonly bgPage: string = '#FFFBF5';
  static readonly bgCard: string = '#FFFFFF';
  static readonly bgInput: string = '#FFF4E6';
  static readonly bgHover: string = '#FFE8CC';

  // ═══ 边框/分割线 ═══
  static readonly border: string = '#FFE0CC';
  static readonly divider: string = '#FFCBA4';

  // ═══ 新拟态专用（暖色系） ═══
  static readonly nmLight: string = '#FFFFFF';
  static readonly nmDark: string = '#E0CCBE';
  static readonly nmAccent: string = '#FF8C42';
  // 高光侧色（左上）
  static readonly nmHighlight: string = '#FFFFFF';
  // 暗影侧色（右下）
  static readonly nmShadow: string = '#C4A88C';

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

  // ═══ 圆角（对齐 Sunshine Campus 设计规范） ═══
  // 规范: sm=8px, md=12px, lg=16px, xl=24px, pill=50vp(胶囊)
  static readonly radiusSm: number = 8;      // 标签/小按钮/输入框内部
  static readonly radiusMd: number = 12;     // 图片占位/小卡片
  static readonly radiusLg: number = 16;     // 标准卡片（最常用）
  static readonly radiusXl: number = 24;     // 大色块/头部面板/弹窗
  static readonly radiusPill: number = 50;   // 胶囊按钮/头像/全圆标签

  // 别名 —— 代码中统一使用这些语义名
  static readonly cardRadius: number = Theme.radiusLg;    // 标准卡片=16
  static readonly heroRadius: number = Theme.radiusXl;    // 头部大块=24
  static readonly chipRadius: number = Theme.radiusSm;    // 标签=8

  // ═══ 海洋蓝快捷别名 ═══
  static readonly ocean: string = Theme.secondary;           // #06AED5
  static readonly oceanLight: string = Theme.secondaryLight;  // #E0F7FF
  static readonly oceanDark: string = Theme.secondaryDark;    // #0288D1

  // ═══ 间距 ═══
  static readonly cardPadding: number = 16;
  static readonly cardMarginBottom: number = 10;
  static readonly sectionGap: number = 12;
  static readonly inputHeight: number = 46;
  static readonly buttonHeight: number = 44;

  // ═══ 按钮规范（对齐设计系统） ═══
  // 主按钮：渐变暖橙底 + 白色字 + 暖色阴影，胶囊形(radiusPill)
  // 线框按钮：透明底 + 暖橙边框 + 暖橙字，胶囊形(radiusPill)
  // 幽灵按钮：透明底 + 次要文字色，胶囊形(radiusPill)
  static readonly buttonHeightSm: number = 32;   // 小按钮
  static readonly buttonHeightMd: number = 44;   // 标准按钮（同 buttonHeight）
  static readonly buttonHeightLg: number = 52;   // 大按钮
  static readonly buttonRadius: number = Theme.radiusPill;  // 按钮默认胶囊形

  // 按钮渐变（ArkTS linearGradient colors 数组）
  static readonly btnGradientSunrise: [string, number][] = [['#FF8C42', 0], ['#FF6B2C', 1]];
  static readonly btnGradientOcean: [string, number][] = [['#06AED5', 0], ['#0288D1', 1]];
  static readonly btnGradientDirection: number = 135;  // 左上→右下

  // ═══ 课表/个人卡片配色 ═══
  static readonly scheduleCardBg: string[] = ['#FFF4E6', '#E0F7FF', '#FFF9E6', '#FEE2E2', '#FCE7F3', '#F3E8FF'];
  static readonly scheduleCardFg: string[] = ['#FF8C42', '#0288D1', '#D97706', '#EF4444', '#DB2777', '#7C3AED'];
  static readonly personalCardBg: string[] = ['#FFF4E6', '#E0F7FF', '#FEE2E2', '#FCE7F3'];
  static readonly personalCardFg: string[] = ['#FF8C42', '#0288D1', '#EF4444', '#DB2777'];
}

export class ShadowStyle {
  // 轻阴影（对齐 Sunshine Campus 设计规范）
  // 规范: sm=0 1px 2px rgba(0,0,0,0.04), md=0 2px 8px rgba(0,0,0,0.06), lg=0 4px 16px rgba(0,0,0,0.08)
  static readonly sm: ShadowOptions = { radius: 6, color: '#0000000A', offsetX: 0, offsetY: 2 };
  static readonly md: ShadowOptions = { radius: 12, color: '#0000000F', offsetX: 0, offsetY: 3 };
  static readonly lg: ShadowOptions = { radius: 20, color: '#00000014', offsetX: 0, offsetY: 6 };

  // 主按钮专属阴影：暖橙色 0 3px 12px rgba(255,140,66,0.25)
  static readonly primary: ShadowOptions = { radius: 14, color: '#FF8C4240', offsetX: 0, offsetY: 4 };

  // 次按钮专属阴影：海洋蓝 0 3px 12px rgba(6,174,213,0.25)
  static readonly secondary: ShadowOptions = { radius: 14, color: '#06AED540', offsetX: 0, offsetY: 4 };

  // 兼容旧新拟态引用（弱化为轻阴影，不影响已引用页面）
  static readonly nmRaised: ShadowOptions = { radius: 12, color: '#0000000F', offsetX: 0, offsetY: 3 };
  static readonly nmRaisedLg: ShadowOptions = { radius: 20, color: '#00000014', offsetX: 0, offsetY: 6 };
  static readonly nmPressed: ShadowOptions = { radius: 4, color: '#00000008', offsetX: 0, offsetY: 1 };
}
