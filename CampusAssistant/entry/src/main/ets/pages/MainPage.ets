import { AppStore } from '../service/AppStore';
import { UserInfo, CourseSchedule, Product, Announcement, Semester, ProductCategory, ClubActivityItem } from '../model/Models';
import { WebSocketService, WsMessage, MessageCallback } from '../service/WebSocketService';
import { Constants } from '../common/Constants';
import { ApiService, ApiResult } from '../service/ApiService';
import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { router } from '@kit.ArkUI';

const WEEK_DAY_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];
const SCHEDULE_CARD_BG: string[] = ['#EEF0FF', '#E9F6FF', '#FFF5D8', '#FDECF5', '#EAF8EA', '#FFF0E1', '#F2EDFF', '#EDF3F5'];
const SCHEDULE_CARD_FG: string[] = ['#6A63B6', '#2F8DB8', '#C69212', '#C85796', '#36A957', '#CB7A1B', '#7B61C8', '#7A8A92'];
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
  @State semesterWeekCount: number = 20;
  @State semesterName: string = '';
  @State semesterStartDate: string = '';
  @State unreadCount: number = 0;
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
  private aiScroller: Scroller = new Scroller();
  private textDecoder: util.TextDecoder = new util.TextDecoder('utf-8');

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
    };
    WebSocketService.getInstance().onMessage(this.mainWsCallback);
  }

  onPageShow(): void {
    const store: AppStore = AppStore.getInstance();
    this.userInfo = store.userInfo;
    this.loadProducts();
    this.loadMyActivities();
    // 接收 AddCoursePage 返回的手动添课数据
    const hasPending = AppStorage.Get<boolean>('pending_hasManualCourse');
    if (hasPending === true) {
      AppStorage.Delete('pending_hasManualCourse');
      const item: CourseSchedule = new CourseSchedule();
      item.id = Date.now();
      item.courseName = AppStorage.Get<string>('pending_courseName') ?? '';
      item.classroom = AppStorage.Get<string>('pending_classroom') ?? '';
      item.teacherName = AppStorage.Get<string>('pending_teacherName') ?? '';
      item.dayOfWeek = AppStorage.Get<number>('pending_dayOfWeek') ?? 1;
      item.startSection = AppStorage.Get<number>('pending_startSection') ?? 1;
      item.endSection = AppStorage.Get<number>('pending_endSection') ?? 2;
      item.startWeek = AppStorage.Get<number>('pending_startWeek') ?? 1;
      item.endWeek = AppStorage.Get<number>('pending_endWeek') ?? 20;
      item.weekParity = AppStorage.Get<string>('pending_weekParity') ?? 'all';
      item.colorIndex = this.scheduleList.length % SCHEDULE_CARD_BG.length;
      this.scheduleList.push(item);
      this.updateScheduleGrid();
      this.getUIContext().getPromptAction().showToast({ message: '课程已添加到当前课表' });
    }
  }

  aboutToDisappear(): void {
    if (this.mainWsCallback !== null) {
      WebSocketService.getInstance().removeMessageCallback(this.mainWsCallback);
    }
  }

  private async loadUnreadCount(): Promise<void> {
    const result: ApiResult = await ApiService.getUnreadCount();
    if (result.code === 200 && result.data !== undefined) {
      const obj: Record<string, Object> = result.data as Record<string, Object>;
      this.unreadCount = (obj['unreadCount'] as number) ?? 0;
    }
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
    if (startDateStr.length < 10) {
      return 1;
    }
    const parts: string[] = startDateStr.split('-');
    const start: Date = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
    const now: Date = new Date();
    const diffMs: number = now.getTime() - start.getTime();
    const diffDays: number = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    const week: number = Math.floor(diffDays / 7) + 1;
    if (week < 1) {
      return 1;
    }
    if (week > weekCount) {
      return weekCount;
    }
    return week;
  }

  private async loadSchedule(): Promise<void> {
    const result: ApiResult = await ApiService.getMySchedule(1);
    if (result.code === 200 && result.data !== undefined) {
      this.scheduleList = ApiService.parseScheduleList(result.data);
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
      }.tabBar(this.TabItem(0, '首页', '🏠'))

      TabContent() {
        this.ScheduleContent()
      }.tabBar(this.TabItem(1, '课表', '📅'))

      TabContent() {
        this.MarketContent()
      }.tabBar(this.TabItem(2, '交易', '🛒'))

      TabContent() {
        this.AIChatContent()
      }.tabBar(this.TabItem(3, 'AI', '🤖'))

      TabContent() {
        this.ProfileContent()
      }.tabBar(this.TabItem(4, '我的', '👤'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
    .onChange((index: number) => {
      this.currentTab = index;
    })
  }

  @Builder
  TabItem(index: number, label: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(22)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? '#4A90D9' : '#999999')
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  HomeContent() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Scroll() {
        Column() {
          Row() {
            Column() {
              Text(`你好，${this.userInfo.name}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
              Text(`${this.userInfo.college} · ${this.userInfo.major}`)
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Column() {
              if (this.userInfo.avatar.length > 0) {
                Image(`${ApiService.baseUrl}${this.userInfo.avatar}`)
                  .width(48)
                  .height(48)
                  .borderRadius(24)
                  .objectFit(ImageFit.Cover)
              } else {
                Text(this.userInfo.name.length > 0 ? this.userInfo.name[0] : 'U')
                  .fontSize(24)
                  .fontColor(Color.White)
                  .textAlign(TextAlign.Center)
                  .width(48)
                  .height(48)
                  .borderRadius(24)
                  .backgroundColor('#4A90D9')
              }
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 16 })

          Row() {
            this.QuickEntry('📋', '我的课表', () => { this.currentTab = 1; })
            this.QuickEntry('📚', '空教室', () => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/EmptyRoomPage' });
            })
            this.QuickEntry('🏃', '社团活动', () => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/ClubActivityListPage' });
            })
            this.QuickEntry('🔎', '失物招领', () => {
              this.getUIContext().getRouter().pushUrl({ url: 'pages/LostFoundListPage' });
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
          .justifyContent(FlexAlign.SpaceAround)

          if (this.myActivities.length > 0) {
            Column() {
              Text('我的活动')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .width('100%')
                .padding({ left: 20, bottom: 12 })

              ForEach(this.myActivities, (act: ClubActivityItem) => {
                Row() {
                  Column() {
                    Text(act.title)
                      .fontSize(14)
                      .fontColor('#333333')
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`${act.club} · ${act.venue} · ${act.activityTime}`)
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 4 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  Blank()
                  Text('查看')
                    .fontSize(13)
                    .fontColor('#4A90D9')
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                .backgroundColor(Color.White)
                .onClick(() => {
                  this.getUIContext().getRouter().pushUrl({
                    url: 'pages/ClubActivityDetailPage',
                    params: { 'id': `${act.id}` } as Record<string, string>
                  });
                })
              }, (act: ClubActivityItem) => `${act.id}`)
            }
            .width('100%')
            .padding({ top: 16 })
          }

          Column() {
            Text('今日课程')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 20, bottom: 12 })

            this.TodaySchedule()
          }
          .width('100%')
          .padding({ top: 16 })

          Column() {
            Row() {
              Text('校园公告')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
              Blank()
              Text('更多 >')
                .fontSize(13)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 12 })

            ForEach(this.announcements, (item: Announcement) => {
              Row() {
                Column() {
                  Text(item.title)
                    .fontSize(15)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.summary)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Column() {
                  Text(item.category)
                    .fontSize(11)
                    .fontColor('#4A90D9')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .backgroundColor('#EBF3FC')
                }
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .backgroundColor(Color.White)
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
  QuickEntry(icon: string, label: string, action: () => void) {
    Column() {
      Text(icon)
        .fontSize(28)
      Text(label)
        .fontSize(11)
        .fontColor('#666666')
        .margin({ top: 4 })
    }
    .width(64)
    .height(72)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => { action(); })
  }

  @Builder
  TodaySchedule() {
    if (this.todayCourses.length === 0) {
      Column() {
        Text('今天没有课程，好好休息吧~')
          .fontSize(14)
          .fontColor('#999999')
          .padding(20)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    } else {
      ForEach(this.todayCourses, (item: CourseSchedule) => {
        Row() {
          Column() {
            Text(Constants.SECTION_TIMES[item.startSection - 1][0])
              .fontSize(13)
              .fontColor('#999999')
            Text(Constants.SECTION_TIMES[item.endSection - 1][1])
              .fontSize(12)
              .fontColor('#CCCCCC')
              .margin({ top: 2 })
          }
          .width(48)
          .alignItems(HorizontalAlign.Center)

          Blank().width(8)

          Column() {
            Row()
              .width(3)
              .height('100%')
              .backgroundColor(Constants.SCHEDULE_COLORS[item.colorIndex % Constants.SCHEDULE_COLORS.length])
              .borderRadius(2)
          }
          .height(60)

          Blank().width(12)

          Column() {
            Text(item.courseName)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Text(`${item.classroom} · ${item.teacherName}`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .alignItems(VerticalAlign.Center)
      }, (item: CourseSchedule) => `${item.id}`)
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
    if (this.semesterStartDate.length < 10) {
      return null;
    }
    const parts: string[] = this.semesterStartDate.split('-');
    if (parts.length < 3) {
      return null;
    }
    const date: Date = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
    date.setDate(date.getDate() + (this.currentWeek - 1) * 7 + dayIndex);
    return date;
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
    return SCHEDULE_CARD_BG[Math.abs(item.colorIndex) % SCHEDULE_CARD_BG.length];
  }

  private courseFg(item: CourseSchedule): string {
    return SCHEDULE_CARD_FG[Math.abs(item.colorIndex) % SCHEDULE_CARD_FG.length];
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

  private saveManualCourse(): void {
    if (this.addCourseName.trim().length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入课程名称' });
      return;
    }
    const item: CourseSchedule = new CourseSchedule();
    item.id = Date.now();
    item.courseName = this.addCourseName.trim();
    item.classroom = this.addClassroom.trim();
    item.teacherName = this.addTeacherName.trim();
    item.dayOfWeek = this.addDayOfWeek;
    item.startSection = this.addStartSection;
    item.endSection = this.addEndSection;
    item.startWeek = this.addStartWeek;
    item.endWeek = this.addEndWeek;
    item.weekParity = 'all';
    item.colorIndex = this.scheduleList.length % SCHEDULE_CARD_BG.length;
    this.scheduleList.push(item);
    this.updateScheduleGrid();
    this.showAddCourseForm = false;
    this.getUIContext().getPromptAction().showToast({ message: '课程已添加到当前课表' });
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
            .height(48)
            .fontSize(17)
            .fontColor(Color.White)
            .backgroundColor('#FF6B4A')
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
            .fontColor('#EF4A48')
          Text('▼')
            .fontSize(16)
            .fontColor('#20242A')
            .margin({ left: 8 })
        }
        .onClick(() => {
          this.showWeekPicker();
        })
        Text(this.semesterTitle())
          .fontSize(14)
          .fontColor('#999999')
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
        .backgroundColor('#080B12')
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
          .fontColor('#333333')
        Text('月')
          .fontSize(17)
          .fontColor('#333333')
          .margin({ top: 2 })
      }
      .width(50)
      .alignItems(HorizontalAlign.Center)

      ForEach(WEEK_DAY_LABELS, (day: string, index: number) => {
        Column() {
          Text(day)
            .fontSize(19)
            .fontColor('#333333')
          Text(this.weekDayText(index))
            .fontSize(15)
            .fontColor('#999999')
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
    .border({ width: 1, color: '#EEEEEE' })
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
                .fontColor('#333333')
              Text(this.sectionStartTime(section))
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 3 })
              Text(this.sectionEndTime(section))
                .fontSize(11)
                .fontColor('#999999')
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
                    .color('#F0F0F0')
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
        .backgroundColor('#FFFFFFDD')
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
            .backgroundColor('#222222')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ right: 8 })
        }
        Text(item.courseName.length > 0 ? item.courseName : '课程名称未录入')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
          .layoutWeight(1)
        Text('编辑')
          .fontSize(15)
          .fontColor('#999999')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(Color.White)
          .borderRadius(5)
      }
      .width('100%')

      Text(this.courseWeekText(item))
        .fontSize(17)
        .fontColor('#333333')
        .width('100%')
        .margin({ top: 18 })
      Text(`周${WEEK_DAY_LABELS[item.dayOfWeek - 1]} | 第${item.startSection}-${item.endSection}节 | ${this.courseTimeText(item)}`)
        .fontSize(15)
        .fontColor('#999999')
        .width('100%')
        .margin({ top: 12 })
      Text(`教室：${item.classroom.length > 0 ? item.classroom : '未填写'}`)
        .fontSize(15)
        .fontColor('#999999')
        .width('100%')
        .margin({ top: 12 })
      Text(`老师：${item.teacherName.length > 0 ? item.teacherName : '未填写'}`)
        .fontSize(15)
        .fontColor('#999999')
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#EEF3F6')
    .borderRadius(14)
    .margin({ bottom: 18 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  AddCourseContent() {
    Column() {
      Row() {
        Text('<')
          .fontSize(30)
          .fontColor('#20242A')
          .width(50)
          .onClick(() => {
            this.hideAddCourse();
          })
        Text('添加课程')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('保存')
          .fontSize(16)
          .fontColor('#5A82D9')
          .width(50)
          .textAlign(TextAlign.End)
          .onClick(() => {
            this.saveManualCourse();
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 18, right: 18 })
      .border({ width: 1, color: '#EEEEEE' })

      Scroll() {
        Column() {
          Row() {
            Column() {
              Text('当前学期为')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#3D6FB8')
              Text('返回课程表页面即可切换学期')
                .fontSize(14)
                .fontColor('#3D6FB8')
                .margin({ top: 12 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text(this.semesterTitle())
              .fontSize(18)
              .fontColor('#3D6FB8')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#F1F7FF')
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
            .fontColor('#5A82D9')
            .backgroundColor('#EEF4FF')
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
        .fontColor('#222222')
        .width(104)
      TextInput({ placeholder: placeholder, text: value })
        .layoutWeight(1)
        .height(52)
        .fontSize(16)
        .textAlign(TextAlign.End)
        .backgroundColor('#00000000')
        .placeholderColor('#D0D0D0')
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
    .border({ width: 1, color: '#EEEEEE' })
  }

  @Builder
  AddSelectRow(label: string, value: string, type: number) {
    Row() {
      Text(label)
        .fontSize(19)
        .fontWeight(FontWeight.Medium)
        .fontColor('#222222')
        .width(104)
      Blank()
      Text(value)
        .fontSize(17)
        .fontColor(type === 2 ? '#E45A73' : '#666666')
      Text('>')
        .fontSize(24)
        .fontColor('#BBBBBB')
        .margin({ left: 10 })
    }
    .width('100%')
    .height(70)
    .border({ width: 1, color: '#EEEEEE' })
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
  MarketContent() {
    Refresh({ refreshing: $$this.marketRefreshing }) {
      Column() {
        Row() {
          Text('二手交易')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Blank()
          Text('+ 发布')
            .fontSize(14)
            .fontColor('#4A90D9')
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
                .backgroundColor('#FF4444')
                .position({ x: 14, y: -4 })
            }
          }
          .width(28)
          .height(28)
          .onClick(() => {
            this.unreadCount = 0;
            this.getUIContext().getRouter().pushUrl({ url: 'pages/ConversationListPage' });
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 12 })

        Stack() {
          TextInput({ placeholder: '搜索商品...', text: this.searchKeyword })
            .fontSize(14)
            .height(36)
            .borderRadius(18)
            .backgroundColor('#F0F0F0')
            .padding({ left: 16, right: 16 })
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
                    .fontColor('#333333')
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
            .backgroundColor(Color.White)
            .borderRadius(8)
            .shadow({ radius: 4, color: '#20000000', offsetY: 2 })
            .position({ y: 36 })
            .zIndex(10)
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 4 })

        Scroll() {
          Row({ space: 8 }) {
            Text('全部')
              .fontSize(13)
              .fontColor(this.selectedCategoryId === 0 ? '#4A90D9' : '#666666')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16)
              .backgroundColor(this.selectedCategoryId === 0 ? '#EBF3FC' : '#F0F0F0')
              .onClick(() => {
                this.selectedCategoryId = 0;
                this.loadProducts();
              })
            ForEach(this.categories, (cat: ProductCategory) => {
              Text(cat.name)
                .fontSize(13)
                .fontColor(this.selectedCategoryId === cat.id ? '#4A90D9' : '#666666')
                .padding({ left: cat.parentId === 0 ? 12 : 8, right: cat.parentId === 0 ? 12 : 8, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.selectedCategoryId === cat.id ? '#EBF3FC' : '#F0F0F0')
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

        List({ space: 12 }) {
          ForEach(this.products, (item: Product) => {
            ListItem() {
              Row() {
                Column() {
                  if (item.images.length > 0) {
                    Image(`${ApiService.baseUrl}${item.images[0]}`)
                      .width(80)
                      .height(80)
                      .borderRadius(8)
                      .objectFit(ImageFit.Cover)
                  } else {
                    Row()
                      .width(80)
                      .height(80)
                      .backgroundColor('#EEEEEE')
                      .borderRadius(8)
                  }
                }
                Column() {
                  Text(item.title)
                    .fontSize(15)
                    .fontColor('#333333')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.description)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row() {
                    Text(`¥${item.price}`)
                      .fontSize(16)
                      .fontColor('#FF4444')
                      .fontWeight(FontWeight.Bold)
                    if (item.originalPrice > 0) {
                      Text(`¥${item.originalPrice}`)
                        .fontSize(12)
                        .fontColor('#CCCCCC')
                        .decoration({ type: TextDecorationType.LineThrough })
                        .margin({ left: 6 })
                    }
                    Blank()
                    Text(item.campusLocation)
                      .fontSize(11)
                      .fontColor('#999999')
                  }
                  .width('100%')
                  .margin({ top: 6 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .padding({ left: 12 })
              }
              .width('100%')
              .padding(12)
              .backgroundColor(Color.White)
              .borderRadius(12)
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
          }, (item: Product) => `${item.id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F6FA')
    }
    .onRefreshing(() => {
      this.refreshMarket();
    })
    .backgroundColor('#F5F6FA')
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

    const aiMsg: AiMsg = new AiMsg();
    aiMsg.role = 'assistant';
    aiMsg.content = '';
    this.aiMessages.push(aiMsg);
    const lastIndex: number = this.aiMessages.length - 1;

    setTimeout(() => {
      this.aiScroller.scrollEdge(Edge.Bottom);
    }, 100);

    const baseUrl: string = 'http://192.168.3.22:8000';
    const url: string = `${baseUrl}/api/ai/chat`;
    const req: http.HttpRequest = http.createHttp();
    let fullContent: string = '';
    let buffer: string = '';

    req.on('dataReceive', (data: ArrayBuffer) => {
      const chunk: string = this.textDecoder.decodeToString(new Uint8Array(data));
      buffer += chunk;
      const lines: string[] = buffer.split('\n');
      buffer = lines[lines.length - 1];

      for (let i: number = 0; i < lines.length - 1; i++) {
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
              fullContent = 'AI 服务出错: ' + parsed['error'];
            } else {
              const content: string = parsed['content'] ?? '';
              if (content.length > 0) {
                fullContent += content;
              }
            }
          } catch (_e) {
            // skip
          }
        }
      }

      aiMsg.content = fullContent;
      this.aiMessages[lastIndex] = aiMsg;
      setTimeout(() => {
        this.aiScroller.scrollEdge(Edge.Bottom);
      }, 50);
    });

    req.on('dataEnd', () => {
      if (fullContent.length === 0) {
        aiMsg.content = '抱歉，AI 服务未返回内容';
        this.aiMessages[lastIndex] = aiMsg;
      }
      this.aiIsLoading = false;
      req.off('dataReceive');
      req.off('dataEnd');
      req.destroy();
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
    });
  }

  @Builder
  AIChatContent() {
    Column() {
      Row() {
        Text('AI 校园助手')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
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
                .backgroundColor('#4A90D9')
                .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
                .constraintSize({ maxWidth: '75%' })
              } else {
                Column() {
                  if (msg.content.length === 0 && this.aiIsLoading) {
                    Row({ space: 4 }) {
                      LoadingProgress()
                        .width(16)
                        .height(16)
                        .color('#4A90D9')
                      Text('思考中...')
                        .fontSize(14)
                        .fontColor('#999999')
                    }
                  } else {
                    Text(this.cleanMarkdown(msg.content))
                      .fontSize(15)
                      .fontColor('#333333')
                      .lineHeight(22)
                  }
                }
                .padding(12)
                .backgroundColor('#F0F0F0')
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
          .placeholderColor('#CCCCCC')
          .backgroundColor('#F5F5F5')
          .borderRadius(22)
          .padding({ left: 16, right: 16 })
          .enabled(!this.aiIsLoading)
          .onChange((v: string) => { this.aiInputText = v; })
          .onSubmit(() => { this.sendAiMessage(); })
        Button('发送')
          .height(44)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#4A90D9')
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
    .backgroundColor('#F5F6FA')
  }

  @Builder
  ProfileContent() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            if (this.userInfo.avatar.length > 0) {
              Image(`${ApiService.baseUrl}${this.userInfo.avatar}`)
                .width(64)
                .height(64)
                .borderRadius(32)
                .objectFit(ImageFit.Cover)
            } else {
              Text(this.userInfo.name.length > 0 ? this.userInfo.name[0] : 'U')
                .fontSize(28)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .width(64)
                .height(64)
                .borderRadius(32)
                .backgroundColor('#4A90D9')
            }
          }

          Column() {
            Text(this.userInfo.name)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text(`学号：${this.userInfo.studentId}`)
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .margin({ left: 16 })
          .alignItems(HorizontalAlign.Start)
          Blank()
          Button('编辑资料')
            .height(34)
            .fontSize(13)
            .fontColor('#4A90D9')
            .backgroundColor('#EBF3FC')
            .borderRadius(17)
            .padding({ left: 14, right: 14 })
            .onClick(() => {
              this.openEditProfilePage();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24, bottom: 24 })
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ left: 16, right: 16, top: 16 })

        Column() {
          Row() {
            Text('学院')
              .fontSize(14)
              .fontColor('#666666')
            Blank()
            Text(this.userInfo.college)
              .fontSize(14)
              .fontColor('#333333')
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('专业')
              .fontSize(14)
              .fontColor('#666666')
            Blank()
            Text(this.userInfo.major)
              .fontSize(14)
              .fontColor('#333333')
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('年级')
              .fontSize(14)
              .fontColor('#666666')
            Blank()
            Text(this.userInfo.grade)
              .fontSize(14)
              .fontColor('#333333')
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('信用分')
              .fontSize(14)
              .fontColor('#666666')
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
              .fontColor('#666666')
            Blank()
            Text(this.userInfo.className)
              .fontSize(14)
              .fontColor('#333333')
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('手机号')
              .fontSize(14)
              .fontColor('#666666')
            Blank()
            Text(this.userInfo.phone)
              .fontSize(14)
              .fontColor('#333333')
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ left: 16, right: 16, top: 0 })

        Column() {
          Row() {
            Text('我的发布')
              .fontSize(14)
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
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
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
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
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
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
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
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
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
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
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/AiChatPage' });
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('消息通知')
              .fontSize(14)
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/ConversationListPage' });
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('修改密码')
              .fontSize(14)
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/PasswordChangePage' });
          })

          Divider().margin({ left: 20, right: 20 })

          Row() {
            Text('设置')
              .fontSize(14)
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(48)
          .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ left: 16, right: 16, top: 16 })

        Button('退出登录')
          .width('90%')
          .height(44)
          .fontSize(16)
          .fontColor('#FF4444')
          .backgroundColor(Color.White)
          .borderRadius(12)
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
