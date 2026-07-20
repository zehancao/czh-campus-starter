export class UserInfo {
  id: number = 0;
  studentId: string = '';
  name: string = '';
  avatar: string = '';
  college: string = '';
  major: string = '';
  grade: string = '';
  classId: number = 0;
  className: string = '';
  hometown: string = '';
  phone: string = '';
  role: string = 'student';
  creditScore: number = 100;
}

export class CourseSchedule {
  id: number = 0;
  courseName: string = '';
  classroom: string = '';
  dayOfWeek: number = 1;
  startSection: number = 1;
  endSection: number = 2;
  startWeek: number = 1;
  endWeek: number = 16;
  weekParity: string = 'all';
  teacherName: string = '';
  colorIndex: number = 0;
  source: string = 'class';
}

export class Product {
  id: number = 0;
  sellerId: number = 0;
  sellerName: string = '';
  categoryId: number = 0;
  categoryName: string = '';
  title: string = '';
  description: string = '';
  price: number = 0;
  originalPrice: number = 0;
  conditionLevel: number = 1;
  images: string[] = [];
  status: number = 1;
  viewCount: number = 0;
  campusLocation: string = '';
  createTime: string = '';
}

export class Announcement {
  id: number = 0;
  title: string = '';
  summary: string = '';
  category: string = '';
  isTop: number = 0;
  publishTime: string = '';
}

export class ChatMessage {
  id: number = 0;
  conversationId: number = 0;
  senderId: number = 0;
  content: string = '';
  msgType: string = 'text';
  createTime: string = '';
  isMine: boolean = false;
}

export class Conversation {
  id: number = 0;
  otherUserId: number = 0;
  otherUserName: string = '';
  otherUserAvatar: string = '';
  lastMessage: string = '';
  lastTime: string = '';
  unreadCount: number = 0;
  productId: number = 0;
}

export class ClassOption {
  id: number = 0;
  name: string = '';
}

export class Semester {
  id: number = 0;
  name: string = '';
  startDate: string = '';
  endDate: string = '';
  weekCount: number = 16;
  isCurrent: number = 0;
}

export class PickerOption {
  id: number = 0;
  name: string = '';
}

export class ProductCategory {
  id: number = 0;
  name: string = '';
  icon: string = '';
  parentId: number = 0;
  sortOrder: number = 0;
}

export class FavoriteItem {
  id: number = 0;
  productId: number = 0;
  productTitle: string = '';
  productPrice: number = 0;
  productImages: string[] = [];
  productStatus: number = 1;
  sellerName: string = '';
  createTime: string = '';
}

export class EmptyRoom {
  id: number = 0;
  building: string = '';
  roomNo: string = '';
  capacity: number = 0;
  hasProjector: number = 0;
  hasAc: number = 0;
  type: string = '';
}

export class LostFoundItem {
  id: number = 0;
  userId: number = 0;
  userName: string = '';
  type: number = 1;
  title: string = '';
  description: string = '';
  images: string = '';
  locationDesc: string = '';
  category: string = '';
  contactPhone: string = '';
  status: number = 1;
  createTime: string = '';
}

export interface DetailParams {
  id: string;
  type: string;
}

export class ClubActivityItem {
  id: number = 0;
  userId: number = 0;
  userName: string = '';
  club: string = '';
  title: string = '';
  description: string = '';
  venue: string = '';
  activityTime: string = '';
  maxParticipants: number = 20;
  currentParticipants: number = 0;
  status: number = 1;
  createTime: string = '';
  registered: boolean = false;
  participantNames: string[] = [];
}
