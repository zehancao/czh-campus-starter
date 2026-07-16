import { AppStore } from '../service/AppStore';
import { UserInfo, CourseSchedule, Product, Announcement, Semester, ProductCategory, ClubActivityItem } from '../model/Models';
import { WebSocketService, WsMessage, MessageCallback } from '../service/WebSocketService';
import { Constants } from '../common/Constants';
import { ApiService, ApiResult } from '../service/ApiService';
import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';

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
  @State semesterWeekCount: number = 20;
  @State unreadCount: number = 0;
  @State categories: ProductCategory[] = [];
  @State selectedCategoryId: number = 0;
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
      this.semesterWeekCount = semester.weekCount;
      this.currentWeek = this.calcCurrentWeek(semester.startDate, semester.weekCount);
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
      (item: CourseSchedule) => item.startWeek <= this.currentWeek && item.endWeek >= this.currentWeek);
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

  @Builder
  ScheduleContent() {
    Column() {
      Row() {
        Text('课程表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Row() {
          Text('<')
            .fontSize(18)
            .fontColor(this.currentWeek > 1 ? '#4A90D9' : '#CCCCCC')
            .padding({ left: 12, right: 8, top: 4, bottom: 4 })
            .onClick(() => {
              if (this.currentWeek > 1) {
                this.currentWeek--;
                this.updateScheduleGrid();
              }
            })
          Text(`第${this.currentWeek}周`)
            .fontSize(14)
            .fontColor('#4A90D9')
            .fontWeight(FontWeight.Medium)
          Text('>')
            .fontSize(18)
            .fontColor(this.currentWeek < this.semesterWeekCount ? '#4A90D9' : '#CCCCCC')
            .padding({ left: 8, right: 12, top: 4, bottom: 4 })
            .onClick(() => {
              if (this.currentWeek < this.semesterWeekCount) {
                this.currentWeek++;
                this.updateScheduleGrid();
              }
            })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      Row() {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string) => {
          Column() {
            Text(day)
              .fontSize(13)
              .fontColor('#999999')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }, (day: string) => day)
      }
      .width('100%')
      .padding({ left: 48, right: 8, bottom: 4 })

      Scroll() {
        Row() {
          Column() {
            ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (section: number) => {
              Column() {
                Text(`${section}`)
                  .fontSize(11)
                  .fontColor('#CCCCCC')
              }
              .width(40)
              .height(60)
              .justifyContent(FlexAlign.Center)
            }, (section: number) => `${section}`)
          }
          .width(40)

          Row() {
            ForEach([0, 1, 2, 3, 4, 5, 6], (dayIdx: number) => {
              Column() {
                ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], (secIdx: number) => {
                  Stack() {
                    if (this.scheduleGrid.length > dayIdx && this.scheduleGrid[dayIdx].length > secIdx && this.scheduleGrid[dayIdx][secIdx].courseName.length > 0) {
                      Column() {
                        Text(this.scheduleGrid[dayIdx][secIdx].courseName)
                          .fontSize(10)
                          .fontColor(Color.White)
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(this.scheduleGrid[dayIdx][secIdx].classroom)
                          .fontSize(8)
                          .fontColor('#FFFFFFCC')
                          .margin({ top: 2 })
                      }
                      .width('100%')
                      .height('100%')
                      .padding({ left: 2, right: 2, top: 2, bottom: 2 })
                      .backgroundColor(Constants.SCHEDULE_COLORS[this.scheduleGrid[dayIdx][secIdx].colorIndex % Constants.SCHEDULE_COLORS.length])
                      .borderRadius(4)
                      .justifyContent(FlexAlign.Center)
                    }
                  }
                  .width('100%')
                  .height(60)
                  .padding(1)
                }, (secIdx: number) => `${dayIdx}-${secIdx}`)
              }
              .layoutWeight(1)
            }, (dayIdx: number) => `${dayIdx}`)
          }
          .layoutWeight(1)
        }
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
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

    const baseUrl: string = 'http://192.168.1.3:8000';
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
          .onClick(async () => {
            try {
              const uris: string[] = await ApiService.pickImages();
              if (uris.length > 0) {
                const url: string = await ApiService.uploadAvatar(uris[0]);
                if (url.length > 0 && !url.startsWith('ERROR:')) {
                  this.userInfo.avatar = url;
                  const store: AppStore = AppStore.getInstance();
                  store.userInfo = this.userInfo;
                  this.getUIContext().getPromptAction().showToast({ message: '头像已更新' });
                }
              }
            } catch (_err) {
              this.getUIContext().getPromptAction().showToast({ message: '头像上传失败' });
            }
          })
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
        .margin({ left: 16, right: 16, top: 16 })

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
