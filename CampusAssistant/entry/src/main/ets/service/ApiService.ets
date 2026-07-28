import { http } from '@kit.NetworkKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { promptAction } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { AppStore } from './AppStore';
import { UserInfo, CourseSchedule, Product, Announcement, Conversation, ChatMessage, Semester, PickerOption, ProductCategory, FavoriteItem, EmptyRoom, LostFoundItem, CarpoolOrder, PassengerItem, SafetyReport, SafetyContact, ClubActivityItem, ConfessionPost, StudyShareItem } from '../model/Models';

export interface ApiResult {
  code: number;
  msg: string;
  data: Object | undefined;
}

export class ApiService {
  static baseUrl: string = 'http://192.168.1.253:8080';

  static setBaseUrl(url: string): void {
    ApiService.baseUrl = url;
  }

  static async request(method: http.RequestMethod, path: string, data: Object | undefined, needToken: boolean): Promise<ApiResult> {
    const url: string = `${ApiService.baseUrl}${path}`;
    const headerRecord: Record<string, string> = { 'Content-Type': 'application/json' };
    if (needToken) {
      const store: AppStore = AppStore.getInstance();
      if (store.token.length > 0) {
        headerRecord['Authorization'] = `Bearer ${store.token}`;
      }
    }
    const options: http.HttpRequestOptions = {
      method: method,
      header: headerRecord,
      readTimeout: 15000,
      connectTimeout: 15000,
      expectDataType: http.HttpDataType.STRING
    };
    if (data !== undefined) {
      options.extraData = JSON.stringify(data);
    }
    try {
      const req: http.HttpRequest = http.createHttp();
      const response: http.HttpResponse = await req.request(url, options);
      req.destroy();
      const resultStr: string = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
      const result: ApiResult = JSON.parse(resultStr) as ApiResult;
      return result;
    } catch (err) {
      const errMsg: string = err !== null && err !== undefined ? String(err) : 'unknown';
      const errResult: ApiResult = { code: -1, msg: `网络错误: ${errMsg}`, data: undefined };
      promptAction.showToast({ message: errMsg, duration: 3000 });
      return errResult;
    }
  }

  static async login(studentId: string, password: string): Promise<ApiResult> {
    const body: Record<string, string> = { 'studentId': studentId, 'password': password };
    const result: ApiResult = await ApiService.request(http.RequestMethod.POST, '/api/user/login', body, false);
    if (result.code === 200 && result.data !== undefined) {
      const data: Record<string, Object> = result.data as Record<string, Object>;
      const store: AppStore = AppStore.getInstance();
      const token: string = data['token'] as string;
      store.setToken(token);
      const userObj: Record<string, Object> = data['user'] as Record<string, Object>;
      const userInfo: UserInfo = ApiService.parseUser(userObj);
      store.setUserInfo(userInfo);
    }
    return result;
  }

