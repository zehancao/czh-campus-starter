import { ApiService, ApiResult } from '../service/ApiService';
import { ClubActivityItem } from '../model/Models';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';
import { AppStore } from '../service/AppStore';

const PAGE_SIZE: number = 20;

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
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State isLoadingMore: boolean = false;
  private clubOptions: string[] = ['', '篮球', '排球', '足球', '羽毛球', '乒乓球', '剧本杀', '桌游', '唱歌', '学习', '琴棋书画', '电竞', '户外', '聚餐'];
  private clubLabels: string[] = ['全部', '篮球', '排球', '足球', '羽毛球', '乒乓球', '剧本杀', '桌游', '唱歌', '学习', '琴棋书画', '电竞', '户外', '聚餐'];
  private statusValues: number[] = [0, 1, 2];
  private statusLabels: string[] = ['全部', '报名中', '已满'];

  aboutToAppear(): void {
    this.refreshActivities();
  }

  onPageShow(): void {
    this.refreshActivities();
  }

  private async refreshActivities(): Promise<void> {
    this.currentPage = 1;
    this.hasMore = true;
    this.isLoading = true;
    this.errorMessage = '';
    let result: ApiResult;
    if (this.showMine) {
      result = await ApiService.getMyClubActivities(this.currentPage, PAGE_SIZE);
    } else {
      result = await ApiService.getClubActivityList(this.selectedClub, this.selectedStatus, this.currentPage, PAGE_SIZE);
    }
    if (result.code === 200 && result.data !== undefined) {
      const arr: ClubActivityItem[] = this.parseActivityList(result.data);
      this.activities = arr;
      this.hasMore = arr.length >= PAGE_SIZE;
    } else {
      this.activities = [];
      this.hasMore = false;
      this.errorMessage = result.msg.length > 0 ? result.msg : '活动加载失败';
    }
    this.isLoading = false;
  }

  private async loadMore(): Promise<void> {
    if (this.isLoadingMore || !this.hasMore) {
      return;
    }
    this.isLoadingMore = true;
    this.currentPage = this.currentPage + 1;
    let result: ApiResult;
    if (this.showMine) {
      result = await ApiService.getMyClubActivities(this.currentPage, PAGE_SIZE);
    } else {
      result = await ApiService.getClubActivityList(this.selectedClub, this.selectedStatus, this.currentPage, PAGE_SIZE);
    }
    if (result.code === 200 && result.data !== undefined) {
      const newItems: ClubActivityItem[] = this.parseActivityList(result.data);
      const merged: ClubActivityItem[] = this.activities.concat(newItems);
      this.activities = merged;
      this.hasMore = newItems.length >= PAGE_SIZE;
    }
    this.isLoadingMore = false;
  }

  private async doRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.refreshActivities();
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
    item.coverImage = (obj['coverImage'] as string) ?? '';
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
    return '未知';
  }

  private statusColor(status: number): string {
    if (status === 1) {
      return Theme.success;
    }
    if (status === 2) {
      return Theme.warning;
    }
    return Theme.textSecondary;
  }

  private statusBg(status: number): string {
    if (status === 1) {
      return Theme.successLight;
    }
    if (status === 2) {
      return Theme.warningLight;
    }
    return Theme.divider;
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

  private confirmDeleteActivity(item: ClubActivityItem): void {
    AlertDialog.show({
      message: '确定删除这个活动吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: () => { this.doDeleteActivity(item.id) }
      }
    });
  }

  private async doDeleteActivity(activityId: number): Promise<void> {
    const result: ApiResult = await ApiService.deleteClubActivity(activityId);
    if (result.code === 200) {
      this.getUIContext().getPromptAction().showToast({ message: '删除成功', duration: 1500 });
      this.refreshActivities();
    } else {
      const msg: string = result.msg ?? '删除失败';
      this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
    }
  }

  build() {
    Column() {
      NavHeader({ title: '校园活动' }) {
        Button('组局')
          .height(36)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(Theme.primary)
          .borderRadius(18)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/ClubActivityPublishPage' });
          })
      }

      Row({ space: 10 }) {
        Button('活动广场')
          .height(34)
          .fontSize(13)
          .fontColor(!this.showMine ? Color.White : Theme.textSecondary)
          .backgroundColor(!this.showMine ? Theme.primary : Theme.bgInput)
          .borderRadius(17)
          .onClick(() => {
            this.showMine = false;
            this.refreshActivities();
          })
        Button('我的报名')
          .height(34)
          .fontSize(13)
          .fontColor(this.showMine ? Color.White : Theme.textSecondary)
          .backgroundColor(this.showMine ? Theme.primary : Theme.bgInput)
          .borderRadius(17)
          .onClick(() => {
            this.showMine = true;
            this.refreshActivities();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor(Theme.bgCard)

      if (!this.showMine) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.clubOptions, (club: string, index: number) => {
              Text(this.clubLabels[index])
                .fontSize(13)
                .fontColor(this.selectedClub === club ? Color.White : Theme.textSecondary)
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .backgroundColor(this.selectedClub === club ? Theme.primary : Theme.bgInput)
                .borderRadius(15)
                .onClick(() => {
                  this.selectedClub = club;
                  this.refreshActivities();
                })
            }, (club: string, index: number) => `${index}-${club}`)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .height(44)
        .backgroundColor(Theme.bgCard)

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.statusValues, (status: number, index: number) => {
              Text(this.statusLabels[index])
                .fontSize(13)
                .fontColor(this.selectedStatus === status ? Color.White : Theme.textSecondary)
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .backgroundColor(this.selectedStatus === status ? Theme.success : Theme.bgInput)
                .borderRadius(15)
                .onClick(() => {
                  this.selectedStatus = status;
                  this.refreshActivities();
                })
            }, (status: number, index: number) => `${index}-${status}`)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .height(44)
        .backgroundColor(Theme.bgCard)
      }

      Refresh({ refreshing: $$this.isRefreshing }) {
        if (this.isLoading && this.activities.length === 0) {
          Column() {
            LoadingProgress()
              .width(32)
              .height(32)
              .color(Theme.primary)
            Text('正在加载活动')
              .fontSize(14)
              .fontColor(Theme.textTertiary)
              .margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.activities.length === 0) {
          Column() {
            Text(this.errorMessage.length > 0 ? this.errorMessage : (this.showMine ? '还没有报名活动' : '暂无社团活动'))
              .fontSize(15)
              .fontColor(Theme.textTertiary)
            Button('刷新')
              .height(36)
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor(Theme.primary)
              .borderRadius(18)
              .margin({ top: 16 })
              .onClick(() => {
                this.refreshActivities();
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
            if (this.hasMore && this.activities.length > 0) {
              ListItem() {
                Row() {
                  LoadingProgress()
                    .width(20)
                    .height(20)
                    .color(Theme.primary)
                  Text('加载更多...')
                    .fontSize(13)
                    .fontColor(Theme.textTertiary)
                    .margin({ left: 8 })
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: 12, bottom: 12 })
              }
            }
            if (!this.hasMore && this.activities.length > 0) {
              ListItem() {
                Text('- 没有更多了 -')
                  .fontSize(13)
                  .fontColor(Theme.textTertiary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 12, bottom: 12 })
              }
            }
          }
          .width('100%')
          .height('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 24 })
          .scrollBar(BarState.Off)
          .onReachEnd(() => {
            this.loadMore();
          })
        }
      }
      .layoutWeight(1)
      .onRefreshing(() => {
        this.doRefresh();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder
  ActivityCard(item: ClubActivityItem) {
    Column() {
      if (item.coverImage.length > 0) {
        Image(`${ApiService.baseUrl}${item.coverImage}`)
          .width('100%')
          .height(150)
          .objectFit(ImageFit.Cover)
          .borderRadius(10)
          .margin({ bottom: 12 })
      }
      Row() {
        Text(item.club)
          .fontSize(12)
          .fontColor(Theme.primary)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(Theme.primaryLight)
          .borderRadius(4)
        Blank()
        if (AppStore.getInstance().isLoggedIn && AppStore.getInstance().userInfo.id === item.userId) {
          Text('删除')
            .fontSize(12)
            .fontColor(Theme.textTertiary)
            .margin({ right: 8 })
            .onClick(() => { this.confirmDeleteActivity(item) })
        }
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
        .fontColor(Theme.textPrimary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 10 })

      Text(item.description.length > 0 ? item.description : '发布者暂未填写活动介绍')
        .fontSize(13)
        .fontColor(Theme.textSecondary)
        .lineHeight(19)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 6 })

      Row() {
        Text('地点')
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width(42)
        Text(item.venue)
          .fontSize(13)
          .fontColor(Theme.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        Text('时间')
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width(42)
        Text(this.formatTime(item.activityTime))
          .fontSize(13)
          .fontColor(Theme.textPrimary)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 7 })

      Row() {
        Text('截止')
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width(42)
        Text(this.deadlineTime(item.activityTime))
          .fontSize(13)
          .fontColor(Theme.warning)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 7 })

      Row() {
        Text('人数')
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .width(42)
        Text(`${item.currentParticipants}/${item.maxParticipants}`)
          .fontSize(13)
          .fontColor(item.currentParticipants >= item.maxParticipants ? Theme.warning : Theme.textPrimary)
          .layoutWeight(1)
        Text('查看详情')
          .fontSize(13)
          .fontColor(Theme.primary)
      }
      .width('100%')
      .margin({ top: 7 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Theme.bgCard)
    .borderRadius(10)
    .shadow(ShadowStyle.sm)
    .onClick(() => {
      this.goDetail(item);
    })
  }
}
