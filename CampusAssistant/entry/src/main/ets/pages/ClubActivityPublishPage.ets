import { ApiService, ApiResult } from '../service/ApiService';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

@Entry
@Component
struct ClubActivityPublishPage {
  @State selectedClub: string = '';
  @State customClub: string = '';
  @State title: string = '';
  @State description: string = '';
  @State venue: string = '';
  @State activityTime: string = '';
  @State maxParticipants: number = 20;
  @State isSubmitting: boolean = false;
  @State coverImage: string = '';
  @State selectedYear: number = 2026;
  @State selectedMonth: number = 1;
  @State selectedDay: number = 1;
  @State selectedHour: number = 19;
  @State selectedMinute: number = 0;
  private clubOptions: string[] = ['篮球', '排球', '足球', '羽毛球', '乒乓球', '剧本杀', '桌游', '唱歌', '学习', '琴棋书画', '电竞', '户外', '聚餐', '其他'];

  private yearRange: string[] = [];
  private monthRange: string[] = [];
  private hourRange: string[] = [];
  private minuteRange: string[] = [];

  aboutToAppear(): void {
    const now: Date = new Date();
    this.selectedYear = now.getFullYear();
    this.selectedMonth = now.getMonth() + 1;
    this.selectedDay = now.getDate();
    this.selectedHour = 19;
    this.selectedMinute = 0;
    this.buildRanges();
    this.syncActivityTime();
  }

  private buildRanges(): void {
    const currentYear: number = new Date().getFullYear();
    const years: string[] = [];
    for (let y: number = currentYear; y <= currentYear + 3; y++) {
      years.push(`${y}年`);
    }
    this.yearRange = years;

    const months: string[] = [];
    for (let m: number = 1; m <= 12; m++) {
      months.push(`${m}月`);
    }
    this.monthRange = months;

    const hours: string[] = [];
    for (let h: number = 0; h <= 23; h++) {
      hours.push(`${h < 10 ? '0' : ''}${h}时`);
    }
    this.hourRange = hours;

    const minutes: string[] = [];
    for (let mi: number = 0; mi <= 59; mi++) {
      minutes.push(`${mi < 10 ? '0' : ''}${mi}分`);
    }
    this.minuteRange = minutes;
  }

  private daysInMonth(year: number, month: number): number {
    return new Date(year, month, 0).getDate();
  }

  private dayRange(): string[] {
    const max: number = this.daysInMonth(this.selectedYear, this.selectedMonth);
    const days: string[] = [];
    for (let d: number = 1; d <= max; d++) {
      days.push(`${d}日`);
    }
    return days;
  }

  private clampDay(): void {
    const max: number = this.daysInMonth(this.selectedYear, this.selectedMonth);
    if (this.selectedDay > max) {
      this.selectedDay = max;
    }
  }

  private pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private syncActivityTime(): void {
    this.activityTime = `${this.selectedYear}-${this.pad2(this.selectedMonth)}-${this.pad2(this.selectedDay)}T${this.pad2(this.selectedHour)}:${this.pad2(this.selectedMinute)}:00`;
  }

  private formatDisplay(): string {
    return `${this.selectedYear}-${this.pad2(this.selectedMonth)}-${this.pad2(this.selectedDay)} ${this.pad2(this.selectedHour)}:${this.pad2(this.selectedMinute)}`;
  }

  private deadlineDisplay(): string {
    const d: Date = new Date(this.selectedYear, this.selectedMonth - 1, this.selectedDay, this.selectedHour, this.selectedMinute, 0, 0);
    d.setHours(d.getHours() - 1);
    return `${d.getFullYear()}-${this.pad2(d.getMonth() + 1)}-${this.pad2(d.getDate())} ${this.pad2(d.getHours())}:${this.pad2(d.getMinutes())}`;
  }

  private isDeadlineInFuture(): boolean {
    const deadline: Date = new Date(this.selectedYear, this.selectedMonth - 1, this.selectedDay, this.selectedHour, this.selectedMinute, 0, 0);
    deadline.setHours(deadline.getHours() - 1);
    return deadline.getTime() > new Date().getTime();
  }

