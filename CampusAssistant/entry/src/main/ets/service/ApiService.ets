import { http } from '@kit.NetworkKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { AppStore } from './AppStore';
import { UserInfo, CourseSchedule, Product, Announcement, Conversation, ChatMessage, Semester, PickerOption, ProductCategory, FavoriteItem, EmptyRoom, LostFoundItem } from '../model/Models';

export interface ApiResult {
  code: number;
  msg: string;
  data: Object | undefined;
}

export class ApiService {
  static baseUrl: string = 'http://192.168.1.3:8080';

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
      connectTimeout: 15000
    };
    if (data !== undefined) {
      options.extraData = JSON.stringify(data);
    }
    try {
      const req: http.HttpRequest = http.createHttp();
      const response: http.HttpResponse = await req.request(url, options);
      req.destroy();
      const resultStr: string = response.result as string;
      const result: ApiResult = JSON.parse(resultStr) as ApiResult;
      return result;
    } catch (err) {
      const errResult: ApiResult = { code: -1, msg: '网络错误，请检查后端是否启动', data: undefined };
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

  static async getProductList(categoryId: number): Promise<ApiResult> {
    return await ApiService.request(http.RequestMethod.GET, `/api/product/list?categoryId=${categoryId}`, undefined, false);
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

  static async uploadImage(uri: string): Promise<string> {
    const srcUri: fileUri.FileUri = new fileUri.FileUri(uri);
    const srcPath: string = srcUri.path;
    if (srcPath.length === 0) {
      return 'ERROR:srcPath_empty';
    }
    const store: AppStore = AppStore.getInstance();
    if (store.context === undefined) {
      return 'ERROR:context_undefined';
    }
    const cacheDir: string = store.context.cacheDir;
    const fileName: string = `upload_${Date.now()}_${Math.random().toString(36).substring(2, 8)}.jpg`;
    const destPath: string = `${cacheDir}/${fileName}`;
    fileIo.copyFileSync(srcPath, destPath);
    const url: string = `${ApiService.baseUrl}/api/product/upload-image`;
    const req: http.HttpRequest = http.createHttp();
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
          contentType: 'image/jpeg',
          remoteFileName: fileName
        }
      ]
    });
    req.destroy();
    const resultStr: string = response.result as string;
    const result: ApiResult = JSON.parse(resultStr) as ApiResult;
    if (result.code === 200 && result.data !== undefined) {
      return result.data as string;
    }
    return `ERROR:code_${result.code}_msg_${result.msg}`;
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
        const imgs: string = imagesObj as string;
        if (imgs.length > 0) {
          const cleaned: string = imgs.replace('[', '').replace(']', '').replace(new RegExp('"', 'g'), '');
          if (cleaned.length > 0) {
            item.productImages = cleaned.split(',');
          }
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

  static async uploadAvatar(uri: string): Promise<string> {    const srcUri: fileUri.FileUri = new fileUri.FileUri(uri);
    const srcPath: string = srcUri.path;
    if (srcPath.length === 0) {
      return 'ERROR:srcPath_empty';
    }
    const store: AppStore = AppStore.getInstance();
    if (store.context === undefined) {
      return 'ERROR:context_undefined';
    }
    const cacheDir: string = store.context.cacheDir;
    const fileName: string = `avatar_${Date.now()}_${Math.random().toString(36).substring(2, 8)}.jpg`;
    const destPath: string = `${cacheDir}/${fileName}`;
    fileIo.copyFileSync(srcPath, destPath);
    const url: string = `${ApiService.baseUrl}/api/user/upload-avatar`;
    const req: http.HttpRequest = http.createHttp();
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
          contentType: 'image/jpeg',
          remoteFileName: fileName
        }
      ]
    });
    req.destroy();
    const resultStr: string = response.result as string;
    const result: ApiResult = JSON.parse(resultStr) as ApiResult;
    if (result.code === 200 && result.data !== undefined) {
      return result.data as string;
    }
    return `ERROR:code_${result.code}_msg_${result.msg}`;
  }

  static async getClubActivityList(club: string, status: number): Promise<ApiResult> {
    let path: string = '/api/club-activity/list?';
    if (club.length > 0) {
      path += `club=${encodeURIComponent(club)}&`;
    }
    if (status > 0) {
      path += `status=${status}`;
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

  static async getMyClubActivities(): Promise<ApiResult> {
    return ApiService.request(http.RequestMethod.GET, '/api/club-activity/my-activities', undefined, true);
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
}
