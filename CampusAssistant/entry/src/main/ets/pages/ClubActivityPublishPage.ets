import { ApiService, ApiResult } from '../service/ApiService';

@Entry
@Component
struct ClubActivityPublishPage {
  @State selectedClub: string = '篮球';
  @State title: string = '';
  @State description: string = '';
  @State venue: string = '';
  @State activityTime: string = '';
  @State selectedDate: Date = new Date();
  @State selectedTime: Date = new Date();
  @State maxParticipants: number = 20;
  @State isSubmitting: boolean = false;
  private clubOptions: string[] = ['篮球', '排球', '足球', '羽毛球', '乒乓球'];

  aboutToAppear(): void {
    if (this.activityTime.length === 0) {
      const defaultDate: Date = this.defaultActivityDate();
      this.selectedDate = defaultDate;
      this.selectedTime = defaultDate;
      this.syncActivityTime();
    }
  }

  private defaultActivityDate(): Date {
    const date: Date = new Date();
    date.setDate(date.getDate() + 1);
    date.setHours(19, 0, 0, 0);
    return date;
  }

  private pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private syncActivityTime(): void {
    const date: Date = new Date(this.selectedDate.getTime());
    date.setHours(this.selectedTime.getHours(), this.selectedTime.getMinutes(), 0, 0);
    this.activityTime = this.formatIsoDate(date);
  }

  private formatIsoDate(date: Date): string {
    return `${date.getFullYear()}-${this.pad2(date.getMonth() + 1)}-${this.pad2(date.getDate())}T${this.pad2(date.getHours())}:${this.pad2(date.getMinutes())}:00`;
  }

  private formatDisplayDate(date: Date): string {
    return `${date.getFullYear()}-${this.pad2(date.getMonth() + 1)}-${this.pad2(date.getDate())} ${this.pad2(date.getHours())}:${this.pad2(date.getMinutes())}`;
  }

  private activityDate(): Date {
    const date: Date = new Date(this.selectedDate.getTime());
    date.setHours(this.selectedTime.getHours(), this.selectedTime.getMinutes(), 0, 0);
    return date;
  }

  private deadlineDate(): Date {
    const date: Date = this.activityDate();
    date.setHours(date.getHours() - 1);
    return date;
  }

  private isDeadlineInFuture(): boolean {
    return this.deadlineDate().getTime() > new Date().getTime();
  }

  private validateForm(): boolean {
    if (this.selectedClub.length === 0) {
      this.showToast('请选择社团');
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
    const params: Record<string, Object> = {
      'club': this.selectedClub,
      'title': this.title.trim(),
      'description': this.description.trim(),
      'venue': this.venue.trim(),
      'activityTime': this.activityTime.trim(),
      'maxParticipants': this.maxParticipants
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
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor('#333333')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text('发布活动')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
        Blank()
      }
      .width('100%')
      .height(58)
      .padding({ left: 8, right: 16 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          Column() {
            Text('社团类型')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 12 })
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.clubOptions, (club: string) => {
                Text(club)
                  .fontSize(14)
                  .fontColor(this.selectedClub === club ? Color.White : '#666666')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .backgroundColor(this.selectedClub === club ? '#4A90D9' : '#F0F2F5')
                  .borderRadius(18)
                  .margin({ right: 10, bottom: 10 })
                  .onClick(() => {
                    this.selectedClub = club;
                  })
              }, (club: string) => club)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(10)

          Column() {
            this.FieldLabel('活动标题')
            TextInput({ placeholder: '例如：周五篮球友谊赛', text: this.title })
              .height(46)
              .fontSize(15)
              .backgroundColor('#F7F8FA')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.title = value;
              })

            this.FieldLabel('活动地点')
            TextInput({ placeholder: '例如：篮球场A区', text: this.venue })
              .height(46)
              .fontSize(15)
              .backgroundColor('#F7F8FA')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.venue = value;
              })

            this.FieldLabel('活动时间')
            Column() {
              DatePicker({
                start: new Date(2026, 0, 1),
                end: new Date(2035, 11, 31),
                selected: this.selectedDate
              })
                .width('100%')
                .height(160)
                .onChange((value) => {
                  const year: number = value.year ?? this.selectedDate.getFullYear();
                  const month: number = value.month ?? (this.selectedDate.getMonth() + 1);
                  const day: number = value.day ?? this.selectedDate.getDate();
                  const nextDate: Date = new Date(year, month - 1, day, this.selectedTime.getHours(), this.selectedTime.getMinutes(), 0, 0);
                  this.selectedDate = nextDate;
                  this.syncActivityTime();
                })

              Divider().margin({ top: 8, bottom: 8 })

              TimePicker({ selected: this.selectedTime })
                .useMilitaryTime(true)
                .width('100%')
                .height(160)
                .onChange((value) => {
                  const nextTime: Date = new Date(this.selectedTime.getTime());
                  nextTime.setHours(value.hour, value.minute, 0, 0);
                  this.selectedTime = nextTime;
                  this.syncActivityTime();
                })
            }
            .width('100%')
            .padding({ left: 8, right: 8, top: 8, bottom: 8 })
            .backgroundColor('#F7F8FA')
            .borderRadius(10)

            Row() {
              Text('活动时间')
                .fontSize(13)
                .fontColor('#888888')
              Blank()
              Text(this.formatDisplayDate(this.activityDate()))
                .fontSize(13)
                .fontColor('#333333')
            }
            .width('100%')
            .margin({ top: 10 })

            Row() {
              Text('报名截止')
                .fontSize(13)
                .fontColor('#888888')
              Blank()
              Text(this.formatDisplayDate(this.deadlineDate()))
                .fontSize(13)
                .fontColor('#D35400')
            }
            .width('100%')
            .margin({ top: 6 })

            this.FieldLabel('人数上限')
            Row() {
              Button('-')
                .width(42)
                .height(38)
                .fontSize(20)
                .fontColor('#4A90D9')
                .backgroundColor('#EBF3FC')
                .borderRadius(8)
                .onClick(() => {
                  this.decreaseParticipants();
                })
              Text(`${this.maxParticipants}`)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .textAlign(TextAlign.Center)
                .layoutWeight(1)
              Button('+')
                .width(42)
                .height(38)
                .fontSize(20)
                .fontColor(Color.White)
                .backgroundColor('#4A90D9')
                .borderRadius(8)
                .onClick(() => {
                  this.increaseParticipants();
                })
            }
            .width('100%')
            .height(46)
            .padding({ left: 4, right: 4 })
            .backgroundColor('#F7F8FA')
            .borderRadius(8)

            this.FieldLabel('活动介绍')
            TextArea({ placeholder: '说明活动规则、集合方式、适合人群等', text: this.description })
              .height(130)
              .fontSize(15)
              .backgroundColor('#F7F8FA')
              .borderRadius(8)
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .onChange((value: string) => {
                this.description = value;
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .margin({ top: 12 })

          Blank().height(88)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Row() {
        Button(this.isSubmitting ? '发布中' : '发布活动')
          .width('100%')
          .height(46)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor(this.isSubmitting ? '#A8C7E8' : '#4A90D9')
          .borderRadius(23)
          .enabled(!this.isSubmitting)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 10, bottom: 24 })
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor('#333333')
      .width('100%')
      .margin({ top: 16, bottom: 8 })
  }
}
