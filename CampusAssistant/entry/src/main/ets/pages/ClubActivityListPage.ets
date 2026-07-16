import { ApiService, ApiResult } from '../service/ApiService';
import { ClubActivityItem } from '../model/Models';

@Entry
@Component
struct ClubActivityListPage {
  @State activities: ClubActivityItem[] = [];
  @State selectedClub: string = '';
  @State selectedStatus: number = 1;
  @State showMine: boolean = false;
  @State isRefreshing: boolean = false;
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  private clubOptions: string[] = ['', '篮球', '排球', '足球', '羽毛球', '乒乓球'];
  private clubLabels: string[] = ['全部', '篮球', '排球', '足球', '羽毛球', '乒乓球'];
  private statusValues: number[] = [0, 1, 2, 3];
  private statusLabels: string[] = ['全部', '报名中', '已满', '已结束'];

  aboutToAppear(): void {
    this.loadActivities();
  }

  onPageShow(): void {
    this.loadActivities();
  }

  private async loadActivities(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    let result: ApiResult;
    if (this.showMine) {
      result = await ApiService.getMyClubActivities();
    } else {
      result = await ApiService.getClubActivityList(this.selectedClub, this.selectedStatus);
    }
    if (result.code === 200 && result.data !== undefined) {
      this.activities = this.parseActivityList(result.data);
    } else {
      this.activities = [];
      this.errorMessage = result.msg.length > 0 ? result.msg : '活动加载失败';
    }
    this.isLoading = false;
  }

  private async refreshActivities(): Promise<void> {
    this.isRefreshing = true;
    await this.loadActivities();
    this.isRefreshing = false;
  }

  private parseActivityList(data: Object): ClubActivityItem[] {
    const arr: Object[] = data as Object[];
    const list: ClubActivityItem[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: ClubActivityItem = this.parseActivity(obj);
      list.push(item);
    }
    return list;
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

  private goDetail(item: ClubActivityItem): void {
    const params: Record<string, Object> = {
      'id': item.id
    } as Record<string, Object>;
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/ClubActivityDetailPage',
      params: params
    });
  }

  build() {
    Column() {
      Row() {
        Text('社团活动')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
        Blank()
        Button('发布')
          .height(36)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#4A90D9')
          .borderRadius(18)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/ClubActivityPublishPage' });
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 12 })
      .backgroundColor(Color.White)

      Row({ space: 10 }) {
        Button('活动广场')
          .height(34)
          .fontSize(13)
          .fontColor(!this.showMine ? Color.White : '#666666')
          .backgroundColor(!this.showMine ? '#4A90D9' : '#F0F2F5')
          .borderRadius(17)
          .onClick(() => {
            this.showMine = false;
            this.loadActivities();
          })
        Button('我的报名')
          .height(34)
          .fontSize(13)
          .fontColor(this.showMine ? Color.White : '#666666')
          .backgroundColor(this.showMine ? '#4A90D9' : '#F0F2F5')
          .borderRadius(17)
          .onClick(() => {
            this.showMine = true;
            this.loadActivities();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor(Color.White)

      if (!this.showMine) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.clubOptions, (club: string, index: number) => {
              Text(this.clubLabels[index])
                .fontSize(13)
                .fontColor(this.selectedClub === club ? Color.White : '#666666')
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .backgroundColor(this.selectedClub === club ? '#4A90D9' : '#F0F2F5')
                .borderRadius(15)
                .onClick(() => {
                  this.selectedClub = club;
                  this.loadActivities();
                })
            }, (club: string, index: number) => `${index}-${club}`)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .height(44)
        .backgroundColor(Color.White)

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.statusValues, (status: number, index: number) => {
              Text(this.statusLabels[index])
                .fontSize(13)
                .fontColor(this.selectedStatus === status ? Color.White : '#666666')
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .backgroundColor(this.selectedStatus === status ? '#3B7A57' : '#F0F2F5')
                .borderRadius(15)
                .onClick(() => {
                  this.selectedStatus = status;
                  this.loadActivities();
                })
            }, (status: number, index: number) => `${index}-${status}`)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .height(44)
        .backgroundColor(Color.White)
      }

      Refresh({ refreshing: $$this.isRefreshing }) {
        if (this.isLoading && this.activities.length === 0) {
          Column() {
            LoadingProgress()
              .width(32)
              .height(32)
              .color('#4A90D9')
            Text('正在加载活动')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.activities.length === 0) {
          Column() {
            Text(this.errorMessage.length > 0 ? this.errorMessage : (this.showMine ? '还没有报名活动' : '暂无社团活动'))
              .fontSize(15)
              .fontColor('#999999')
            Button('刷新')
              .height(36)
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor('#4A90D9')
              .borderRadius(18)
              .margin({ top: 16 })
              .onClick(() => {
                this.loadActivities();
              })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 12 }) {
            ForEach(this.activities, (item: ClubActivityItem) => {
              ListItem() {
                this.ActivityCard(item)
              }
            }, (item: ClubActivityItem) => `${item.id}`)
          }
          .width('100%')
          .height('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 24 })
          .scrollBar(BarState.Off)
        }
      }
      .layoutWeight(1)
      .onRefreshing(() => {
        this.refreshActivities();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  ActivityCard(item: ClubActivityItem) {
    Column() {
      Row() {
        Text(item.club)
          .fontSize(12)
          .fontColor('#4A90D9')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor('#EBF3FC')
          .borderRadius(4)
        Blank()
        Text(this.statusText(item.status))
          .fontSize(12)
          .fontColor(this.statusColor(item.status))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.statusBg(item.status))
          .borderRadius(4)
      }
      .width('100%')

      Text(item.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#222222')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 10 })

      Text(item.description.length > 0 ? item.description : '发布者暂未填写活动介绍')
        .fontSize(13)
        .fontColor('#777777')
        .lineHeight(19)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 6 })

      Row() {
        Text('地点')
          .fontSize(12)
          .fontColor('#999999')
          .width(42)
        Text(item.venue)
          .fontSize(13)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        Text('时间')
          .fontSize(12)
          .fontColor('#999999')
          .width(42)
        Text(this.formatTime(item.activityTime))
          .fontSize(13)
          .fontColor('#333333')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 7 })

      Row() {
        Text('截止')
          .fontSize(12)
          .fontColor('#999999')
          .width(42)
        Text(this.deadlineTime(item.activityTime))
          .fontSize(13)
          .fontColor('#D35400')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 7 })

      Row() {
        Text('人数')
          .fontSize(12)
          .fontColor('#999999')
          .width(42)
        Text(`${item.currentParticipants}/${item.maxParticipants}`)
          .fontSize(13)
          .fontColor(item.currentParticipants >= item.maxParticipants ? '#E67E22' : '#333333')
          .layoutWeight(1)
        Text('查看详情')
          .fontSize(13)
          .fontColor('#4A90D9')
      }
      .width('100%')
      .margin({ top: 7 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .onClick(() => {
      this.goDetail(item);
    })
  }
}