  static async register(params: Record<string, string>): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.POST, '/api/user/register', params, false);
  }

  static async getPublicColleges(): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, '/api/public/colleges', undefined, false);
  }

  static async getPublicMajors(collegeId: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, `/api/public/majors?collegeId=${collegeId}`, undefined, false);
  }

  static async getPublicClasses(grade: string, collegeId: number, majorId: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, `/api/public/classes?grade=${grade}&collegeId=${collegeId}&majorId=${majorId}`, undefined, false);
  }

  static async getPublicGrades(): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, '/api/public/grades', undefined, false);
  }

  static async getProductCategories(): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, '/api/public/product-categories', undefined, false);
  }

  static async getProfile(): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, '/api/user/profile', undefined, true);
  }

  static async getMySchedule(semesterId: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, `/api/schedule/my?semesterId=${semesterId}`, undefined, true);
  }

  static async getCurrentSemester(): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, '/api/schedule/current-semester', undefined, true);
  }

  static async addPersonalCourse(params: Record<string, Object>): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.POST, '/api/schedule/add-personal', params, true);
  }

  static async deletePersonalCourse(id: number): Promise<ApiResult> {
    const body: Record<string, Object> = { 'id': id } as Record<string, Object>;
    return await ApiService.request(http.RequestMethod.POST, '/api/schedule/delete-personal', body, true);
  }

  static parseSemester(data: Object): Semester {
    const obj: Record<string, Object> = data as Record<string, Object>;
    const s: Semester = new Semester();
    s.id = (obj['id'] as number) ?? 0;
    s.name = (obj['name'] as string) ?? '';
    s.startDate = (obj['startDate'] as string) ?? '';
    s.endDate = (obj['endDate'] as string) ?? '';
    s.weekCount = (obj['weekCount'] as number) ?? 16;
    s.isCurrent = (obj['isCurrent'] as number) ?? 0;
    return s;
  }

  static async getProductList(categoryId: number, page: number, size: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, `/api/product/list?categoryId=${categoryId}&page=${page}&size=${size}`, undefined, false);
  }

  static async getProductDetail(id: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, `/api/product/${id}`, undefined, true);
  }

  static async getAnnouncementList(category: string): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, `/api/announcement/list?category=${category}`, undefined, true);
  }

  static async getConversations(): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, '/api/chat/conversations', undefined, true);
  }

  static async getUnreadCount(): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, '/api/chat/unread-count', undefined, true);
  }

  static async getMessages(conversationId: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, `/api/chat/messages/${conversationId}`, undefined, true);
  }

  static async sendMessage(conversationId: number, content: string, msgType: string): Promise<ApiResult> {
    const body: Record<string, string> = { 'conversationId': `${conversationId}`, 'content': content, 'msgType': msgType };
    return await ApiService.request(http.RequestMethod.POST, '/api/chat/send', body, true);
  }

  static async createConversation(otherUserId: number, productId: number): Promise<ApiResult> {
    const body: Record<string, string> = { 'otherUserId': `${otherUserId}`, 'productId': `${productId}` };
    return await ApiService.request(http.RequestMethod.POST, '/api/chat/create-conversation', body, true);
  }

  static async publishProduct(params: Record<string, Object>): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.POST, '/api/product/publish', params, true);
  }

  static async pickImages(): Promise<string[]> {
    const options: picker.PhotoSelectOptions = new picker.PhotoSelectOptions();
    options.maxSelectNumber = 5;
    options.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
    const photoPicker: picker.PhotoViewPicker = new picker.PhotoViewPicker();
    const result: picker.PhotoSelectResult = await photoPicker.select(options);
    return result.photoUris;
  }

  private static getExtFromUri(uri: string): string {
    const segments: string[] = uri.split('/');
    const last: string = segments.length > 0 ? segments[segments.length - 1] : '';
    const dotParts: string[] = last.split('.');
    if (dotParts.length > 1) {
      const ext: string = dotParts[dotParts.length - 1].toLowerCase();
      if (ext.length <= 5) return ext;
    }
    return 'bin';
  }

  private static getMimeType(ext: string): string {
    const mimeMap: Record<string, string> = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed'
    };
    const mime: string | undefined = mimeMap[ext];
    return mime !== undefined ? mime : 'application/octet-stream';
  }

  private static async uploadFile(endpoint: string, uri: string): Promise<string> {
    const srcUri: fileUri.FileUri = new fileUri.FileUri(uri);
    const srcPath: string = srcUri.path;
    if (srcPath.length === 0) {
      return 'ERROR:srcPath_empty';
    }
    const store: AppStore = AppStore.getInstance();
    if (store.context === undefined) {
      return 'ERROR:context_undefined';
    }
    const ext: string = ApiService.getExtFromUri(uri);
    const cacheDir: string = store.context.cacheDir;
    const fileName: string = `upload_${Date.now()}_${Math.random().toString(36).substring(2, 8)}.${ext}`;
    const destPath: string = `${cacheDir}/${fileName}`;
    const mimeType: string = ApiService.getMimeType(ext);
    fileIo.copyFileSync(srcPath, destPath);
    const url: string = `${ApiService.baseUrl}${endpoint}`;
    const req: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await req.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'content-type': 'multipart/form-data',
          'Authorization': `Bearer ${store.token}`
        },
        multiFormDataList: [
          {
            name: 'file',
            filePath: destPath,
            contentType: mimeType,
            remoteFileName: fileName
          }
        ]
      });
      const resultStr: string = response.result as string;
      const result: ApiResult = JSON.parse(resultStr) as ApiResult;
      if (result.code === 200 && result.data !== undefined) {
        return result.data as string;
      }
      return `ERROR:code_${result.code}_msg_${result.msg}`;
    } finally {
      req.destroy();
    }
  }

  static async uploadImage(uri: string): Promise<string> {
    return ApiService.uploadFile('/api/product/upload-image', uri);
  }

  static parseUser(obj: Record<string, Object>): UserInfo {
    const user: UserInfo = new UserInfo();
    user.id = (obj['id'] as number) ?? 0;
    user.studentId = (obj['studentId'] as string) ?? '';
    user.name = (obj['name'] as string) ?? '';
    user.avatar = (obj['avatar'] as string) ?? '';
    user.college = (obj['college'] as string) ?? '';
    user.major = (obj['major'] as string) ?? '';
    user.grade = (obj['grade'] as string) ?? '';
    user.className = (obj['className'] as string) ?? '';
    user.hometown = (obj['hometown'] as string) ?? '';
    user.phone = (obj['phone'] as string) ?? '';
    user.role = (obj['role'] as string) ?? 'student';
    user.creditScore = (obj['creditScore'] as number) ?? 100;
    return user;
  }

  static parseScheduleList(data: Object): CourseSchedule[] {
    const arr: Object[] = data as Object[];
    const list: CourseSchedule[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: CourseSchedule = new CourseSchedule();
      item.id = (obj['id'] as number) ?? 0;
      item.courseName = (obj['courseName'] as string) ?? '';
      item.classroom = (obj['classroom'] as string) ?? '';
      item.dayOfWeek = (obj['dayOfWeek'] as number) ?? 1;
      item.startSection = (obj['startSection'] as number) ?? 1;
      item.endSection = (obj['endSection'] as number) ?? 2;
      item.startWeek = (obj['startWeek'] as number) ?? 1;
      item.endWeek = (obj['endWeek'] as number) ?? 16;
      item.weekParity = (obj['weekParity'] as string) ?? 'all';
      item.teacherName = (obj['teacherName'] as string) ?? '';
      item.source = (obj['source'] as string) ?? 'class';
      item.colorIndex = i % 10;
      list.push(item);
    }
    return list;
  }

  static parseAnnouncementList(data: Object): Announcement[] {
    const arr: Object[] = data as Object[];
    const list: Announcement[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: Announcement = new Announcement();
      item.id = (obj['id'] as number) ?? 0;
      item.title = (obj['title'] as string) ?? '';
      item.summary = (obj['summary'] as string) ?? '';
      item.category = (obj['category'] as string) ?? '';
      item.isTop = (obj['isTop'] as number) ?? 0;
      item.publishTime = (obj['publishTime'] as string) ?? '';
      list.push(item);
    }
    return list;
  }

  static parseConversationList(data: Object): Conversation[] {
    const arr: Object[] = data as Object[];
    const list: Conversation[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: Conversation = new Conversation();
      item.id = (obj['id'] as number) ?? 0;
      item.otherUserId = (obj['otherUserId'] as number) ?? 0;
      item.otherUserName = (obj['otherUserName'] as string) ?? '';
      item.lastMessage = (obj['lastMessage'] as string) ?? '';
      item.lastTime = (obj['lastTime'] as string) ?? '';
      item.unreadCount = (obj['unreadCount'] as number) ?? 0;
      item.productId = (obj['productId'] as number) ?? 0;
      list.push(item);
    }
    return list;
  }

  static parseMessageList(data: Object): ChatMessage[] {
    const arr: Object[] = data as Object[];
    const list: ChatMessage[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: ChatMessage = new ChatMessage();
      item.id = (obj['id'] as number) ?? 0;
      item.conversationId = (obj['conversationId'] as number) ?? 0;
      item.senderId = (obj['senderId'] as number) ?? 0;
      item.content = (obj['content'] as string) ?? '';
      item.msgType = (obj['msgType'] as string) ?? 'text';
      item.createTime = (obj['createTime'] as string) ?? '';
      item.isMine = (obj['isMine'] as boolean) ?? false;
      list.push(item);
    }
    return list;
  }

  static parsePickerOptions(data: Object): PickerOption[] {
    const arr: Object[] = data as Object[];
    const list: PickerOption[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: PickerOption = new PickerOption();
      item.id = (obj['id'] as number) ?? 0;
      item.name = (obj['name'] as string) ?? '';
      list.push(item);
    }
    return list;
  }

  static parseClassOptions(data: Object): PickerOption[] {
    const arr: Object[] = data as Object[];
    const list: PickerOption[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: PickerOption = new PickerOption();
      item.id = (obj['id'] as number) ?? 0;
      item.name = (obj['name'] as string) ?? '';
      list.push(item);
    }
    return list;
  }

  static parseProductCategoryList(data: Object): ProductCategory[] {
    const arr: Object[] = data as Object[];
    const list: ProductCategory[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: ProductCategory = new ProductCategory();
      item.id = (obj['id'] as number) ?? 0;
      item.name = (obj['name'] as string) ?? '';
      item.icon = (obj['icon'] as string) ?? '';
      item.parentId = (obj['parentId'] as number) ?? 0;
      item.sortOrder = (obj['sortOrder'] as number) ?? 0;
      list.push(item);
    }
    return list;
  }

  static async getMyProducts(): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, '/api/product/my-products', undefined, true);
  }

  static parseProductList(data: Object): Product[] {
    const arr: Object[] = data as Object[];
    const list: Product[] = [];
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
        if (typeof imagesObj === 'object') {
          item.images = imagesObj as string[];
        } else {
          const raw: string = imagesObj as string;
          if (raw.length > 0) {
            const c: string = raw.replace('[', '').replace(']', '').replace(new RegExp('"', 'g'), '');
            if (c.length > 0) {
              item.images = c.split(',');
            }
          }
        }
      }
      list.push(item);
    }
    return list;
  }

  static async updateProductStatus(productId: number, status: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.POST, `/api/product/update-status?productId=${productId}&status=${status}`, undefined, true);
  }

  static async deleteProduct(productId: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.POST, `/api/product/delete?productId=${productId}`, undefined, true);
  }

  static async getMyFavorites(): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, '/api/favorite/list', undefined, true);
  }

  static async addFavorite(productId: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.POST, `/api/favorite/add?productId=${productId}`, undefined, true);
  }

  static async removeFavorite(productId: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.POST, `/api/favorite/remove?productId=${productId}`, undefined, true);
  }

  static async checkFavorite(productId: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, `/api/favorite/check?productId=${productId}`, undefined, true);
  }

  static parseFavoriteList(data: Object): FavoriteItem[] {
    const arr: Object[] = data as Object[];
    const list: FavoriteItem[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: FavoriteItem = new FavoriteItem();
      item.id = (obj['id'] as number) ?? 0;
      item.productId = (obj['productId'] as number) ?? 0;
      item.productTitle = (obj['productTitle'] as string) ?? '';
      item.productPrice = (obj['productPrice'] as number) ?? 0;
      item.productStatus = (obj['productStatus'] as number) ?? 1;
      item.sellerName = (obj['sellerName'] as string) ?? '';
      item.createTime = (obj['createTime'] as string) ?? '';
      const imagesObj: Object = obj['productImages'];
      if (imagesObj !== null && imagesObj !== undefined) {
        try {
          const imgs: string = imagesObj as string;
          if (imgs.length > 0) {
            item.productImages = JSON.parse(imgs) as string[];
          }
        } catch (e) {
          item.productImages = [];
        }
      }
      list.push(item);
    }
    return list;
  }

  static async getBuildings(): Promise<string[]> {
    const result: ApiResult = await ApiService.request(http.RequestMethod.GET, '/api/classroom/buildings', undefined, false);
    if (result.code === 200 && result.data !== undefined) {
      return result.data as string[];
    }
    return [];
  }

  static async getRoomsByBuilding(building: string): Promise<string[]> {
    const result: ApiResult = await ApiService.request(http.RequestMethod.GET, `/api/classroom/rooms?building=${encodeURIComponent(building)}`, undefined, false);
    if (result.code === 200 && result.data !== undefined) {
      return result.data as string[];
    }
    return [];
  }

  static async getEmptyRooms(building: string, dayOfWeek: number, section: number, week: number): Promise<EmptyRoom[]> {
    let path: string = `/api/classroom/empty?dayOfWeek=${dayOfWeek}&section=${section}`;
    if (building.length > 0) {
      path += `&building=${encodeURIComponent(building)}`;
    }
    if (week > 0) {
      path += `&week=${week}`;
    }
    const result: ApiResult = await ApiService.request(http.RequestMethod.GET, path, undefined, false);
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      const list: EmptyRoom[] = [];
      for (const obj of arr) {
        const record: Record<string, Object> = obj as Record<string, Object>;
        const room: EmptyRoom = new EmptyRoom();
        room.id = (record['id'] as number) ?? 0;
        room.building = (record['building'] as string) ?? '';
        room.roomNo = (record['roomNo'] as string) ?? '';
        room.capacity = (record['capacity'] as number) ?? 0;
        room.hasProjector = (record['hasProjector'] as number) ?? 0;
        room.hasAc = (record['hasAc'] as number) ?? 0;
        room.type = (record['type'] as string) ?? '';
        list.push(room);
      }
      return list;
    }
    return [];
  }

  static async getRoomSchedule(classroom: string, dayOfWeek: number): Promise<CourseSchedule[]> {
    let path: string = `/api/classroom/schedule?classroom=${encodeURIComponent(classroom)}`;
    if (dayOfWeek > 0) {
      path += `&dayOfWeek=${dayOfWeek}`;
    }
    const result: ApiResult = await ApiService.request(http.RequestMethod.GET, path, undefined, false);
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      const list: CourseSchedule[] = [];
      for (const obj of arr) {
        const record: Record<string, Object> = obj as Record<string, Object>;
        const schedule: CourseSchedule = new CourseSchedule();
        schedule.courseName = (record['courseName'] as string) ?? '';
        schedule.teacherName = (record['teacher'] as string) ?? '';
        schedule.classroom = (record['classroom'] as string) ?? '';
        schedule.dayOfWeek = (record['dayOfWeek'] as number) ?? 1;
        schedule.startSection = (record['startSection'] as number) ?? 1;
        schedule.endSection = (record['endSection'] as number) ?? 2;
        schedule.startWeek = (record['startWeek'] as number) ?? 1;
        schedule.endWeek = (record['endWeek'] as number) ?? 16;
        list.push(schedule);
      }
      return list;
    }
    return [];
  }

  static async getLostFoundList(typeVal: number, keyword: string, page: number): Promise<LostFoundItem[]> {
    let path: string = `/api/lost-found/list?page=${page}&size=20`;
    if (typeVal > 0) {
      path += `&type=${typeVal}`;
    }
    if (keyword.length > 0) {
      path += `&keyword=${encodeURIComponent(keyword)}`;
    }
    const result: ApiResult = await ApiService.request(http.RequestMethod.GET, path, undefined, false);
    if (result.code === 200 && result.data !== undefined) {
      const arr: Object[] = result.data as Object[];
      const list: LostFoundItem[] = [];
      for (const obj of arr) {
        const record: Record<string, Object> = obj as Record<string, Object>;
        const item: LostFoundItem = new LostFoundItem();
        item.id = (record['id'] as number) ?? 0;
        item.userId = (record['userId'] as number) ?? 0;
        item.userName = (record['userName'] as string) ?? '';
        item.type = (record['type'] as number) ?? 1;
        item.title = (record['title'] as string) ?? '';
        item.description = (record['description'] as string) ?? '';
        item.images = (record['images'] as string) ?? '';
        item.locationDesc = (record['locationDesc'] as string) ?? '';
        item.category = (record['category'] as string) ?? '';
        const phoneObj: Object = record['contactPhone'];
        item.contactPhone = phoneObj !== null && phoneObj !== undefined ? (phoneObj as string) : '';
        item.status = (record['status'] as number) ?? 1;
        item.createTime = (record['createTime'] as string) ?? '';
        list.push(item);
      }
      return list;
    }
    return [];
  }

  static async publishLostFound(lf: LostFoundItem): Promise<ApiResult> {
    const body: Record<string, Object> = {
      'type': lf.type,
      'title': lf.title,
      'description': lf.description,
      'images': lf.images.length > 0 ? lf.images : '[]',
      'locationDesc': lf.locationDesc,
      'category': lf.category,
      'contactPhone': lf.contactPhone,
    };
    return ApiService.request(http.RequestMethod.POST, '/api/lost-found/publish', body, true);
  }

  static async deleteLostFound(id: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/lost-found/delete?id=${id}`, undefined, true);
  }

  static async getMyLostFoundList(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/lost-found/my-list', undefined, true);
  }

  static async getMyBrowseHistory(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/browse/my-history', undefined, true);
  }

  static async clearBrowseHistory(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, '/api/browse/clear', undefined, true);
  }

  static async changePassword(oldPassword: string, newPassword: string): Promise<ApiResult> {
    const body: Record<string, Object> = {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
    return ApiService.request(http.RequestMethod.POST, '/api/user/change-password', body, true);
  }

  static async updateName(name: string): Promise<ApiResult> {
    const body: Record<string, Object> = {
      'name': name,
    };
    return ApiService.request(http.RequestMethod.POST, '/api/user/update-name', body, true);
  }

  static async uploadAvatar(uri: string): Promise<string> {
    return ApiService.uploadFile('/api/user/upload-avatar', uri);
  }

  static async uploadClubCover(uri: string): Promise<string> {
    return ApiService.uploadFile('/api/club-activity/upload-cover', uri);
  }

  static async updateAvatar(avatar: string): Promise<ApiResult> {
    const body: Record<string, Object> = {
      'avatar': avatar,
    };
    return ApiService.request(http.RequestMethod.POST, '/api/user/update-avatar', body, true);
  }

  static async getClubActivityList(club: string, status: number, page: number, size: number): Promise<ApiResult> {
    let path: string = `/api/club-activity/list?page=${page}&size=${size}`;
    if (club.length > 0) {
      path += `&club=${encodeURIComponent(club)}`;
    }
    if (status > 0) {
      path += `&status=${status}`;
    }
    return ApiService.request(http.RequestMethod.GET, path, undefined, true);
  }

  static async getClubActivityDetail(id: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, `/api/club-activity/detail?id=${id}`, undefined, true);
  }

  static async publishClubActivity(params: Record<string, Object>): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, '/api/club-activity/publish', params, true);
  }

  static async registerClubActivity(activityId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/club-activity/register?activityId=${activityId}`, undefined, true);
  }

  static async cancelClubActivity(activityId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/club-activity/cancel?activityId=${activityId}`, undefined, true);
  }

  static async deleteClubActivity(activityId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/club-activity/delete?activityId=${activityId}`, undefined, true);
  }

  static async getMyPublishedClubActivities(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/club-activity/my-published', undefined, true);
  }

  static async getMyClubActivities(page: number, size: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, `/api/club-activity/my-activities?page=${page}&size=${size}`, undefined, true);
  }

  static async getCreditScore(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/complaint/credit-score', undefined, true);
  }

  static async submitComplaint(params: Record<string, Object>): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, '/api/complaint/submit', params, true);
  }

  static async getMyComplaints(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/complaint/my-complaints', undefined, true);
  }

  static async getOnlineUsers(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/chat/online-users', undefined, true);
  }

  static async submitFeedback(userName: string, contact: string, content: string): Promise<ApiResult> {
    const body: Record<string, string> = {
      'userName': userName,
      'contact': contact,
      'content': content
    };
    return ApiService.request(http.RequestMethod.POST, '/api/feedback/submit', body, false);
  }

  static async getConfessionList(category: string, page: number, size: number): Promise<ApiResult> {
    let url: string = `/api/confession-wall/list?page=${page}&size=${size}`;
    if (category.length > 0) {
      url = `${url}&category=${encodeURIComponent(category)}`;
    }
    return ApiService.request(http.RequestMethod.GET, url, undefined, true);
  }

  static async getConfessionDetail(id: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, `/api/confession-wall/detail?id=${id}`, undefined, true);
  }

  static async publishConfession(params: Record<string, Object>): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, '/api/confession-wall/publish', params, true);
  }

  static async deleteConfession(postId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/confession-wall/delete?postId=${postId}`, undefined, true);
  }

  static async likeConfession(postId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/confession-wall/like?postId=${postId}`, undefined, true);
  }

  static async commentConfession(postId: number, content: string, isAnonymous: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/confession-wall/comment?postId=${postId}&content=${encodeURIComponent(content)}&isAnonymous=${isAnonymous}`, undefined, true);
  }

  static async reportConfession(postId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/confession-wall/report?postId=${postId}`, undefined, true);
  }

  static async getMyConfessionPosts(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/confession-wall/my-posts', undefined, true);
  }

  static async uploadConfessionImage(uri: string): Promise<string> {
    return ApiService.uploadFile('/api/confession-wall/upload', uri);
  }

  static async getStudyShareList(courseName: string, category: string, page: number, size: number): Promise<ApiResult> {
    let url: string = `/api/study-share/list?page=${page}&size=${size}`;
    if (courseName.length > 0) {
      url = `${url}&courseName=${encodeURIComponent(courseName)}`;
    }
    if (category.length > 0) {
      url = `${url}&category=${encodeURIComponent(category)}`;
    }
    return ApiService.request(http.RequestMethod.GET, url, undefined, true);
  }

  static async getStudyShareDetail(id: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, `/api/study-share/detail?id=${id}`, undefined, true);
  }

  static async publishStudyShare(params: Record<string, Object>): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, '/api/study-share/publish', params, true);
  }

  static async deleteStudyShare(shareId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/study-share/delete?shareId=${shareId}`, undefined, true);
  }

  static async likeStudyShare(shareId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/study-share/like?shareId=${shareId}`, undefined, true);
  }

  static async favoriteStudyShare(shareId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/study-share/favorite?shareId=${shareId}`, undefined, true);
  }

  static async downloadStudyShare(shareId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/study-share/download?shareId=${shareId}`, undefined, true);
  }

  static async reportStudyShare(shareId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/study-share/report?shareId=${shareId}`, undefined, true);
  }

  static async getMyStudyShares(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/study-share/my-shares', undefined, true);
  }

  static async getMyStudyShareFavorites(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/study-share/my-favorites', undefined, true);
  }

  static async uploadStudyShareFile(uri: string): Promise<string> {
    return ApiService.uploadFile('/api/study-share/upload', uri);
  }

  static async uploadStudyShareCover(uri: string): Promise<string> {
    return ApiService.uploadFile('/api/study-share/upload-cover', uri);
  }

  static async getCarpoolList(destination: string, status: number, page: number, size: number): Promise<ApiResult> {
    let path: string = `/api/carpool/list?page=${page}&size=${size}`;
    if (destination.length > 0) {
      path += `&destination=${encodeURIComponent(destination)}`;
    }
    if (status >= 0) {
      path += `&status=${status}`;
    }
    return ApiService.request(http.RequestMethod.GET, path, undefined, true);
  }

  static async getCarpoolDetail(id: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, `/api/carpool/detail?id=${id}`, undefined, true);
  }

  static async publishCarpool(params: Record<string, Object>): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, '/api/carpool/publish', params, true);
  }

  static async joinCarpool(orderId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/carpool/join?orderId=${orderId}`, undefined, true);
  }

  static async cancelJoinCarpool(orderId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/carpool/cancel-join?orderId=${orderId}`, undefined, true);
  }

  static async cancelCarpool(orderId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/carpool/cancel?orderId=${orderId}`, undefined, true);
  }

  static async deleteCarpool(orderId: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, `/api/carpool/delete?orderId=${orderId}`, undefined, true);
  }

  static async getMyCarpoolOrders(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/carpool/my-orders', undefined, true);
  }

  static parseCarpoolOrders(data: Object): CarpoolOrder[] {
    const arr: Object[] = data as Object[];
    const list: CarpoolOrder[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: CarpoolOrder = new CarpoolOrder();
      item.id = (obj['id'] as number) ?? 0;
      item.userId = (obj['userId'] as number) ?? 0;
      item.publisherName = (obj['publisherName'] as string) ?? '';
      item.publisherAvatar = (obj['publisherAvatar'] as string) ?? '';
      item.departure = (obj['departure'] as string) ?? '';
      item.destination = (obj['destination'] as string) ?? '';
      item.departureTime = (obj['departureTime'] as string) ?? '';
      item.maxPassengers = (obj['maxPassengers'] as number) ?? 4;
      item.currentPassengers = (obj['currentPassengers'] as number) ?? 0;
      item.contactPhone = (obj['contactPhone'] as string) ?? '';
      item.remark = (obj['remark'] as string) ?? '';
      item.status = (obj['status'] as number) ?? 0;
      item.joined = (obj['joined'] as boolean) ?? false;
      item.createTime = (obj['createTime'] as string) ?? '';
      list.push(item);
    }
    return list;
  }

  static parsePassengers(data: Object): PassengerItem[] {
    const arr: Object[] = data as Object[];
    const list: PassengerItem[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: PassengerItem = new PassengerItem();
      item.userId = (obj['userId'] as number) ?? 0;
      item.nickname = (obj['nickname'] as string) ?? '';
      item.avatar = (obj['avatar'] as string) ?? '';
      list.push(item);
    }
    return list;
  }

  static parseClubActivityList(data: Object): ClubActivityItem[] {
    const arr: Object[] = data as Object[];
    const list: ClubActivityItem[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
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
      list.push(item);
    }
    return list;
  }

  static parseConfessionPostList(data: Object): ConfessionPost[] {
    const arr: Object[] = data as Object[];
    const list: ConfessionPost[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: ConfessionPost = new ConfessionPost();
      item.id = (obj['id'] as number) ?? 0;
      item.userId = (obj['userId'] as number) ?? 0;
      item.publisherName = (obj['publisherName'] as string) ?? '';
      item.publisherAvatar = (obj['publisherAvatar'] as string) ?? '';
      item.content = (obj['content'] as string) ?? '';
      const imgObj: Object = obj['images'];
      if (imgObj !== null && imgObj !== undefined) {
        const imgArr: Object[] = imgObj as Object[];
        item.images = [];
        for (let j = 0; j < imgArr.length; j++) {
          item.images.push(imgArr[j] as string);
        }
      }
      item.category = (obj['category'] as string) ?? '树洞';
      item.isAnonymous = (obj['isAnonymous'] as number) ?? 0;
      item.likeCount = (obj['likeCount'] as number) ?? 0;
      item.commentCount = (obj['commentCount'] as number) ?? 0;
      item.liked = (obj['liked'] as boolean) ?? false;
      item.status = (obj['status'] as number) ?? 0;
      item.createTime = (obj['createTime'] as string) ?? '';
      list.push(item);
    }
    return list;
  }

  static parseStudyShareList(data: Object): StudyShareItem[] {
    const arr: Object[] = data as Object[];
    const list: StudyShareItem[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: StudyShareItem = new StudyShareItem();
      item.id = (obj['id'] as number) ?? 0;
      item.userId = (obj['userId'] as number) ?? 0;
      item.uploaderName = (obj['uploaderName'] as string) ?? '';
      item.uploaderAvatar = (obj['uploaderAvatar'] as string) ?? '';
      item.title = (obj['title'] as string) ?? '';
      item.description = (obj['description'] as string) ?? '';
      item.courseName = (obj['courseName'] as string) ?? '';
      item.category = (obj['category'] as string) ?? '其他';
      item.fileUrl = (obj['fileUrl'] as string) ?? '';
      item.fileType = (obj['fileType'] as string) ?? '';
      item.fileSize = (obj['fileSize'] as number) ?? 0;
      item.coverImage = (obj['coverImage'] as string) ?? '';
      item.likeCount = (obj['likeCount'] as number) ?? 0;
      item.favoriteCount = (obj['favoriteCount'] as number) ?? 0;
      item.downloadCount = (obj['downloadCount'] as number) ?? 0;
      item.liked = (obj['liked'] as boolean) ?? false;
      item.favorited = (obj['favorited'] as boolean) ?? false;
      item.status = (obj['status'] as number) ?? 0;
      item.createTime = (obj['createTime'] as string) ?? '';
      list.push(item);
    }
    return list;
  }

  static async submitSafetyReport(params: Record<string, Object>): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.POST, '/api/safety/report', params, true);
  }

  static async getSafetyList(status: number, page: number, size: number): Promise<ApiResult> {
    let path: string = `/api/safety/list?page=${page}&size=${size}`;
    if (status >= 0) {
      path += `&status=${status}`;
    }
    return ApiService.request(http.RequestMethod.GET, path, undefined, true);
  }

  static async getSafetyDetail(id: number): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, `/api/safety/detail?id=${id}`, undefined, true);
  }

  static async handleSafetyReport(id: number, status: number, remark: string): Promise<ApiResult> {
    let path: string = `/api/safety/handle?id=${id}&status=${status}`;
    if (remark.length > 0) {
      path += `&remark=${encodeURIComponent(remark)}`;
    }
    return ApiService.request(http.RequestMethod.POST, path, undefined, true);
  }

  static async getMySafetyReports(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/safety/my-reports', undefined, true);
  }

  static async getSafetyContacts(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/safety/contacts', undefined, false);
  }

  static async uploadSafetyImage(uri: string): Promise<string> {
    return ApiService.uploadFile('/api/safety/upload', uri);
  }

  static parseSafetyReports(data: Object): SafetyReport[] {
    const arr: Object[] = data as Object[];
    const list: SafetyReport[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: SafetyReport = new SafetyReport();
      item.id = (obj['id'] as number) ?? 0;
      item.userId = (obj['userId'] as number) ?? 0;
      item.reporterName = (obj['reporterName'] as string) ?? '';
      item.reporterPhone = (obj['reporterPhone'] as string) ?? '';
      item.type = (obj['type'] as string) ?? '';
      item.location = (obj['location'] as string) ?? '';
      item.description = (obj['description'] as string) ?? '';
      const imgObj: Object = obj['images'];
      if (imgObj !== null && imgObj !== undefined) {
        const imgArr: Object[] = imgObj as Object[];
        item.images = [];
        for (let j = 0; j < imgArr.length; j++) {
          item.images.push(imgArr[j] as string);
        }
      }
      item.status = (obj['status'] as number) ?? 0;
      item.handlerId = (obj['handlerId'] as number) ?? 0;
      item.handlerName = (obj['handlerName'] as string) ?? '';
      item.handleRemark = (obj['handleRemark'] as string) ?? '';
      item.createTime = (obj['createTime'] as string) ?? '';
      item.handleTime = (obj['handleTime'] as string) ?? '';
      list.push(item);
    }
    return list;
  }

  static parseSafetyContacts(data: Object): SafetyContact[] {
    const arr: Object[] = data as Object[];
    const list: SafetyContact[] = [];
    for (let i = 0; i < arr.length; i++) {
      const obj: Record<string, Object> = arr[i] as Record<string, Object>;
      const item: SafetyContact = new SafetyContact();
      item.id = (obj['id'] as number) ?? 0;
      item.name = (obj['name'] as string) ?? '';
      item.phone = (obj['phone'] as string) ?? '';
      item.category = (obj['category'] as string) ?? '';
      list.push(item);
    }
    return list;
  }
}
