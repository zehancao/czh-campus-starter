import { ApiService, ApiResult } from '../service/ApiService';
import { ClubActivityItem } from '../model/Models';

@Entry
@Component
struct ClubActivityDetailPage {
  @State activityId: number = 0;
  @State activity: ClubActivityItem = new ClubActivityItem();
  @State isLoading: boolean = false;
  @State isSubmitting: boolean = false;
  @State errorMessage: string = '';

  aboutToAppear(): void {
    this.readParams();
    this.loadDetail();
  }

  onPageShow(): void {
    if (this.activityId > 0) {
      this.loadDetail();
    }
  }

  private readParams(): void {
    const paramsObj: Object | undefined = this.getUIContext().getRouter().getParams();
    if (paramsObj !== undefined) {
      const params: Record<string, Object> = paramsObj as Record<string, Object>;
      const idObj: Object = params['id'];
      if (idObj !== null && idObj !== undefined) {
        if (typeof idObj === 'number') {
          this.activityId = idObj as number;
        } else {
          const idText: string = idObj as string;
          const parsed: number = parseInt(idText);
          this.activityId = parsed > 0 ? parsed : 0;
        }
      }
    }
  }

  private async loadDetail(): Promise<void> {
    if (this.activityId <= 0) {
      this.errorMessage = '活动参数错误';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    const result: ApiResult = await ApiService.getClubActivityDetail(this.activityId);
    if (result.code === 200 && result.data !== undefined) {
      const obj: Record<string, Object> = result.data as Record<string, Object>;
      this.activity = this.parseActivity(obj);
    } else {
      this.errorMessage = result.msg.length > 0 ? result.msg : '活动详情加载失败';
    }
    this.isLoading = false;
  }

  private parseActivity(obj: Record<string, Object>): ClubActivityItem {
    const item: ClubActivityItem = new ClubActivityItem();
    item.id = (obj['id'] as number) ?? 0;
    item.userId = (obj['userId'] as number) ?? 0;
    item.userName = (obj['userName'] as string) ?? '';
    item.club = (obj['club'] as string) ?? '';
    item.title = (obj['title'] as string) ?? '';
    item.description = (obj['description'] as string) ?? '';
    item.venue = (obj['venue'] as string) ?? '';
    item.activityTime = (obj['activityTime'] as string) ?? '';
    item.maxParticipants = (obj['maxParticipants'] as number) ?? 20;
    item.currentParticipants = (obj['currentParticipants'] as number) ?? 0;
    item.status = (obj['status'] as number) ?? 1;
    item.createTime = (obj['createTime'] as string) ?? '';
    item.registered = (obj['registered'] as boolean) ?? false;
    const namesObj: Object = obj['participantNames'];
    if (namesObj !== null && namesObj !== undefined) {
      item.participantNames = namesObj as string[];
    }
    return item;
  }

  private async registerActivity(): Promise<void> {
    if (this.activityId <= 0 || this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;
    const result: ApiResult = await ApiService.registerClubActivity(this.activityId);
    if (result.code === 200) {
      this.getUIContext().getPromptAction().showToast({ message: '报名成功' });
      await this.loadDetail();
    } else {
      this.getUIContext().getPromptAction().showToast({ message: result.msg.length > 0 ? result.msg : '报名失败' });
    }
    this.isSubmitting = false;
  }

  private async cancelActivity(): Promise<void> {
    if (this.activityId <= 0 || this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;
    const result: ApiResult = await ApiService.cancelClubActivity(this.activityId);
    if (result.code === 200) {
      this.getUIContext().getPromptAction().showToast({ message: '已取消报名' });
      await this.loadDetail();
    } else {
      this.getUIContext().getPromptAction().showToast({ message: result.msg.length > 0 ? result.msg : '取消失败' });
    }
    this.isSubmitting = false;
  }

  private statusText(status: number): string {
    if (status === 1) {
      return '报名中';
    }
    if (status === 2) {
      return '已满';
    }
    if (status === 3) {
      return '已结束';
    }
    return '未知';
  }

  private statusColor(status: number): string {
    if (status === 1) {
      return '#2E7D32';
    }
    if (status === 2) {
      return '#E67E22';
    }
    if (status === 3) {
      return '#999999';
    }
    return '#666666';
  }

  private statusBg(status: number): string {
    if (status === 1) {
      return '#EAF6ED';
    }
    if (status === 2) {
      return '#FFF3E5';
    }
    if (status === 3) {
      return '#EEEEEE';
    }
    return '#F3F3F3';
  }

  private formatTime(time: string): string {
    if (time.length >= 16) {
      return time.replace('T', ' ').substring(0, 16);
    }
    return time;
  }

  private pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${this.pad2(date.getMonth() + 1)}-${this.pad2(date.getDate())} ${this.pad2(date.getHours())}:${this.pad2(date.getMinutes())}`;
  }

  private deadlineTime(time: string): string {
    if (time.length < 16) {
      return '活动开始前1小时';
    }
    const date: Date = new Date(time);
    const timeMs: number = date.getTime();
    if (timeMs <= 0) {
      return '活动开始前1小时';
    }
    date.setHours(date.getHours() - 1);
    return this.formatDate(date);
  }

  private isBeforeDeadline(): boolean {
    if (this.activity.activityTime.length < 16) {
      return true;
    }
    const date: Date = new Date(this.activity.activityTime);
    const timeMs: number = date.getTime();
    if (timeMs <= 0) {
      return true;
    }
    date.setHours(date.getHours() - 1);
    return new Date().getTime() < date.getTime();
  }

  private joinPercent(): number {
    if (this.activity.maxParticipants <= 0) {
      return 0;
    }
    const percent: number = Math.floor(this.activity.currentParticipants * 100 / this.activity.maxParticipants);
    return percent > 100 ? 100 : percent;
  }

  private canRegister(): boolean {
    return this.activity.status === 1 && this.isBeforeDeadline() && !this.activity.registered && this.activity.currentParticipants < this.activity.maxParticipants;
  }

  private canCancel(): boolean {
    return this.activity.registered && this.activity.status === 1 && this.isBeforeDeadline();
  }

  private actionText(): string {
    if (this.activity.registered) {
      return this.canCancel() ? '取消报名' : '已报名';
    }
    if (!this.isBeforeDeadline()) {
      return '报名已截止';
    }
    return this.canRegister() ? '立即报名' : '暂不可报名';
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
        Text('活动详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
        Blank()
      }
      .width('100%')
      .height(58)
      .padding({ left: 8, right: 16 })
      .backgroundColor(Color.White)

      if (this.isLoading && this.activity.id === 0) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color('#4A90D9')
          Text('正在加载详情')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0 && this.activity.id === 0) {
        Column() {
          Text(this.errorMessage)
            .fontSize(15)
            .fontColor('#999999')
          Button('重新加载')
            .height(36)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor('#4A90D9')
            .borderRadius(18)
            .margin({ top: 16 })
            .onClick(() => {
              this.loadDetail();
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Text(this.activity.club)
                  .fontSize(13)
                  .fontColor('#4A90D9')
                  .padding({ left: 9, right: 9, top: 4, bottom: 4 })
                  .backgroundColor('#EBF3FC')
                  .borderRadius(4)
                Blank()
                Text(this.statusText(this.activity.status))
                  .fontSize(13)
                  .fontColor(this.statusColor(this.activity.status))
                  .padding({ left: 9, right: 9, top: 4, bottom: 4 })
                  .backgroundColor(this.statusBg(this.activity.status))
                  .borderRadius(4)
              }
              .width('100%')

              Text(this.activity.title)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#222222')
                .lineHeight(32)
                .width('100%')
                .margin({ top: 14 })

              Text(this.activity.description.length > 0 ? this.activity.description : '发布者暂未填写活动介绍')
                .fontSize(15)
                .fontColor('#666666')
                .lineHeight(23)
                .width('100%')
                .margin({ top: 12 })
            }
            .width('100%')
            .padding(18)
            .backgroundColor(Color.White)
            .borderRadius(10)

            Column() {
              this.InfoRow('社团', this.activity.club)
              Divider().margin({ left: 16 })
              this.InfoRow('地点', this.activity.venue)
              Divider().margin({ left: 16 })
              this.InfoRow('活动时间', this.formatTime(this.activity.activityTime))
              Divider().margin({ left: 16 })
              this.InfoRow('报名截止', this.deadlineTime(this.activity.activityTime))
              Divider().margin({ left: 16 })
              this.InfoRow('发布人', this.activity.userName.length > 0 ? this.activity.userName : '未知')
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(10)
            .margin({ top: 12 })

            Column() {
              Row() {
                Text('报名人数')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')
                Blank()
                Text(`${this.activity.currentParticipants}/${this.activity.maxParticipants}`)
                  .fontSize(15)
                  .fontColor('#4A90D9')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')

              Progress({ value: this.joinPercent(), total: 100, type: ProgressType.Linear })
                .width('100%')
                .height(8)
                .color('#4A90D9')
                .backgroundColor('#E8ECF2')
                .margin({ top: 12 })

              if (this.activity.participantNames.length > 0) {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.activity.participantNames, (name: string, index: number) => {
                    Text(name)
                      .fontSize(13)
                      .fontColor('#555555')
                      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                      .backgroundColor('#F0F2F5')
                      .borderRadius(14)
                      .margin({ right: 8, top: 8 })
                  }, (name: string, index: number) => `${index}-${name}`)
                }
                .width('100%')
                .margin({ top: 10 })
              } else {
                Text('暂无报名同学')
                  .fontSize(13)
                  .fontColor('#999999')
                  .margin({ top: 12 })
                  .width('100%')
              }
            }
            .width('100%')
            .padding(18)
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
      }

      if (this.activity.id > 0) {
        Row() {
          if (this.activity.registered) {
            Button(this.isSubmitting ? '处理中' : this.actionText())
              .width('100%')
              .height(46)
              .fontSize(16)
              .fontColor(this.canCancel() ? '#E74C3C' : '#999999')
              .backgroundColor(this.canCancel() ? '#FDEDEC' : '#EEEEEE')
              .borderRadius(23)
              .enabled(this.canCancel() && !this.isSubmitting)
              .onClick(() => {
                this.cancelActivity();
              })
          } else {
            Button(this.isSubmitting ? '处理中' : this.actionText())
              .width('100%')
              .height(46)
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor(this.canRegister() ? '#4A90D9' : '#CCCCCC')
              .borderRadius(23)
              .enabled(this.canRegister() && !this.isSubmitting)
              .onClick(() => {
                this.registerActivity();
              })
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 10, bottom: 24 })
        .backgroundColor(Color.White)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#888888')
        .width(70)
      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
  }
}