  private validateForm(): boolean {
    const club: string = this.selectedClub === '其他' ? this.customClub.trim() : this.selectedClub;
    if (club.length === 0) {
      this.showToast('请选择或输入活动类型');
      return false;
    }
    if (this.title.trim().length === 0) {
      this.showToast('请输入活动标题');
      return false;
    }
    if (this.title.trim().length > 200) {
      this.showToast('标题不能超过200字');
      return false;
    }
    if (this.venue.trim().length === 0) {
      this.showToast('请输入活动地点');
      return false;
    }
    this.syncActivityTime();
    if (!this.isDeadlineInFuture()) {
      this.showToast('活动时间至少要晚于当前1小时');
      return false;
    }
    if (this.maxParticipants < 1) {
      this.showToast('人数至少为1人');
      return false;
    }
    return true;
  }

  private showToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  private async submit(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }
    if (!this.validateForm()) {
      return;
    }
    this.isSubmitting = true;
    const club: string = this.selectedClub === '其他' ? this.customClub.trim() : this.selectedClub;
    const params: Record<string, Object> = {
      'club': club,
      'title': this.title.trim(),
      'description': this.description.trim(),
      'venue': this.venue.trim(),
      'activityTime': this.activityTime.trim(),
      'maxParticipants': this.maxParticipants,
      'coverImage': this.coverImage
    } as Record<string, Object>;
    const result: ApiResult = await ApiService.publishClubActivity(params);
    if (result.code === 200) {
      this.showToast('活动发布成功');
      this.getUIContext().getRouter().back();
    } else {
      this.showToast(result.msg.length > 0 ? result.msg : '发布失败');
    }
    this.isSubmitting = false;
  }

  private async pickCover(): Promise<void> {
    try {
      const uris: string[] = await ApiService.pickImages();
      if (uris.length === 0) {
        return;
      }
      const url: string = await ApiService.uploadClubCover(uris[0]);
      if (url.length > 0 && !url.startsWith('ERROR:')) {
        this.coverImage = url;
        this.showToast('封面上传成功');
      } else {
        this.showToast('封面上传失败');
      }
    } catch (_err) {
      this.showToast('选择图片失败');
    }
  }

  private decreaseParticipants(): void {
    if (this.maxParticipants > 1) {
      this.maxParticipants -= 1;
    }
  }

  private increaseParticipants(): void {
    if (this.maxParticipants < 999) {
      this.maxParticipants += 1;
    }
  }

  build() {
    Column() {
      NavHeader({ title: '发布活动' })

      Scroll() {
        Column() {
          Column() {
            Text('活动类型')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.textPrimary)
              .width('100%')
              .margin({ bottom: 12 })
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.clubOptions, (club: string) => {
                Text(club)
                  .fontSize(14)
                  .fontColor(this.selectedClub === club ? Color.White : Theme.textSecondary)
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .backgroundColor(this.selectedClub === club ? Theme.primary : Theme.bgInput)
                  .borderRadius(18)
                  .margin({ right: 10, bottom: 10 })
                  .onClick(() => {
                    this.selectedClub = club;
                  })
              }, (club: string) => club)
            }
            .width('100%')

            if (this.selectedClub === '其他') {
              TextInput({ placeholder: '请输入活动类型，如：摄影、骑行…', text: this.customClub })
                .height(46)
                .fontSize(15)
                .backgroundColor(Theme.bgInput)
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .margin({ top: 8 })
                .onChange((value: string) => {
                  this.customClub = value;
                })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.bgCard)
          .borderRadius(10)
          .shadow(ShadowStyle.sm)

          Column() {
            Text('活动封面')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.textPrimary)
              .width('100%')
              .margin({ bottom: 12 })
            Stack() {
              if (this.coverImage.length > 0) {
                Image(`${ApiService.baseUrl}${this.coverImage}`)
                  .width('100%')
                  .height(160)
                  .borderRadius(10)
                  .objectFit(ImageFit.Cover)
              } else {
                Column() {
                  Text('🖼️').fontSize(32)
                  Text('点击上传活动封面')
                    .fontSize(13)
                    .fontColor(Theme.textTertiary)
                    .margin({ top: 8 })
                }
                .width('100%')
                .height(160)
                .backgroundColor(Theme.bgInput)
                .borderRadius(10)
                .border({ width: 1, color: Theme.border, style: BorderStyle.Dashed })
                .justifyContent(FlexAlign.Center)
              }
            }
            .width('100%')
            .onClick(() => {
              this.pickCover();
            })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.bgCard)
          .borderRadius(10)
          .margin({ top: 12 })
          .shadow(ShadowStyle.sm)

          Column() {
            this.FieldLabel('活动标题')
            TextInput({ placeholder: '例如：周五剧本杀组局', text: this.title })
              .height(46)
              .fontSize(15)
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.title = value;
              })

            this.FieldLabel('活动地点')
            TextInput({ placeholder: '例如：教学楼A201', text: this.venue })
              .height(46)
              .fontSize(15)
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.venue = value;
              })

            this.FieldLabel('活动日期')
            Row() {
              TextPicker({ range: this.yearRange, selected: this.selectedYear - new Date().getFullYear() })
                .width('35%')
                .height(140)
                .onChange((value: string | string[], index: number | number[]) => {
                  const i: number = index as number;
                  this.selectedYear = new Date().getFullYear() + i;
                  this.clampDay();
                  this.syncActivityTime();
                })

              TextPicker({ range: this.monthRange, selected: this.selectedMonth - 1 })
                .width('30%')
                .height(140)
                .onChange((value: string | string[], index: number | number[]) => {
                  const i: number = index as number;
                  this.selectedMonth = i + 1;
                  this.clampDay();
                  this.syncActivityTime();
                })

              TextPicker({ range: this.dayRange(), selected: this.selectedDay - 1 })
                .width('30%')
                .height(140)
                .onChange((value: string | string[], index: number | number[]) => {
                  const i: number = index as number;
                  this.selectedDay = i + 1;
                  this.syncActivityTime();
                })
            }
            .width('100%')
            .backgroundColor(Theme.bgInput)
            .borderRadius(10)

            this.FieldLabel('活动时间')
            Row() {
              TextPicker({ range: this.hourRange, selected: this.selectedHour })
                .width('50%')
                .height(140)
                .onChange((value: string | string[], index: number | number[]) => {
                  const i: number = index as number;
                  this.selectedHour = i;
                  this.syncActivityTime();
                })

              TextPicker({ range: this.minuteRange, selected: this.selectedMinute })
                .width('50%')
                .height(140)
                .onChange((value: string | string[], index: number | number[]) => {
                  const i: number = index as number;
                  this.selectedMinute = i;
                  this.syncActivityTime();
                })
            }
            .width('100%')
            .backgroundColor(Theme.bgInput)
            .borderRadius(10)
            .margin({ top: 8 })

            Row() {
              Text('活动时间')
                .fontSize(13)
                .fontColor(Theme.textSecondary)
              Blank()
              Text(this.formatDisplay())
                .fontSize(13)
                .fontColor(Theme.textPrimary)
            }
            .width('100%')
            .margin({ top: 10 })

            Row() {
              Text('报名截止')
                .fontSize(13)
                .fontColor(Theme.textSecondary)
              Blank()
              Text(this.deadlineDisplay())
                .fontSize(13)
                .fontColor(Theme.warning)
            }
            .width('100%')
            .margin({ top: 6 })

            this.FieldLabel('人数上限')
            Row() {
              Button('-')
                .width(42)
                .height(38)
                .fontSize(20)
                .fontColor(Theme.primary)
                .backgroundColor(Theme.primaryLight)
                .borderRadius(8)
                .onClick(() => {
                  this.decreaseParticipants();
                })
              Text(`${this.maxParticipants}`)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
                .textAlign(TextAlign.Center)
                .layoutWeight(1)
              Button('+')
                .width(42)
                .height(38)
                .fontSize(20)
                .fontColor(Color.White)
                .backgroundColor(Theme.primary)
                .borderRadius(8)
                .onClick(() => {
                  this.increaseParticipants();
                })
            }
            .width('100%')
            .height(46)
            .padding({ left: 4, right: 4 })
            .backgroundColor(Theme.bgInput)
            .borderRadius(8)

            this.FieldLabel('活动介绍')
            TextArea({ placeholder: '说明活动规则、集合方式、适合人群等', text: this.description })
              .height(130)
              .fontSize(15)
              .backgroundColor(Theme.bgInput)
              .borderRadius(8)
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .onChange((value: string) => {
                this.description = value;
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.bgCard)
          .borderRadius(10)
          .margin({ top: 12 })
          .shadow(ShadowStyle.sm)

          Blank().height(88)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Row() {
        Button(this.isSubmitting ? '发布中' : '发布组局')
          .width('100%')
          .height(46)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor(this.isSubmitting ? Theme.primaryLight : Theme.primary)
          .borderRadius(23)
          .enabled(!this.isSubmitting)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 10, bottom: 24 })
      .backgroundColor(Theme.bgCard)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(Theme.textPrimary)
      .width('100%')
      .margin({ top: 16, bottom: 8 })
  }
}
