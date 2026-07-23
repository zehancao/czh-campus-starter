import { AppStore } from '../service/AppStore';
import { UserInfo, CourseSchedule, Product, Announcement, Semester, ProductCategory, ClubActivityItem, Conversation, ChatMessage } from '../model/Models';
import { WebSocketService, WsMessage, MessageCallback } from '../service/WebSocketService';
import { Constants } from '../common/Constants';
import { ApiService, ApiResult } from '../service/ApiService';
import { Theme, ShadowStyle } from '../common/Theme';
import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { calcSemesterWeek, semesterWeekDate } from '../common/utils';

const WEEK_DAY_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];
const SCHEDULE_SECTION_HEIGHT: number = 66;

@Entry
@Component
struct MainPage {
  @State currentTab: number = 0;
  @State userInfo: UserInfo = new UserInfo();
  @State scheduleList: CourseSchedule[] = [];
  @State announcements: Announcement[] = [];
  @State myActivities: ClubActivityItem[] = [];
  @State products: Product[] = [];
  @State todayCourses: CourseSchedule[] = [];
  @State scheduleGrid: CourseSchedule[][] = [];
  @State isRefreshing: boolean = false;
  @State currentWeek: number = 1;
  @State todayWeek: number = 1;
  @State semesterId: number = 0;
  @State semesterWeekCount: number = 20;
  @State semesterName: string = '';
  @State semesterStartDate: string = '';
  @State unreadCount: number = 0;
  @State conversations: Conversation[] = [];
  @State onlineUserIds: number[] = [];
  @State conversationKeyword: string = '';
  @State conversationLoading: boolean = true;
  @State conversationError: string = '';
  private conversationLoadedOnce: boolean = false;
  @State categories: ProductCategory[] = [];
  @State selectedCategoryId: number = 0;
  @State showAddCourseForm: boolean = false;
  @State showCourseDetail: boolean = false;
  @State selectedCourse: CourseSchedule = new CourseSchedule();
  @State addCourseName: string = '';
  @State addClassroom: string = '';
  @State addTeacherName: string = '';
  @State addDayOfWeek: number = 1;
  @State addStartSection: number = 1;
  @State addEndSection: number = 2;
  @State addStartWeek: number = 1;
  @State addEndWeek: number = 20;
  private mainWsCallback: MessageCallback | null = null;
  @State aiMessages: AiMsg[] = [];
  @State aiInputText: string = '';
  @State aiIsLoading: boolean = false;
  @State aiStreamingIndex: number = -1;
  @State aiThinking: boolean = false;
  @State aiStreamText: string = '';
  private aiScroller: Scroller = new Scroller();
  private textDecoder: util.TextDecoder = new util.TextDecoder('utf-8');
  private aiHttpRequest: http.HttpRequest | null = null;
  private aiPendingText: string = '';
  private aiFlushTimer: number = -1;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.userInfo = store.userInfo;
    const welcome: AiMsg = new AiMsg();
    welcome.role = 'assistant';
    welcome.content = '你好！我是中飞院智能校园助手，可以回答校规、办事流程等问题，请问有什么可以帮你的？';
    this.aiMessages.push(welcome);
    this.loadSemester();
    this.loadAnnouncements();
    this.loadCategories();
    this.loadProducts();
    this.loadUnreadCount();
    this.loadMyActivities();
    this.mainWsCallback = (msg: WsMessage) => {
      if (msg.type === 'unread_update') {
        const data: Record<string, Object> = msg.data as Record<string, Object>;
        this.unreadCount = (data['unreadCount'] as number) ?? 0;
      }
      if (msg.type === 'message') {
        this.handleConversationWsMessage(msg);
      }
      if (msg.type === 'user_status') {
        const data: Record<string, Object> = msg.data as Record<string, Object>;
        const uid: number = (data['userId'] as number) ?? 0;
        const online: boolean = (data['online'] as boolean) ?? false;
        this.updateOnlineUser(uid, online);
      }
      if (msg.type === 'online_users_loaded' || msg.type === 'connection_state') {
        this.loadConversations(false);
      }
    };
    WebSocketService.getInstance().onMessage(this.mainWsCallback);
  }

  onPageShow(): void {
    const store: AppStore = AppStore.getInstance();
    this.userInfo = store.userInfo;
    this.loadSemester();
    this.loadProducts();
    this.loadMyActivities();
    this.loadUnreadCount();
    if (store.isLoggedIn && this.conversationLoadedOnce) {
      this.loadConversations(false);
    }
  }

  aboutToDisappear(): void {
    if (this.mainWsCallback !== null) {
      WebSocketService.getInstance().removeMessageCallback(this.mainWsCallback);
    }
    if (this.aiHttpRequest !== null) {
      this.aiHttpRequest.off('dataReceive');
      this.aiHttpRequest.off('dataEnd');
      this.aiHttpRequest.destroy();
      this.aiHttpRequest = null;
    }
    if (this.aiFlushTimer !== -1) {
      clearInterval(this.aiFlushTimer);
      this.aiFlushTimer = -1;
    }
  }

  private async loadUnreadCount(): Promise<void> {
    const result: ApiResult = await ApiService.getUnreadCount();
    if (result.code === 200 && result.data !== undefined) {
      const obj: Record<string, Object> = result.data as Record<string, Object>;
      this.unreadCount = (obj['unreadCount'] as number) ?? 0;
    }
  }

  private async loadConversations(showLoading: boolean = true): Promise<void> {
    if (showLoading || !this.conversationLoadedOnce) {
      this.conversationLoading = true;
    }
    if (showLoading) {
      this.conversationError = '';
    }
    const result: ApiResult = await ApiService.getConversations();
    if (result.code === 200 && result.data !== undefined) {
      this.conversations = ApiService.parseConversationList(result.data);
      this.conversationError = '';
    } else if (showLoading) {
      this.conversationError = result.msg;
    }
    const onlineResult: ApiResult = await ApiService.getOnlineUsers();
    if (onlineResult.code === 200 && onlineResult.data !== undefined) {
      this.onlineUserIds = onlineResult.data as number[];
    }
    this.conversationLoadedOnce = true;
    this.conversationLoading = false;
  }

  private handleConversationWsMessage(msg: WsMessage): void {
    const data: Record<string, Object> = msg.data as Record<string, Object>;
    const item: ChatMessage = new ChatMessage();
    item.id = (data['id'] as number) ?? 0;
    item.conversationId = (data['conversationId'] as number) ?? 0;
    item.senderId = (data['senderId'] as number) ?? 0;
    item.content = (data['content'] as string) ?? '';
    item.msgType = (data['msgType'] as string) ?? 'text';
    item.createTime = (data['createTime'] as string) ?? '';
    item.isMine = item.senderId === AppStore.getInstance().userInfo.id;
    if (item.conversationId <= 0) {
      return;
    }
    const next: Conversation[] = [];
    let found: boolean = false;
    for (let i: number = 0; i < this.conversations.length; i++) {
      const source: Conversation = this.conversations[i];
      if (source.id === item.conversationId) {
        const updated: Conversation = new Conversation();
        updated.id = source.id;
        updated.otherUserId = source.otherUserId;
        updated.otherUserName = source.otherUserName;
        updated.otherUserAvatar = source.otherUserAvatar;
        updated.lastMessage = item.content;
        updated.lastTime = item.createTime;
        updated.unreadCount = item.isMine ? source.unreadCount : source.unreadCount + 1;
        updated.productId = source.productId;
        next.unshift(updated);
        found = true;
      } else {
        next.push(source);
      }
    }
    if (found) {
      this.conversations = next;
    } else {
      this.loadConversations(false);
    }
  }

  private updateOnlineUser(userId: number, online: boolean): void {
    if (userId <= 0) {
      return;
    }
    const next: number[] = [];
    let exists: boolean = false;
    for (let i: number = 0; i < this.onlineUserIds.length; i++) {
      if (this.onlineUserIds[i] === userId) {
        exists = true;
        if (online) {
          next.push(this.onlineUserIds[i]);
        }
      } else {
        next.push(this.onlineUserIds[i]);
      }
    }
    if (online && !exists) {
      next.push(userId);
    }
    this.onlineUserIds = next;
  }

  private isUserOnline(userId: number): boolean {
    for (let i: number = 0; i < this.onlineUserIds.length; i++) {
      if (this.onlineUserIds[i] === userId) {
        return true;
      }
    }
    return false;
  }

  private shouldShowConversation(item: Conversation): boolean {
    const key: string = this.conversationKeyword.trim();
    if (key.length === 0) {
      return true;
    }
    return item.otherUserName.indexOf(key) >= 0 || item.lastMessage.indexOf(key) >= 0;
  }

  private formatConvTime(text: string): string {
    if (text.length === 0) {
      return '';
    }
    const value: string = text.replace('T', ' ');
    if (value.length >= 16) {
      return value.substring(5, 16);
    }
    return value;
  }

  private previewConvText(item: Conversation): string {
    if (item.lastMessage.length === 0) {
      return '暂无消息';
    }
    return item.lastMessage;
  }

  private markConversationReadLocally(conversationId: number): void {
    const nextList: Conversation[] = [];
    for (let i: number = 0; i < this.conversations.length; i++) {
      const source: Conversation = this.conversations[i];
      if (source.id === conversationId) {
        const updated: Conversation = new Conversation();
        updated.id = source.id;
        updated.otherUserId = source.otherUserId;
        updated.otherUserName = source.otherUserName;
        updated.otherUserAvatar = source.otherUserAvatar;
        updated.lastMessage = source.lastMessage;
        updated.lastTime = source.lastTime;
        updated.unreadCount = 0;
        updated.productId = source.productId;
        nextList.push(updated);
      } else {
        nextList.push(source);
      }
    }
    this.conversations = nextList;
  }

  private goChat(item: Conversation): void {
    this.markConversationReadLocally(item.id);
    router.pushUrl({
      url: 'pages/ChatPage',
      params: {
        'conversationId': item.id.toString(),
        'otherUserId': item.otherUserId.toString(),
        'otherUserName': item.otherUserName,
        'productId': item.productId.toString()
      } as Record<string, string>
    });
  }

  private openEditProfilePage(): void {
    router.pushUrl({ url: 'pages/EditProfilePage' }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '打开编辑资料失败，请重新编译后再试' });
    });
  }

  private async loadCategories(): Promise<void> {
    const result: ApiResult = await ApiService.getProductCategories();
    if (result.code === 200 && result.data !== undefined) {
      this.categories = ApiService.parseProductCategoryList(result.data);
    }
  }

  private async loadSemester(): Promise<void> {
    const result: ApiResult = await ApiService.getCurrentSemester();
    if (result.code === 200 && result.data !== undefined) {
      const semester: Semester = ApiService.parseSemester(result.data);
      this.semesterId = semester.id;
      this.semesterName = semester.name;
      this.semesterStartDate = semester.startDate;
      this.semesterWeekCount = semester.weekCount;
      this.addEndWeek = semester.weekCount;
      this.todayWeek = this.calcCurrentWeek(semester.startDate, semester.weekCount);
      this.currentWeek = this.todayWeek;
    }
    this.loadSchedule();
  }

  private calcCurrentWeek(startDateStr: string, weekCount: number): number {
    return calcSemesterWeek(startDateStr, weekCount);
  }

  private async loadSchedule(): Promise<void> {
    const sid: number = this.semesterId > 0 ? this.semesterId : 1;
    const result: ApiResult = await ApiService.getMySchedule(sid);
    if (result.code === 200) {
      if (result.data !== undefined) {
        this.scheduleList = ApiService.parseScheduleList(result.data);
      } else {
        this.scheduleList = [];
      }
      this.updateScheduleGrid();
    }
  }

  private updateScheduleGrid(): void {
    const today: number = new Date().getDay();
    const dayOfWeek: number = today === 0 ? 7 : today;
    const filtered: CourseSchedule[] = this.scheduleList.filter(
      (item: CourseSchedule) => this.isCourseActiveInWeek(item, this.currentWeek));
    this.todayCourses = filtered.filter((item: CourseSchedule) => item.dayOfWeek === dayOfWeek);
    this.scheduleGrid = [];
    for (let day = 1; day <= 7; day++) {
      const dayList: CourseSchedule[] = [];
      for (let sec = 1; sec <= 10; sec++) {
        const found: CourseSchedule | undefined = filtered.find(
          (item: CourseSchedule) => item.dayOfWeek === day && item.startSection <= sec && item.endSection >= sec);
        dayList.push(found ?? new CourseSchedule());
      }
      this.scheduleGrid.push(dayList);
    }
  }

  private async loadAnnouncements(): Promise<void> {
    const result: ApiResult = await ApiService.getAnnouncementList('');
    if (result.code === 200 && result.data !== undefined) {
      this.announcements = ApiService.parseAnnouncementList(result.data);
    }
  }

  private async searchProducts(): Promise<void> {
    this.showSuggestions = false;
    if (this.searchKeyword.trim().length === 0) {
      this.loadProducts();
      return;
    }
    const result: ApiResult = await ApiService.request(http.RequestMethod.GET,
      `/api/product/search?keyword=${encodeURIComponent(this.searchKeyword.trim())}`, undefined, false);
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      this.products = [];
      for (let i = 0; i < arr.length; i++) {
        const obj: Record<string, Object> = arr[i] as Record<string, Object>;
        const item: Product = new Product();
        item.id = (obj['id'] as number) ?? 0;
        item.sellerId = (obj['sellerId'] as number) ?? 0;
        item.sellerName = (obj['sellerName'] as string) ?? '';
        item.categoryId = (obj['categoryId'] as number) ?? 0;
        item.categoryName = (obj['categoryName'] as string) ?? '';
        item.title = (obj['title'] as string) ?? '';
        item.description = (obj['description'] as string) ?? '';
        item.price = (obj['price'] as number) ?? 0;
        item.originalPrice = (obj['originalPrice'] as number) ?? 0;
        item.conditionLevel = (obj['conditionLevel'] as number) ?? 1;
        item.status = (obj['status'] as number) ?? 1;
        item.viewCount = (obj['viewCount'] as number) ?? 0;
        item.campusLocation = (obj['campusLocation'] as string) ?? '';
        item.createTime = (obj['createTime'] as string) ?? '';
        const imagesObj: Object = obj['images'];
        if (imagesObj !== null && imagesObj !== undefined) {
          item.images = imagesObj as string[];
        }
        this.products.push(item);
      }
    }
  }

  private async loadSearchSuggestions(keyword: string): Promise<void> {
    if (keyword.trim().length === 0) {
      this.searchSuggestions = [];
      this.showSuggestions = false;
      return;
    }
    const result: ApiResult = await ApiService.request(http.RequestMethod.GET,
      `/api/product/search-suggest?keyword=${encodeURIComponent(keyword.trim())}`, undefined, false);
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      const list: string[] = [];
      for (const obj of arr) {
        list.push(obj as string);
      }
      this.searchSuggestions = list;
      this.showSuggestions = list.length > 0;
    } else {
      this.searchSuggestions = [];
      this.showSuggestions = false;
    }
  }

  private async loadProducts(): Promise<void> {
    const result: ApiResult = await ApiService.getProductList(this.selectedCategoryId);
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      this.products = [];
      for (let i = 0; i < arr.length; i++) {
        const obj: Record<string, Object> = arr[i] as Record<string, Object>;
        const item: Product = new Product();
        item.id = (obj['id'] as number) ?? 0;
        item.sellerId = (obj['sellerId'] as number) ?? 0;
        item.sellerName = (obj['sellerName'] as string) ?? '';
        item.categoryId = (obj['categoryId'] as number) ?? 0;
        item.categoryName = (obj['categoryName'] as string) ?? '';
        item.title = (obj['title'] as string) ?? '';
        item.description = (obj['description'] as string) ?? '';
        item.price = (obj['price'] as number) ?? 0;
        item.originalPrice = (obj['originalPrice'] as number) ?? 0;
        item.conditionLevel = (obj['conditionLevel'] as number) ?? 1;
        item.status = (obj['status'] as number) ?? 1;
        item.viewCount = (obj['viewCount'] as number) ?? 0;
        item.campusLocation = (obj['campusLocation'] as string) ?? '';
        item.createTime = (obj['createTime'] as string) ?? '';
        const imagesObj: Object = obj['images'];
        if (imagesObj !== null && imagesObj !== undefined) {
          item.images = imagesObj as string[];
        }
        this.products.push(item);
      }
    }
  }

  private async loadAllData(): Promise<void> {
    this.isRefreshing = true;
    await Promise.all([this.loadSchedule(), this.loadAnnouncements(), this.loadProducts(), this.loadMyActivities(), this.loadUnreadCount()]);
    this.isRefreshing = false;
  }

  private async loadMyActivities(): Promise<void> {
    const result: ApiResult = await ApiService.getMyClubActivities();
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      this.myActivities = [];
      for (let i = 0; i < arr.length; i++) {
        const obj: Record<string, Object> = arr[i] as Record<string, Object>;
        const item: ClubActivityItem = new ClubActivityItem();
        item.id = (obj['id'] as number) ?? 0;
        item.club = (obj['club'] as string) ?? '';
        item.title = (obj['title'] as string) ?? '';
        item.venue = (obj['venue'] as string) ?? '';
        item.activityTime = (obj['activityTime'] as string) ?? '';
        this.myActivities.push(item);
      }
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
      TabContent() {
        this.HomeContent()
      }.tabBar(this.TabItem(0, '首页'))

      TabContent() {
        this.MarketContent()
      }.tabBar(this.TabItem(1, '交易'))

      TabContent() {
        this.MessageContent()
      }.tabBar(this.TabItem(2, '消息'))

      TabContent() {
        this.AIChatContent()
      }.tabBar(this.TabItem(3, 'AI'))

      TabContent() {
        this.ProfileContent()
      }.tabBar(this.TabItem(4, '我的'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
    .onChange((index: number) => {
      this.currentTab = index;
      if (index === 2 && !this.conversationLoadedOnce) {
        this.loadConversations();
      }
    })
  }

  @Builder
  TabItem(index: number, label: string) {
    Column() {
      if (index === 0) {
        Image(this.currentTab === 0 ? $r('app.media.ic_home_active') : $r('app.media.ic_home'))
          .width(22).height(22)
      } else if (index === 1) {
        Image(this.currentTab === 1 ? $r('app.media.ic_market_active') : $r('app.media.ic_market'))
          .width(22).height(22)
      } else if (index === 2) {
        Image(this.currentTab === 2 ? $r('app.media.ic_message_active') : $r('app.media.ic_message'))
          .width(22).height(22)
      } else if (index === 3) {
        Image(this.currentTab === 3 ? $r('app.media.ic_ai_active') : $r('app.media.ic_ai'))
          .width(22).height(22)
      } else {
        Image(this.currentTab === 4 ? $r('app.media.ic_profile_active') : $r('app.media.ic_profile'))
          .width(22).height(22)
      }
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? Theme.primary : Theme.textTertiary)
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  QuickEntry(emoji: string, label: string, targetPage: string) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(68).height(88)
        .backgroundColor('#C8CFDA')
        .borderRadius(28)
        .offset({ x: 4, y: 4 })
      Column() {
        Text(emoji)
          .fontSize(32)
          .fontColor(Theme.textPrimary)
        Text(label)
          .fontSize(12)
          .fontColor(Theme.textSecondary)
          .margin({ top: 6 })
      }
      .width(68).height(88)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(28)
      .backgroundColor('#FFFFFF')
    }
    .width(72).height(92)
    .borderRadius(28)
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [['#FFFFFF', 0.0], ['#D0D5DD', 1.0]]
    })
    .clip(false)
    .shadow({ radius: 16, color: '#ABB3C0', offsetX: 0, offsetY: 4 })
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: targetPage });
    })
  }

  @Builder
  HomeContent() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Scroll() {
        Column() {
          Row() {
            Stack({ alignContent: Alignment.TopStart }) {
              Column() {
                Text(`你好，${this.userInfo.name}`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.textPrimary)
                Text(`${this.userInfo.college} · ${this.userInfo.major}`)
                  .fontSize(13)
                  .fontColor(Theme.textTertiary)
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .backgroundColor('#FFFFFF')
              .borderRadius(28)
              .padding({ left: 28, right: 24, top: 16, bottom: 14 })
              .margin({ right: 4, bottom: 4 })
            }
            .height(73)
            .backgroundColor('#C8CFDA')
            .borderRadius(28)
            .linearGradient({
              direction: GradientDirection.RightBottom,
              colors: [['#FFFFFF', 0.0], ['#D0D5DD', 1.0]]
            })
            .clip(false)
            .shadow({ radius: 16, color: '#ABB3C0', offsetX: 0, offsetY: 4 })

            Blank()

            Stack({ alignContent: Alignment.Center }) {
              if (this.userInfo.avatar.length > 0) {
                Image(`${ApiService.baseUrl}${this.userInfo.avatar}`)
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .objectFit(ImageFit.Cover)
              } else {
                Text(this.userInfo.name.length > 0 ? this.userInfo.name[0] : 'U')
                  .fontSize(20)
                  .fontColor(Color.White)
                  .textAlign(TextAlign.Center)
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .backgroundColor(Theme.primary)
              }
            }
            .width(56).height(56)
            .borderRadius(28)
            .linearGradient({
              direction: GradientDirection.RightBottom,
              colors: [['#FFFFFF', 0.0], ['#D0D5DD', 1.0]]
            })
            .clip(false)
            .shadow({ radius: 16, color: '#ABB3C0', offsetX: 0, offsetY: 4 })
            .margin({ right: 12 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ left: 16, right: 16 })
          .margin({ top: 12, bottom: 20 })

          Row() {
            this.QuickEntry('📅', '课表', 'pages/SchedulePage')
            this.QuickEntry('🏫', '空教室', 'pages/EmptyRoomPage')
            this.QuickEntry('🎉', '活动', 'pages/ClubActivityListPage')
            this.QuickEntry('🔍', '招领', 'pages/LostFoundListPage')
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 20 })
          .justifyContent(FlexAlign.SpaceAround)

          Column() {
            Column() {
              Text('今日课程')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
                .width('100%')
                .padding({ left: 16, top: 4, bottom: 4 })

              this.TodaySchedule()
            }
            .width('100%')

            Blank().height(12)

            Column() {
              Text('我的活动')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
                .width('100%')
                .padding({ left: 16, top: 4, bottom: 4 })

              this.MyActivitiesList()
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })

          Column() {
            Row() {
              Text('校园公告')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
              Blank()
              Text('更多 >')
                .fontSize(13)
                .fontColor(Theme.textTertiary)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 12 })

            ForEach(this.announcements, (item: Announcement) => {
              Row() {
                Column() {
                  Text(item.title)
                    .fontSize(15)
                    .fontColor(Theme.textPrimary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.summary)
                    .fontSize(12)
                    .fontColor(Theme.textTertiary)
                    .margin({ top: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Column() {
                  Text(item.category)
                    .fontSize(11)
                    .fontColor(Theme.primary)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .backgroundColor(Theme.primaryLight)
                }
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .backgroundColor(Color.White)
              .shadow(ShadowStyle.sm)
            }, (item: Announcement) => `${item.id}`)
          }
          .width('100%')
          .padding({ top: 16 })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .onRefreshing(() => {
      this.loadAllData();
    })
  }

  @Builder
  TodaySchedule() {
    if (this.todayCourses.length === 0) {
      Column() {
        Text('今天没有课程')
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .padding({ left: 16, top: 8, bottom: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    } else {
      ForEach(this.todayCourses, (item: CourseSchedule) => {
        Stack({ alignContent: Alignment.TopStart }) {
          Row() {
            Column() {
              Text(Constants.SECTION_TIMES[item.startSection - 1][0])
                .fontSize(11)
                .fontColor(Theme.textTertiary)
            }
            .width(36)
            .alignItems(HorizontalAlign.Center)

            Column() {
              Row()
                .width(3)
                .height('100%')
                .backgroundColor(Constants.SCHEDULE_COLORS[item.colorIndex % Constants.SCHEDULE_COLORS.length])
                .borderRadius(2)
            }
            .height(40)

            Blank().width(6)

            Column() {
              Text(item.courseName)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.classroom.length > 0 ? item.classroom : '未定')
                .fontSize(11)
                .fontColor(Theme.textTertiary)
                .margin({ top: 2 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .alignItems(VerticalAlign.Center)
          .margin({ right: 3, bottom: 3 })
        }
        .width('100%')
        .backgroundColor('#C8CFDA')
        .borderRadius(16)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [['#FFFFFF', 0.0], ['#D0D5DD', 1.0]]
        })
        .clip(false)
        .shadow({ radius: 10, color: '#ABB3C0', offsetX: 0, offsetY: 3 })
        .margin({ bottom: 4 })
        .onClick(() => {
          this.selectedCourse = item;
          this.showCourseDetail = true;
        })
      }, (item: CourseSchedule) => `${item.id}`)
    }
  }

  @Builder
  MyActivitiesList() {
    if (this.myActivities.length === 0) {
      Column() {
        Text('暂无活动')
          .fontSize(12)
          .fontColor(Theme.textTertiary)
          .padding({ left: 16, top: 8, bottom: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    } else {
      ForEach(this.myActivities, (act: ClubActivityItem) => {
        Stack({ alignContent: Alignment.TopStart }) {
          Row() {
            Blank().width(36)

            Column() {
              Row()
                .width(3)
                .height('100%')
                .backgroundColor(Constants.SCHEDULE_COLORS[0])
                .borderRadius(2)
            }
            .height(40)

            Blank().width(6)

            Column() {
              Row() {
                Text(act.title)
                  .fontSize(13)
                  .fontColor(Theme.textPrimary)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                Text(act.activityTime.length > 0 ? act.activityTime : '')
                  .fontSize(11)
                  .fontColor(Theme.textTertiary)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              Text(act.venue.length > 0 ? act.venue : '')
                .fontSize(11)
                .fontColor(Theme.textTertiary)
                .width('100%')
                .margin({ top: 2 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .alignItems(VerticalAlign.Center)
          .margin({ right: 3, bottom: 3 })
        }
        .width('100%')
        .backgroundColor('#C8CFDA')
        .borderRadius(16)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [['#FFFFFF', 0.0], ['#D0D5DD', 1.0]]
        })
        .clip(false)
        .shadow({ radius: 10, color: '#ABB3C0', offsetX: 0, offsetY: 3 })
        .margin({ bottom: 4 })
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/ClubActivityDetailPage',
            params: { 'id': `${act.id}` } as Record<string, string>
          });
        })
      }, (act: ClubActivityItem) => `${act.id}`)
    }
  }

  private isCourseActiveInWeek(item: CourseSchedule, week: number): boolean {
    if (item.startWeek > week || item.endWeek < week) {
      return false;
    }
    if (item.weekParity === 'odd') {
      return week % 2 === 1;
    }
    if (item.weekParity === 'even') {
      return week % 2 === 0;
    }
    return true;
  }

  private semesterTitle(): string {
    return this.semesterName.length > 0 ? this.semesterName : '当前学期';
  }

  private weekDate(dayIndex: number): Date | null {
    const semesterDate: Date | null = semesterWeekDate(this.semesterStartDate, this.currentWeek, dayIndex);
    if (semesterDate !== null) {
      return semesterDate;
    }
    const parts: string[] = this.semesterStartDate.split('-');
    if (parts.length < 3) {
      return null;
    }
    const date: Date = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
    const dow: number = date.getDay();
    const offsetToMonday: number = dow === 0 ? -6 : 1 - dow;
    date.setDate(date.getDate() + offsetToMonday + (this.currentWeek - 1) * 7 + dayIndex);
    return date;
  }

  private todayDayIndex(): number {
    const day: number = new Date().getDay();
    return day === 0 ? 6 : day - 1;
  }

  private weekMonthText(): string {
    const date: Date | null = this.weekDate(0);
    if (date === null) {
      return '';
    }
    return `${date.getMonth() + 1}月`;
  }

  private weekDayText(dayIndex: number): string {
    const date: Date | null = this.weekDate(dayIndex);
    if (date === null) {
      return `${dayIndex + 1}`;
    }
    return `${date.getDate()}`;
  }

  private courseAtStart(day: number, section: number): CourseSchedule {
    for (let i = 0; i < this.scheduleList.length; i++) {
      const item: CourseSchedule = this.scheduleList[i];
      if (item.dayOfWeek === day && item.startSection === section && this.isCourseActiveInWeek(item, this.currentWeek)) {
        return item;
      }
    }
    return new CourseSchedule();
  }

  private hasCourseCovering(day: number, section: number): boolean {
    for (let i = 0; i < this.scheduleList.length; i++) {
      const item: CourseSchedule = this.scheduleList[i];
      if (item.dayOfWeek === day && item.startSection < section && item.endSection >= section && this.isCourseActiveInWeek(item, this.currentWeek)) {
        return true;
      }
    }
    return false;
  }

  private courseDuration(item: CourseSchedule): number {
    const duration: number = item.endSection - item.startSection + 1;
    return duration > 0 ? duration : 1;
  }

  private courseBg(item: CourseSchedule): string {
    if (item.source === 'personal') {
      return Theme.personalCardBg[Math.abs(item.colorIndex) % Theme.personalCardBg.length];
    }
    return Theme.scheduleCardBg[Math.abs(item.colorIndex) % Theme.scheduleCardBg.length];
  }

  private courseFg(item: CourseSchedule): string {
    if (item.source === 'personal') {
      return Theme.personalCardFg[Math.abs(item.colorIndex) % Theme.personalCardFg.length];
    }
    return Theme.scheduleCardFg[Math.abs(item.colorIndex) % Theme.scheduleCardFg.length];
  }

  private sectionStartTime(section: number): string {
    if (section >= 1 && section <= Constants.SECTION_TIMES.length) {
      return Constants.SECTION_TIMES[section - 1][0];
    }
    return '';
  }

  private sectionEndTime(section: number): string {
    if (section >= 1 && section <= Constants.SECTION_TIMES.length) {
      return Constants.SECTION_TIMES[section - 1][1];
    }
    return '';
  }

  private courseTimeText(item: CourseSchedule): string {
    return `${this.sectionStartTime(item.startSection)}-${this.sectionEndTime(item.endSection)}`;
  }

  private courseWeekText(item: CourseSchedule): string {
    let text: string = `第${item.startWeek}-${item.endWeek}周`;
    if (item.weekParity === 'odd') {
      text += ' 单周';
    }
    if (item.weekParity === 'even') {
      text += ' 双周';
    }
    return text;
  }

  private courseBriefText(item: CourseSchedule): string {
    const room: string = item.classroom.length > 0 ? item.classroom : '教室未填';
    if (item.teacherName.length > 0) {
      return `${item.courseName} @${room}\n${item.teacherName}`;
    }
    return `${item.courseName} @${room}`;
  }

  private showWeekPicker(): void {
    const weeks: string[] = [];
    for (let i = 1; i <= this.semesterWeekCount; i++) {
      weeks.push(`第${i}周`);
    }
    let currentIdx: number = this.currentWeek - 1;
    TextPickerDialog.show({
      range: weeks,
      selected: currentIdx,
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < weeks.length) {
          this.currentWeek = idx + 1;
          this.updateScheduleGrid();
        }
      }
    });
  }

  private backToCurrentWeek(): void {
    this.currentWeek = this.todayWeek;
    this.updateScheduleGrid();
  }

  private openCourseDetail(item: CourseSchedule): void {
    this.selectedCourse = item;
    this.showCourseDetail = true;
  }

  private closeCourseDetail(): void {
    this.showCourseDetail = false;
    this.selectedCourse = new CourseSchedule();
  }

  private showAddCourse(): void {
    router.pushUrl({
      url: 'pages/AddCoursePage',
      params: {
        semesterWeekCount: this.semesterWeekCount,
        semesterTitle: this.semesterTitle()
      }
    }).catch((err: Error) => {
      console.error('[AddCourse] navigate failed:', err.message);
      this.getUIContext().getPromptAction().showToast({ message: '打开添课页失败，请重新编译' });
    });
  }

  private hideAddCourse(): void {
    this.showAddCourseForm = false;
  }

  private showAddDayPicker(): void {
    let currentIdx: number = this.addDayOfWeek - 1;
    TextPickerDialog.show({
      range: WEEK_DAY_LABELS,
      selected: currentIdx,
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < WEEK_DAY_LABELS.length) {
          this.addDayOfWeek = idx + 1;
        }
      }
    });
  }

  private showAddStartSectionPicker(): void {
    const options: string[] = [];
    for (let i = 1; i <= Constants.SECTION_TIMES.length; i++) {
      options.push(`第${i}节 ${this.sectionStartTime(i)}-${this.sectionEndTime(i)}`);
    }
    TextPickerDialog.show({
      range: options,
      selected: this.addStartSection - 1,
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.addStartSection = idx + 1;
          if (this.addEndSection < this.addStartSection) {
            this.addEndSection = this.addStartSection;
          }
        }
      }
    });
  }

  private showAddEndSectionPicker(): void {
    const options: string[] = [];
    for (let i = 1; i <= Constants.SECTION_TIMES.length; i++) {
      options.push(`第${i}节 ${this.sectionStartTime(i)}-${this.sectionEndTime(i)}`);
    }
    TextPickerDialog.show({
      range: options,
      selected: this.addEndSection - 1,
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.addEndSection = idx + 1;
          if (this.addEndSection < this.addStartSection) {
            this.addStartSection = this.addEndSection;
          }
        }
      }
    });
  }

  private showAddStartWeekPicker(): void {
    const options: string[] = [];
    for (let i = 1; i <= this.semesterWeekCount; i++) {
      options.push(`第${i}周`);
    }
    TextPickerDialog.show({
      range: options,
      selected: this.addStartWeek - 1,
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.addStartWeek = idx + 1;
          if (this.addEndWeek < this.addStartWeek) {
            this.addEndWeek = this.addStartWeek;
          }
        }
      }
    });
  }

  private showAddEndWeekPicker(): void {
    const options: string[] = [];
    for (let i = 1; i <= this.semesterWeekCount; i++) {
      options.push(`第${i}周`);
    }
    TextPickerDialog.show({
      range: options,
      selected: this.addEndWeek - 1,
      onAccept: (value: TextPickerResult) => {
        const idx: number = value.index as number;
        if (idx >= 0 && idx < options.length) {
          this.addEndWeek = idx + 1;
          if (this.addEndWeek < this.addStartWeek) {
            this.addStartWeek = this.addEndWeek;
          }
        }
      }
    });
  }

  private async saveManualCourse(): Promise<void> {
    if (this.addCourseName.trim().length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入课程名称' });
      return;
    }
    const store: AppStore = AppStore.getInstance();
    if (!store.isLoggedIn) {
      this.getUIContext().getPromptAction().showToast({ message: '请先登录' });
      return;
    }
    const params: Record<string, Object> = {
      'semesterId': this.semesterId,
      'courseName': this.addCourseName.trim(),
      'classroom': this.addClassroom.trim(),
      'teacher': this.addTeacherName.trim(),
      'dayOfWeek': this.addDayOfWeek,
      'startSection': this.addStartSection,
      'endSection': this.addEndSection,
      'startWeek': this.addStartWeek,
      'endWeek': this.addEndWeek
    } as Record<string, Object>;
    const result: ApiResult = await ApiService.addPersonalCourse(params);
    if (result.code === 200) {
      this.showAddCourseForm = false;
      this.getUIContext().getPromptAction().showToast({ message: '课程已添加' });
      this.loadSchedule();
    } else {
      this.getUIContext().getPromptAction().showToast({ message: result.msg.length > 0 ? result.msg : '添加失败' });
    }
  }

  @Builder
  ScheduleContent() {
    Stack() {
      if (this.showAddCourseForm) {
        this.AddCourseContent()
      } else {
        Column() {
          this.ScheduleHeader()
          this.ScheduleWeekHeader()
          this.ScheduleGrid()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')

        if (this.currentWeek !== this.todayWeek) {
          Button('切回本周')
            .width(88)
            .height(42)
            .fontSize(15)
            .fontColor(Color.White)
            .backgroundColor(Theme.primary)
            .borderRadius(24)
            .padding({ left: 24, right: 24 })
            .position({ x: 292, y: 610 })
            .onClick(() => {
              this.backToCurrentWeek();
            })
        }

        if (this.showCourseDetail) {
          this.CourseDetailOverlay()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ScheduleHeader() {
    Row() {
      Column() {
        Row() {
          Text(`第${this.currentWeek}周`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.danger)
          Text('▼')
            .fontSize(16)
            .fontColor(Theme.textPrimary)
            .margin({ left: 8 })
        }
        .onClick(() => {
          this.showWeekPicker();
        })
        Text(this.semesterTitle())
          .fontSize(14)
          .fontColor(Theme.textTertiary)
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('+')
        .fontSize(30)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor(Theme.primary)
        .borderRadius(10)
        .onClick(() => {
          this.showAddCourse();
        })
    }
    .width('100%')
    .height(58)
    .padding({ left: 12, right: 14, top: 2, bottom: 2 })
    .backgroundColor(Color.White)
  }

  @Builder
  ScheduleWeekHeader() {
    Row() {
      Column() {
        Text(this.weekMonthText().length > 0 ? this.weekMonthText().replace('月', '') : '')
          .fontSize(17)
          .fontColor(Theme.textPrimary)
        Text('月')
          .fontSize(17)
          .fontColor(Theme.textPrimary)
          .margin({ top: 2 })
      }
      .width(50)
      .alignItems(HorizontalAlign.Center)

      ForEach(WEEK_DAY_LABELS, (day: string, index: number) => {
        Column() {
          Text(day)
            .fontSize(19)
            .fontColor(Theme.textPrimary)
          Text(this.weekDayText(index))
            .fontSize(15)
            .fontColor(Theme.textTertiary)
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .height(58)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }, (day: string, index: number) => `${index}-${day}`)
    }
    .width('100%')
    .height(60)
    .border({ width: 1, color: Theme.border })
    .backgroundColor(Color.White)
  }

  @Builder
  ScheduleGrid() {
    Scroll() {
      Row() {
        Column() {
          ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (section: number) => {
            Column() {
              Text(`${section}`)
                .fontSize(18)
                .fontColor(Theme.textPrimary)
              Text(this.sectionStartTime(section))
                .fontSize(11)
                .fontColor(Theme.textTertiary)
                .margin({ top: 3 })
              Text(this.sectionEndTime(section))
                .fontSize(11)
                .fontColor(Theme.textTertiary)
                .margin({ top: 1 })
            }
            .width(50)
            .height(SCHEDULE_SECTION_HEIGHT)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }, (section: number) => `${section}`)
        }
        .width(50)

        Row() {
          ForEach([1, 2, 3, 4, 5, 6, 7], (day: number) => {
            Column() {
              ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (section: number) => {
                Stack() {
                  Divider()
                    .height(1)
                    .color(Theme.border)
                    .width('100%')
                    .position({ x: 0, y: SCHEDULE_SECTION_HEIGHT - 1 })
                  if (!this.hasCourseCovering(day, section)) {
                    this.ScheduleCell(day, section)
                  }
                }
                .width('100%')
                .height(SCHEDULE_SECTION_HEIGHT)
              }, (section: number) => `${day}-${section}`)
            }
            .layoutWeight(1)
          }, (day: number) => `${day}`)
        }
        .layoutWeight(1)
        .padding({ right: 6 })
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  ScheduleCell(day: number, section: number) {
    Column() {
      if (this.courseAtStart(day, section).courseName.length > 0) {
        this.ScheduleCourseCard(this.courseAtStart(day, section))
      }
    }
    .width('100%')
    .height(SCHEDULE_SECTION_HEIGHT)
  }

  @Builder
  ScheduleCourseCard(item: CourseSchedule) {
    Column() {
      Text(this.courseBriefText(item))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.courseFg(item))
        .lineHeight(18)
        .maxLines(this.courseDuration(item) <= 1 ? 2 : 5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('92%')
    .height(this.courseDuration(item) * SCHEDULE_SECTION_HEIGHT - 8)
    .padding({ left: 7, right: 5, top: 8, bottom: 6 })
    .backgroundColor(this.courseBg(item))
    .border({ width: 1, color: this.courseFg(item) })
    .borderRadius(8)
    .margin({ left: 3, right: 3, top: 4 })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.openCourseDetail(item);
    })
  }

  @Builder
  CourseDetailOverlay() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(255,255,255,0.87)')
        .onClick(() => {
          this.closeCourseDetail();
        })

      Column() {
        this.CourseDetailCard(this.selectedCourse, false)
        if (this.selectedCourse.weekParity !== 'all') {
          this.CourseDetailCard(this.selectedCourse, true)
        }
      }
      .width('90%')
      .position({ x: 20, y: 245 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CourseDetailCard(item: CourseSchedule, parityCard: boolean) {
    Column() {
      Row() {
        if (parityCard) {
          Text('非本周')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor(Theme.textPrimary)
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ right: 8 })
        }
        Text(item.courseName.length > 0 ? item.courseName : '课程名称未录入')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.textPrimary)
          .layoutWeight(1)
        if (item.source === 'personal') {
          Text('个人')
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor(Theme.danger)
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ left: 4 })
        }
        if (item.source === 'personal') {
          Text('删除')
            .fontSize(15)
            .fontColor(Theme.danger)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(Color.White)
            .borderRadius(5)
            .onClick(async () => {
              const result: ApiResult = await ApiService.deletePersonalCourse(item.id);
              if (result.code === 200) {
                this.getUIContext().getPromptAction().showToast({ message: '已删除' });
                this.showCourseDetail = false;
                this.loadSchedule();
              } else {
                this.getUIContext().getPromptAction().showToast({ message: result.msg.length > 0 ? result.msg : '删除失败' });
              }
            })
        } else {
          Text('编辑')
            .fontSize(15)
            .fontColor(Theme.textTertiary)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(Color.White)
            .borderRadius(5)
        }
      }
      .width('100%')

      Text(this.courseWeekText(item))
        .fontSize(17)
        .fontColor(Theme.textPrimary)
        .width('100%')
        .margin({ top: 18 })
      Text(`周${WEEK_DAY_LABELS[item.dayOfWeek - 1]} | 第${item.startSection}-${item.endSection}节 | ${this.courseTimeText(item)}`)
        .fontSize(15)
        .fontColor(Theme.textTertiary)
        .width('100%')
        .margin({ top: 12 })
      Text(`教室：${item.classroom.length > 0 ? item.classroom : '未填写'}`)
        .fontSize(15)
        .fontColor(Theme.textTertiary)
        .width('100%')
        .margin({ top: 12 })
      Text(`老师：${item.teacherName.length > 0 ? item.teacherName : '未填写'}`)
        .fontSize(15)
        .fontColor(Theme.textTertiary)
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(24)
    .backgroundColor(Theme.bgPage)
    .borderRadius(14)
    .shadow(ShadowStyle.md)
    .margin({ bottom: 18 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  AddCourseContent() {
    Column() {
      Row() {
        Text('<')
          .fontSize(30)
          .fontColor(Theme.textPrimary)
          .width(50)
          .onClick(() => {
            this.hideAddCourse();
          })
        Text('添加课程')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('保存')
          .fontSize(16)
          .fontColor(Theme.primary)
          .width(50)
          .textAlign(TextAlign.End)
          .onClick(() => {
            this.saveManualCourse();
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 18, right: 18 })
      .border({ width: 1, color: Theme.border })

      Scroll() {
        Column() {
          Row() {
            Column() {
              Text('当前学期为')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.primary)
              Text('返回课程表页面即可切换学期')
                .fontSize(14)
                .fontColor(Theme.primary)
                .margin({ top: 12 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text(this.semesterTitle())
              .fontSize(18)
              .fontColor(Theme.primary)
          }
          .width('100%')
          .padding(20)
          .backgroundColor(Theme.primaryLight)
          .borderRadius(3)
          .margin({ top: 8, bottom: 18 })

          this.AddInputRow('课程名称', '请输入添加的课程名称', this.addCourseName, 1)
          this.AddSelectRow('课程周期', `第${this.addStartWeek}-${this.addEndWeek}周`, 1)
          this.AddSelectRow('课程节数', `周${WEEK_DAY_LABELS[this.addDayOfWeek - 1]} 第${this.addStartSection}-${this.addEndSection}节`, 2)
          this.AddInputRow('教室地点', '请输入教室地点', this.addClassroom, 2)
          this.AddInputRow('任课老师', '请输入任课老师', this.addTeacherName, 3)

          Button('如果有多个上课时间，点此增加上课时间  +')
            .width('100%')
            .height(58)
            .fontSize(17)
            .fontColor(Theme.primary)
            .backgroundColor(Theme.primaryLight)
            .borderRadius(8)
            .margin({ top: 34 })
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: '当前版本先支持一个上课时间' });
            })
        }
        .width('100%')
        .padding({ left: 28, right: 28, bottom: 30 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  AddInputRow(label: string, placeholder: string, value: string, type: number) {
    Row() {
      Text(label)
        .fontSize(19)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.textPrimary)
        .width(104)
      TextInput({ placeholder: placeholder, text: value })
        .layoutWeight(1)
        .height(52)
        .fontSize(16)
        .textAlign(TextAlign.End)
        .backgroundColor('#00000000')
        .placeholderColor(Theme.textDisabled)
        .onChange((val: string) => {
          if (type === 1) {
            this.addCourseName = val;
          }
          if (type === 2) {
            this.addClassroom = val;
          }
          if (type === 3) {
            this.addTeacherName = val;
          }
        })
    }
    .width('100%')
    .height(70)
    .border({ width: 1, color: Theme.border })
  }

  @Builder
  AddSelectRow(label: string, value: string, type: number) {
    Row() {
      Text(label)
        .fontSize(19)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.textPrimary)
        .width(104)
      Blank()
      Text(value)
        .fontSize(17)
        .fontColor(type === 2 ? Theme.danger : Theme.textSecondary)
      Text('>')
        .fontSize(24)
        .fontColor(Theme.textDisabled)
        .margin({ left: 10 })
    }
    .width('100%')
    .height(70)
    .border({ width: 1, color: Theme.border })
    .onClick(() => {
      if (type === 1) {
        this.showAddStartWeekPicker();
        setTimeout(() => {
          this.showAddEndWeekPicker();
        }, 400);
      }
      if (type === 2) {
        this.showAddDayPicker();
        setTimeout(() => {
          this.showAddStartSectionPicker();
        }, 400);
        setTimeout(() => {
          this.showAddEndSectionPicker();
        }, 800);
      }
    })
  }

  @State searchKeyword: string = '';
  @State searchSuggestions: string[] = [];
  @State showSuggestions: boolean = false;

  @State marketRefreshing: boolean = false;

  private async refreshMarket(): Promise<void> {
    this.marketRefreshing = true;
    await this.loadProducts();
    this.marketRefreshing = false;
  }

  @Builder
  ProductCard(item: Product) {
    Column() {
      if (item.images.length > 0) {
        Image(`${ApiService.baseUrl}${item.images[0]}`)
          .width('100%')
          .aspectRatio(1)
          .borderRadius({ topLeft: 18, topRight: 18 })
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('暂无图片')
            .fontSize(13)
            .fontColor(Theme.textTertiary)
        }
        .width('100%')
        .aspectRatio(1)
        .backgroundColor(Theme.bgInput)
        .borderRadius({ topLeft: 18, topRight: 18 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      Column() {
        Text(item.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.textPrimary)
          .maxLines(2)
          .lineHeight(18)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text(`¥${item.price}`)
            .fontSize(16)
            .fontColor(Theme.primary)
            .fontWeight(FontWeight.Bold)
          if (item.originalPrice > 0) {
            Text(`¥${item.originalPrice}`)
              .fontSize(10)
              .fontColor(Theme.textDisabled)
              .decoration({ type: TextDecorationType.LineThrough })
              .margin({ left: 4 })
          }
        }
        .margin({ top: 6 })
        if (item.campusLocation.length > 0) {
          Text(item.campusLocation)
            .fontSize(10)
            .fontColor(Theme.textTertiary)
            .margin({ top: 4 })
        }
      }
      .padding({ left: 10, right: 10, top: 9, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .backgroundColor(Theme.bgCard)
    .borderRadius(18)
    .shadow(ShadowStyle.nmRaised)
    .onClick(() => {
      const detailParams: Record<string, Object> = {
        'productId': item.id
      } as Record<string, Object>;
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/ProductDetailPage',
        params: detailParams
      });
    })
  }

  @Builder
  MarketContent() {
    Refresh({ refreshing: $$this.marketRefreshing }) {
      Column() {
        Row() {
          Text('二手交易')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textPrimary)
          Blank()
          Text('+ 发布')
            .fontSize(14)
            .fontColor(Theme.primary)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/PublishPage' });
            })
          Blank().width(16)
          Stack() {
            Text('💬')
              .fontSize(20)
            if (this.unreadCount > 0) {
              Text(this.unreadCount > 99 ? '99+' : `${this.unreadCount}`)
                .fontSize(9)
                .fontColor(Color.White)
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .borderRadius(10)
                .backgroundColor(Theme.danger)
                .position({ x: 14, y: -4 })
            }
          }
          .width(28)
          .height(28)
          .onClick(() => {
            this.unreadCount = 0;
            this.currentTab = 2;
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 18, bottom: 12 })

        Stack() {
          TextInput({ placeholder: '搜索商品...', text: this.searchKeyword })
            .fontSize(14)
            .height(40)
            .borderRadius(20)
            .backgroundColor(Theme.bgCard)
            .padding({ left: 16, right: 16 })
            .shadow(ShadowStyle.sm)
            .onChange((v: string) => {
              this.searchKeyword = v;
              this.loadSearchSuggestions(v);
            })
            .onSubmit(() => {
              this.searchProducts();
            })
          if (this.showSuggestions && this.searchSuggestions.length > 0) {
            Column() {
              ForEach(this.searchSuggestions, (suggestion: string) => {
                Row() {
                  Text(suggestion)
                    .fontSize(14)
                    .fontColor(Theme.textPrimary)
                    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                }
                .width('100%')
                .onClick(() => {
                  this.searchKeyword = suggestion;
                  this.showSuggestions = false;
                  this.searchProducts();
                })
              }, (suggestion: string, index: number) => `${index}`)
            }
            .width('92%')
            .backgroundColor(Theme.bgCard)
            .borderRadius(14)
            .shadow(ShadowStyle.md)
            .position({ y: 42 })
            .zIndex(10)
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 4 })

        Scroll() {
          Row({ space: 8 }) {
            Text('全部')
              .fontSize(13)
              .fontColor(this.selectedCategoryId === 0 ? Theme.primary : Theme.textSecondary)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16)
              .backgroundColor(this.selectedCategoryId === 0 ? Theme.primaryLight : Theme.bgCard)
              .shadow(ShadowStyle.sm)
              .onClick(() => {
                this.selectedCategoryId = 0;
                this.loadProducts();
              })
            ForEach(this.categories, (cat: ProductCategory) => {
              Text(cat.name)
                .fontSize(13)
                .fontColor(this.selectedCategoryId === cat.id ? Theme.primary : Theme.textSecondary)
                .padding({ left: cat.parentId === 0 ? 12 : 8, right: cat.parentId === 0 ? 12 : 8, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.selectedCategoryId === cat.id ? Theme.primaryLight : Theme.bgCard)
                .shadow(ShadowStyle.sm)
                .onClick(() => {
                  this.selectedCategoryId = cat.id;
                  this.loadProducts();
                })
            }, (cat: ProductCategory) => `${cat.id}`)
          }
          .padding({ left: 20, right: 20, bottom: 12 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        Scroll() {
          Row({ space: 8 }) {
            Column({ space: 8 }) {
              ForEach(this.products.filter((_v: Product, i: number) => i % 2 === 0), (item: Product) => {
                this.ProductCard(item)
              }, (item: Product, _index: number) => `l-${item.id}`)
            }
            .layoutWeight(1)

            Column({ space: 8 }) {
              ForEach(this.products.filter((_v: Product, i: number) => i % 2 === 1), (item: Product) => {
                this.ProductCard(item)
              }, (item: Product, _index: number) => `r-${item.id}`)
            }
            .layoutWeight(1)
            .margin({ top: 24 })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 4, bottom: 86 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.bgPage)
    }
    .onRefreshing(() => {
      this.refreshMarket();
    })
    .backgroundColor(Theme.bgPage)
    .width('100%')
    .height('100%')
  }

  private cleanMarkdown(md: string): string {
    let text: string = md;
    text = text.replace(new RegExp('###\\s+', 'g'), '');
    text = text.replace(new RegExp('##\\s+', 'g'), '');
    text = text.replace(new RegExp('#\\s+', 'g'), '');
    text = text.replace(new RegExp('\\*\\*(.+?)\\*\\*', 'g'), '$1');
    return text;
  }

  private sendAiMessage(): void {
    const text: string = this.aiInputText.trim();
    if (text.length === 0 || this.aiIsLoading) {
      return;
    }
    const userMsg: AiMsg = new AiMsg();
    userMsg.role = 'user';
    userMsg.content = text;
    this.aiMessages.push(userMsg);
    this.aiInputText = '';
    this.aiIsLoading = true;
    this.aiStreamingIndex = this.aiMessages.length;
    this.aiStreamText = '';
    this.aiThinking = false;

    const aiMsg: AiMsg = new AiMsg();
    aiMsg.role = 'assistant';
    aiMsg.content = '';
    this.aiMessages.push(aiMsg);
    this.aiMessages = [...this.aiMessages];

    setTimeout(() => {
      this.aiScroller.scrollEdge(Edge.Bottom);
    }, 50);

    const sIdx: number = this.aiStreamingIndex;

    const baseUrl: string = `${ApiService.baseUrl.substring(0, ApiService.baseUrl.lastIndexOf(':'))}:8000`;
    const url: string = `${baseUrl}/api/ai/chat`;
    const req: http.HttpRequest = http.createHttp();
    this.aiHttpRequest = req;
    let sseBuffer: string = '';

    this.aiPendingText = '';
    this.aiFlushTimer = setInterval(() => {
      if (this.aiPendingText.length > 0) {
        this.aiStreamText += this.aiPendingText;
        this.aiPendingText = '';
        this.aiScroller.scrollEdge(Edge.Bottom);
      }
    }, 80);

    req.on('dataReceive', (data: ArrayBuffer) => {
      const chunk: string = this.textDecoder.decodeToString(new Uint8Array(data));
      sseBuffer += chunk;
      const lines: string[] = sseBuffer.split('\n');
      sseBuffer = '';

      for (let i: number = 0; i < lines.length; i++) {
        const line: string = lines[i].trim();
        if (line.length === 0) {
          continue;
        }
        if (line === 'data: [DONE]') {
          continue;
        }
        if (line.startsWith('data: ')) {
          const jsonStr: string = line.substring(6);
          try {
            const parsed: Record<string, string> = JSON.parse(jsonStr) as Record<string, string>;
            if (parsed['error'] !== undefined) {
              this.aiStreamText = 'AI 服务出错: ' + parsed['error'];
              this.aiScroller.scrollEdge(Edge.Bottom);
            } else if (parsed['status'] === 'thinking') {
              this.aiThinking = true;
              this.aiScroller.scrollEdge(Edge.Bottom);
            } else {
              const content: string = parsed['content'] ?? '';
              if (content.length > 0) {
                this.aiThinking = false;
                this.aiPendingText += content;
              }
            }
          } catch (_e) {
          }
        } else if (!line.startsWith('data:')) {
          sseBuffer = line;
        }
      }
    });

    req.on('dataEnd', () => {
      if (this.aiFlushTimer !== -1) {
        clearInterval(this.aiFlushTimer);
        this.aiFlushTimer = -1;
      }
      if (this.aiPendingText.length > 0) {
        this.aiStreamText += this.aiPendingText;
        this.aiPendingText = '';
      }
      const finalText: string = this.aiStreamText.length > 0 ? this.aiStreamText : '抱歉，AI 服务未返回内容';
      this.aiMessages[sIdx].content = finalText;
      this.aiMessages = [...this.aiMessages];
      this.aiStreamingIndex = -1;
      this.aiIsLoading = false;
      this.aiThinking = false;
      this.aiStreamText = '';
      req.off('dataReceive');
      req.off('dataEnd');
      req.destroy();
      this.aiHttpRequest = null;
      this.aiScroller.scrollEdge(Edge.Bottom);
    });

    req.requestInStream(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream'
      },
      extraData: JSON.stringify({ 'question': text } as Record<string, string>),
      readTimeout: 120000,
      connectTimeout: 15000
    }, (err: BusinessError, data: number) => {
      if (err) {
        if (this.aiFlushTimer !== -1) {
          clearInterval(this.aiFlushTimer);
          this.aiFlushTimer = -1;
        }
        this.aiMessages[sIdx].content = '网络错误，无法连接 AI 服务';
        this.aiMessages = [...this.aiMessages];
        this.aiStreamingIndex = -1;
        this.aiIsLoading = false;
        this.aiThinking = false;
        this.aiStreamText = '';
        this.aiPendingText = '';
        req.off('dataReceive');
        req.off('dataEnd');
        req.destroy();
        this.aiHttpRequest = null;
      }
    });
  }

  @Builder
  AIChatContent() {
    Column() {
      Row() {
        Text('AI 校园助手')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.textPrimary)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      List({ space: 12, scroller: this.aiScroller }) {
        ForEach(this.aiMessages, (msg: AiMsg, index: number) => {
          ListItem() {
            Row() {
              if (msg.role === 'user') {
                Blank()
                Column() {
                  Text(msg.content)
                    .fontSize(15)
                    .fontColor(Color.White)
                    .lineHeight(22)
                }
                .padding(12)
                .backgroundColor(Theme.primary)
                .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
                .constraintSize({ maxWidth: '75%' })
              } else {
                Column() {
                  if (this.aiThinking && index === this.aiStreamingIndex) {
                    Row({ space: 4 }) {
                      LoadingProgress()
                        .width(16)
                        .height(16)
                        .color(Theme.primary)
                      Text('正在检索知识库...')
                        .fontSize(14)
                        .fontColor(Theme.textTertiary)
                    }
                  } else if (index === this.aiStreamingIndex && this.aiIsLoading) {
                    if (this.aiStreamText.length > 0) {
                      Text(this.cleanMarkdown(this.aiStreamText))
                        .fontSize(15)
                        .fontColor(Theme.textPrimary)
                        .lineHeight(22)
                      Text('▍')
                        .fontSize(15)
                        .fontColor(Theme.primary)
                    } else {
                      Row({ space: 4 }) {
                        LoadingProgress()
                          .width(16)
                          .height(16)
                          .color(Theme.primary)
                        Text('思考中...')
                          .fontSize(14)
                          .fontColor(Theme.textTertiary)
                      }
                    }
                  } else if (msg.content.length > 0) {
                    Text(this.cleanMarkdown(msg.content))
                      .fontSize(15)
                      .fontColor(Theme.textPrimary)
                      .lineHeight(22)
                  }
                }
                .padding(12)
                .backgroundColor(Theme.border)
                .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
                .constraintSize({ maxWidth: '75%' })
                Blank()
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          }
        }, (msg: AiMsg, index: number) => `${index}`)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)

      Row() {
        TextInput({ placeholder: '输入你的问题...', text: this.aiInputText })
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .placeholderColor(Theme.textDisabled)
          .backgroundColor(Theme.bgInput)
          .borderRadius(22)
          .padding({ left: 16, right: 16 })
          .enabled(!this.aiIsLoading)
          .onChange((v: string) => { this.aiInputText = v; })
          .onSubmit(() => { this.sendAiMessage(); })
        Button('发送')
          .height(44)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(Theme.primary)
          .borderRadius(22)
          .margin({ left: 8 })
          .padding({ left: 16, right: 16 })
          .enabled(!this.aiIsLoading)
          .type(ButtonType.Capsule)
          .onClick(() => { this.sendAiMessage(); })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 24 })
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder
  MessageContent() {
    Column() {
      Row() {
        Text('消息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.textPrimary)
        Blank()
        Text('刷新')
          .fontSize(14)
          .fontColor(Theme.primary)
          .onClick(() => { this.loadConversations() })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      if (!AppStore.getInstance().isLoggedIn) {
        Column() {
          Text('请先登录')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textPrimary)
          Text('登录后可以查看买卖双方的会话')
            .fontSize(14)
            .fontColor(Theme.textSecondary)
            .margin({ top: 8 })
          Button('去登录')
            .type(ButtonType.Capsule)
            .backgroundColor(Theme.primary)
            .fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }) })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.conversationLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(Theme.primary)
          Text('正在加载会话')
            .fontSize(14)
            .fontColor(Theme.textSecondary)
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.conversationError.length > 0) {
        Column() {
          Text(this.conversationError)
            .fontSize(16)
            .fontColor(Theme.textSecondary)
          Button('重试')
            .type(ButtonType.Capsule)
            .backgroundColor(Theme.primary)
            .fontColor('#FFFFFF')
            .margin({ top: 18 })
            .onClick(() => { this.loadConversations() })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          TextInput({ placeholder: '搜索联系人或消息', text: this.conversationKeyword })
            .height(40)
            .fontSize(14)
            .backgroundColor(Theme.bgInput)
            .borderRadius(20)
            .margin({ left: 16, right: 16, top: 12, bottom: 12 })
            .onChange((value: string) => { this.conversationKeyword = value })

          if (this.conversations.length === 0) {
            Column() {
              Text('暂无会话')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
              Text('从商品详情页联系卖家后，会话会显示在这里')
                .fontSize(14)
                .fontColor(Theme.textSecondary)
                .margin({ top: 8 })
            }
            .width('100%')
            .padding({ top: 40, left: 16, right: 16 })
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.conversations, (item: Conversation) => {
                ListItem() {
                  if (this.shouldShowConversation(item)) {
                    Column() {
                      Row() {
                        Stack({ alignContent: Alignment.BottomEnd }) {
                          Text(item.otherUserName.length > 0 ? item.otherUserName.substring(0, 1) : '聊')
                            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                            .width(48).height(48).borderRadius(24)
                            .textAlign(TextAlign.Center)
                            .backgroundColor(Theme.primary)
                          if (this.isUserOnline(item.otherUserId)) {
                            Text('')
                              .width(11).height(11).borderRadius(6)
                              .backgroundColor(Theme.success)
                              .border({ width: 2, color: '#FFFFFF' })
                          }
                        }.width(50).height(50)

                        Column() {
                          Row() {
                            Text(item.otherUserName.length > 0 ? item.otherUserName : '用户')
                              .fontSize(16).fontWeight(FontWeight.Medium).fontColor(Theme.textPrimary)
                              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                              .layoutWeight(1)
                            Text(this.formatConvTime(item.lastTime))
                              .fontSize(12).fontColor(Theme.textTertiary)
                          }.width('100%')
                          Row() {
                            Text(this.previewConvText(item))
                              .fontSize(14).fontColor(item.unreadCount > 0 ? Theme.textPrimary : Theme.textTertiary)
                              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                              .layoutWeight(1)
                            if (item.unreadCount > 0) {
                              Text(item.unreadCount > 99 ? '99+' : item.unreadCount.toString())
                                .fontSize(11).fontColor('#FFFFFF').textAlign(TextAlign.Center)
                                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                                .borderRadius(10).backgroundColor(Theme.danger)
                                .margin({ left: 8 })
                            }
                          }.width('100%').margin({ top: 6 })
                        }.layoutWeight(1).margin({ left: 12 })
                      }
                      .width('100%')
                      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                      .backgroundColor('#FFFFFF')
                      .onClick(() => { this.goChat(item) })
                      Divider().height(1).color(Theme.divider).margin({ left: 78 })
                    }.width('100%')
                  }
                }
              }, (item: Conversation) => `${item.id}-${item.lastTime}-${item.unreadCount}-${item.lastMessage}`)
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('#FFFFFF')
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bgPage)
  }

  @Builder
  ProfileContent() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            if (this.userInfo.avatar.length > 0) {
              Image(`${ApiService.baseUrl}${this.userInfo.avatar}`)
                .width(72)
                .height(72)
                .borderRadius(36)
                .objectFit(ImageFit.Cover)
            } else {
              Text(this.userInfo.name.length > 0 ? this.userInfo.name[0] : 'U')
                .fontSize(30)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .width(72)
                .height(72)
                .borderRadius(36)
                .backgroundColor(Theme.primary)
            }
          }
          .padding(6)
          .backgroundColor(Theme.bgCard)
          .borderRadius(42)
          .shadow(ShadowStyle.nmRaised)

          Column() {
            Text(this.userInfo.name)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.textPrimary)
            Text(`学号：${this.userInfo.studentId}`)
              .fontSize(13)
              .fontColor(Theme.textTertiary)
              .margin({ top: 4 })
          }
          .margin({ left: 16 })
          .alignItems(HorizontalAlign.Start)
          Blank()
          Button('编辑资料')
            .height(38)
            .fontSize(13)
            .fontColor(Theme.primary)
            .backgroundColor(Theme.bgCard)
            .borderRadius(19)
            .padding({ left: 16, right: 16 })
            .shadow(ShadowStyle.sm)
            .onClick(() => {
              this.openEditProfilePage();
            })
        }
        .width('100%')
        .padding({ left: 24, right: 20, top: 26, bottom: 26 })
        .backgroundColor(Theme.bgCard)
        .borderRadius(Theme.heroRadius)
        .shadow(ShadowStyle.nmRaisedLg)
        .margin({ left: 20, right: 20, top: 22 })

        Column() {
          Row() {
            Text('学院')
              .fontSize(14)
              .fontColor(Theme.textSecondary)
            Blank()
            Text(this.userInfo.college)
              .fontSize(14)
              .fontColor(Theme.textPrimary)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('专业')
              .fontSize(14)
              .fontColor(Theme.textSecondary)
            Blank()
            Text(this.userInfo.major)
              .fontSize(14)
              .fontColor(Theme.textPrimary)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('年级')
              .fontSize(14)
              .fontColor(Theme.textSecondary)
            Blank()
            Text(this.userInfo.grade)
              .fontSize(14)
              .fontColor(Theme.textPrimary)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('信用分')
              .fontSize(14)
              .fontColor(Theme.textSecondary)
            Blank()
            Text(`${this.userInfo.creditScore}`)
              .fontSize(14)
              .fontColor(this.userInfo.creditScore >= 85 ? '#4CAF50' : '#F44336')
              .fontWeight(FontWeight.Medium)
            if (this.userInfo.creditScore < 85) {
              Text('(无法发布)')
                .fontSize(12)
                .fontColor('#F44336')
                .margin({ left: 4 })
            }
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('班级')
              .fontSize(14)
              .fontColor(Theme.textSecondary)
            Blank()
            Text(this.userInfo.className)
              .fontSize(14)
              .fontColor(Theme.textPrimary)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('手机号')
              .fontSize(14)
              .fontColor(Theme.textSecondary)
            Blank()
            Text(this.userInfo.phone)
              .fontSize(14)
              .fontColor(Theme.textPrimary)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .backgroundColor(Theme.bgCard)
        .borderRadius(Theme.cardRadius)
        .shadow(ShadowStyle.nmRaised)
        .margin({ left: 20, right: 20, top: 14 })

        Column() {
          Row() {
            Text('我的发布')
              .fontSize(14)
              .fontColor(Theme.textPrimary)
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor(Theme.textDisabled)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/MyPublishPage' });
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('我的收藏')
              .fontSize(14)
              .fontColor(Theme.textPrimary)
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor(Theme.textDisabled)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/MyFavoritesPage' });
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('我的失物招领')
              .fontSize(14)
              .fontColor(Theme.textPrimary)
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor(Theme.textDisabled)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/MyLostFoundPage' });
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('浏览记录')
              .fontSize(14)
              .fontColor(Theme.textPrimary)
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor(Theme.textDisabled)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/MyHistoryPage' });
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('我的投诉')
              .fontSize(14)
              .fontColor(Theme.textPrimary)
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor(Theme.textDisabled)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/MyComplaintsPage' });
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('AI 助手')
              .fontSize(14)
              .fontColor(Theme.textPrimary)
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor(Theme.textDisabled)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.currentTab = 3;
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('消息通知')
              .fontSize(14)
              .fontColor(Theme.textPrimary)
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor(Theme.textDisabled)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.currentTab = 2;
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('修改密码')
              .fontSize(14)
              .fontColor(Theme.textPrimary)
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor(Theme.textDisabled)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/PasswordChangePage' });
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('与我们联系')
              .fontSize(14)
              .fontColor(Theme.textPrimary)
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor(Theme.textDisabled)
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/SettingsPage' });
          })
        }
        .width('100%')
        .backgroundColor(Theme.bgCard)
        .borderRadius(Theme.cardRadius)
        .shadow(ShadowStyle.nmRaised)
        .margin({ left: 20, right: 20, top: 16 })

        Button('退出登录')
          .width('88%')
          .height(46)
          .fontSize(16)
          .fontColor(Theme.danger)
          .backgroundColor(Theme.bgCard)
          .borderRadius(23)
          .shadow(ShadowStyle.sm)
          .margin({ top: 24 })
          .onClick(() => {
            const store: AppStore = AppStore.getInstance();
            store.logout();
            this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
          })

        Blank().height(40)
      }
      .width('100%')
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  private findCourse(day: number, section: number): CourseSchedule | undefined {
    for (let i = 0; i < this.scheduleList.length; i++) {
      const item: CourseSchedule = this.scheduleList[i];
      if (item.dayOfWeek === day && section >= item.startSection && section <= item.endSection) {
        return item;
      }
    }
    return undefined;
  }
}

class AiMsg {
  role: string = 'user';
  content: string = '';
}
