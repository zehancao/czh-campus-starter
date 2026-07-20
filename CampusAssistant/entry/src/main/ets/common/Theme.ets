export class Theme {
  static readonly primary: string = '#4F46E5';
  static readonly primaryLight: string = '#EEF2FF';
  static readonly primaryDark: string = '#3730A3';

  static readonly secondary: string = '#F97316';
  static readonly secondaryLight: string = '#FFF7ED';
  static readonly secondaryDark: string = '#EA580C';

  static readonly success: string = '#10B981';
  static readonly successLight: string = '#ECFDF5';
  static readonly warning: string = '#F59E0B';
  static readonly warningLight: string = '#FEF3C7';
  static readonly danger: string = '#EF4444';
  static readonly dangerLight: string = '#FEF2F2';
  static readonly info: string = '#0EA5E9';

  static readonly textPrimary: string = '#1F2937';
  static readonly textSecondary: string = '#6B7280';
  static readonly textTertiary: string = '#9CA3AF';
  static readonly textDisabled: string = '#D1D5DB';
  static readonly textWhite: string = '#FFFFFF';

  static readonly bgPage: string = '#F3F4F6';
  static readonly bgCard: string = '#FFFFFF';
  static readonly bgInput: string = '#F9FAFB';
  static readonly bgHover: string = '#F3F4F6';

  static readonly border: string = '#E5E7EB';
  static readonly divider: string = '#F3F4F6';

  static readonly navHeight: number = 56;
  static readonly navBackSize: number = 24;
  static readonly navTitleSize: number = 18;

  static readonly radiusSm: number = 8;
  static readonly radiusMd: number = 12;
  static readonly radiusLg: number = 16;
  static readonly radiusPill: number = 22;

  static readonly cardPadding: number = 16;
  static readonly cardMarginBottom: number = 10;
  static readonly sectionGap: number = 12;
  static readonly inputHeight: number = 46;
  static readonly buttonHeight: number = 44;

  static readonly scheduleCardBg: string[] = ['#EEF2FF', '#CCFBF1', '#FEF3C7', '#FFE4E6', '#FCE7F3', '#F3E8FF'];
  static readonly scheduleCardFg: string[] = ['#4F46E5', '#059669', '#D97706', '#E11D48', '#DB2777', '#7C3AED'];
  static readonly personalCardBg: string[] = ['#FFF7ED', '#FEF3C7', '#FFE4E6', '#FCE7F3'];
  static readonly personalCardFg: string[] = ['#EA580C', '#D97706', '#E11D48', '#DB2777'];
}

export class ShadowStyle {
  static readonly sm: ShadowOptions = { radius: 4, color: '#0F172A0A', offsetX: 0, offsetY: 1 };
  static readonly md: ShadowOptions = { radius: 8, color: '#0F172A0D', offsetX: 0, offsetY: 2 };
  static readonly lg: ShadowOptions = { radius: 16, color: '#0F172A12', offsetX: 0, offsetY: 4 };
}
