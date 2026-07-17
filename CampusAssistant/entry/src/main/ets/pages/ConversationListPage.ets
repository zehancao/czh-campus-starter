import { router } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { Conversation, ChatMessage } from '../model/Models';
import { WebSocketService, WsMessage, MessageCallback } from '../service/WebSocketService';

@Entry
@Component
struct ConversationListPage {
  @State private conversations: Conversation[] = [];
  @State private onlineUserIds: number[] = [];
  @State private keyword: string = '';
  @State private isLoggedIn: boolean = false;
  @State private isLoading: boolean = true;
  @State private errorMsg: string = '';
  private hasLoadedOnce: boolean = false;
  private wsCallback: MessageCallback | null = null;
  private refreshTimer: number = -1;

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (this.isLoggedIn) {
      this.registerWsCallback();
      WebSocketService.getInstance().connect();
      this.loadData();
      this.startPolling();
    } else {
      this.isLoading = false;
    }
  }

  aboutToDisappear(): void {
    if (this.wsCallback !== null) {
      WebSocketService.getInstance().removeMessageCallback(this.wsCallback);
      this.wsCallback = null;
    }
    this.stopPolling();
  }

  onPageShow(): void {
    if (this.hasLoadedOnce && this.isLoggedIn) {
      this.loadData(false);
    }
  }

  private startPolling(): void {
    this.stopPolling();
    this.refreshTimer = setInterval(() => {
      if (this.isLoggedIn && WebSocketService.getInstance().connectionState !== 'connected') {
        this.loadData(false);
      }
    }, 3000) as number;
  }

  private stopPolling(): void {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  private async loadData(showLoading: boolean = true): Promise<void> {
    if (showLoading || !this.hasLoadedOnce) {
      this.isLoading = true;
    }
    if (showLoading) {
      this.errorMsg = '';
    }
    const result = await ApiService.getConversations();
    if (result.code === 200 && result.data !== undefined) {
      this.conversations = ApiService.parseConversationList(result.data);
      this.errorMsg = '';
    } else if (showLoading) {
      this.errorMsg = result.msg || '会话加载失败';
    }
    const onlineResult = await ApiService.getOnlineUsers();
    if (onlineResult.code === 200 && onlineResult.data !== undefined) {
      this.onlineUserIds = onlineResult.data as number[];
    }
    this.hasLoadedOnce = true;
    this.isLoading = false;
  }

  private registerWsCallback(): void {
    if (this.wsCallback !== null) {
      return;
    }
    this.wsCallback = (msg: WsMessage) => {
      this.handleWsMessage(msg);
    };
    WebSocketService.getInstance().onMessage(this.wsCallback);
  }

  private handleWsMessage(msg: WsMessage): void {
    if (msg.type === 'user_status') {
      const data: Record<string, Object> = msg.data as Record<string, Object>;
      const uid: number = (data['userId'] as number) ?? 0;
      const online: boolean = (data['online'] as boolean) ?? false;
      this.updateOnlineUser(uid, online);
      return;
    }
    if (msg.type === 'online_users_loaded') {
      this.refreshOnlineUsersFromSocket();
      return;
    }
    if (msg.type === 'connection_state') {
      const data: Record<string, Object> = msg.data as Record<string, Object>;
      const state: string = (data['state'] as string) ?? '';
      if (state === 'connected') {
        this.loadData(false);
      }
      return;
    }
    if (msg.type === 'message') {
      const item: ChatMessage = this.parseWsChatMessage(msg.data);
      this.updateConversationByMessage(item);
      return;
    }
    if (msg.type === 'unread_update') {
      this.loadData(false);
    }
  }

  private parseWsChatMessage(data: Object): ChatMessage {
    const obj: Record<string, Object> = data as Record<string, Object>;
    const item: ChatMessage = new ChatMessage();
    item.id = (obj['id'] as number) ?? 0;
    item.conversationId = (obj['conversationId'] as number) ?? 0;
    item.senderId = (obj['senderId'] as number) ?? 0;
    item.content = (obj['content'] as string) ?? '';
    item.msgType = (obj['msgType'] as string) ?? 'text';
    item.createTime = (obj['createTime'] as string) ?? '';
    item.isMine = item.senderId === AppStore.getInstance().userInfo.id;
    return item;
  }

  private updateOnlineUser(userId: number, online: boolean): void {
    if (userId <= 0) {
      return;
    }
    const next: number[] = [];
    let exists: boolean = false;
    for (let i = 0; i < this.onlineUserIds.length; i++) {
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

  private refreshOnlineUsersFromSocket(): void {
    const next: number[] = [];
    for (let i = 0; i < this.conversations.length; i++) {
      const userId: number = this.conversations[i].otherUserId;
      if (WebSocketService.getInstance().isUserOnline(userId)) {
        next.push(userId);
      }
    }
    this.onlineUserIds = next;
  }

  private updateConversationByMessage(message: ChatMessage): void {
    if (message.conversationId <= 0) {
      return;
    }
    const next: Conversation[] = [];
    let found: boolean = false;
    for (let i = 0; i < this.conversations.length; i++) {
      const source: Conversation = this.conversations[i];
      if (source.id === message.conversationId) {
        const updated: Conversation = new Conversation();
        updated.id = source.id;
        updated.otherUserId = source.otherUserId;
        updated.otherUserName = source.otherUserName;
        updated.otherUserAvatar = source.otherUserAvatar;
        updated.lastMessage = message.content;
        updated.lastTime = message.createTime;
        updated.unreadCount = message.isMine ? source.unreadCount : source.unreadCount + 1;
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
      this.loadData(false);
    }
  }

  private isOnline(userId: number): boolean {
    for (let i = 0; i < this.onlineUserIds.length; i++) {
      if (this.onlineUserIds[i] === userId) {
        return true;
      }
    }
    return false;
  }

  private shouldShow(item: Conversation): boolean {
    const key: string = this.keyword.trim();
    if (key.length === 0) {
      return true;
    }
    return item.otherUserName.indexOf(key) >= 0 || item.lastMessage.indexOf(key) >= 0;
  }

  private formatTime(text: string): string {
    if (text.length === 0) {
      return '';
    }
    const value: string = text.replace('T', ' ');
    if (value.length >= 16) {
      return value.substring(5, 16);
    }
    return value;
  }

  private previewText(item: Conversation): string {
    if (item.lastMessage.length === 0) {
      return '暂无消息';
    }
    return item.lastMessage;
  }

  private markConversationReadLocally(conversationId: number): void {
    const nextList: Conversation[] = [];
    for (let i = 0; i < this.conversations.length; i++) {
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

  @Builder
  ConversationCell(item: Conversation) {
    if (this.shouldShow(item)) {
      Row() {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Text(item.otherUserName.length > 0 ? item.otherUserName.substring(0, 1) : '聊')
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            .width(48).height(48).borderRadius(24)
            .textAlign(TextAlign.Center)
            .backgroundColor('#2563EB')
          if (this.isOnline(item.otherUserId)) {
            Text('')
              .width(11).height(11).borderRadius(6)
              .backgroundColor('#22C55E')
              .border({ width: 2, color: '#FFFFFF' })
          }
        }.width(50).height(50)

        Column() {
          Row() {
            Text(item.otherUserName.length > 0 ? item.otherUserName : '用户')
              .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#111827')
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(this.formatTime(item.lastTime))
              .fontSize(12).fontColor('#9CA3AF')
          }.width('100%')
          Row() {
            Text(this.previewText(item))
              .fontSize(14).fontColor(item.unreadCount > 0 ? '#374151' : '#9CA3AF')
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            if (item.unreadCount > 0) {
              Text(item.unreadCount > 99 ? '99+' : item.unreadCount.toString())
                .fontSize(11).fontColor('#FFFFFF').textAlign(TextAlign.Center)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(10).backgroundColor('#EF4444')
                .margin({ left: 8 })
            }
          }.width('100%').margin({ top: 6 })
        }.layoutWeight(1).margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor('#FFFFFF')
      .onClick(() => { this.goChat(item) })
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor('#374151').width(34).onClick(() => { router.back() })
        Text('会话').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#111827')
        Blank()
        Text('刷新').fontSize(14).fontColor('#2563EB').onClick(() => { this.loadData() })
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 12, bottom: 10 })
      .backgroundColor('#FFFFFF')

      if (!this.isLoggedIn) {
        Column() {
          Text('请先登录').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#111827')
          Text('登录后可以查看买卖双方的会话').fontSize(14).fontColor('#6B7280').margin({ top: 8 })
          Button('去登录')
            .type(ButtonType.Capsule).backgroundColor('#2563EB').fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }) })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#2563EB')
          Text('正在加载会话').fontSize(14).fontColor('#6B7280').margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.errorMsg.length > 0) {
        Column() {
          Text(this.errorMsg).fontSize(16).fontColor('#6B7280')
          Button('重试')
            .type(ButtonType.Capsule).backgroundColor('#2563EB').fontColor('#FFFFFF')
            .margin({ top: 18 })
            .onClick(() => { this.loadData() })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Column() {
          TextInput({ placeholder: '搜索联系人或消息', text: this.keyword })
            .height(40).fontSize(14).backgroundColor('#F3F4F6').borderRadius(20)
            .margin({ left: 16, right: 16, top: 12, bottom: 12 })
            .onChange((value: string) => { this.keyword = value })

          if (this.conversations.length === 0) {
            Column() {
              Text('暂无会话').fontSize(18).fontWeight(FontWeight.Medium).fontColor('#111827')
              Text('从商品详情页联系卖家后，会话会显示在这里').fontSize(14).fontColor('#6B7280').margin({ top: 8 })
            }
            .width('100%')
            .padding({ top: 40, left: 16, right: 16 })
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.conversations, (item: Conversation) => {
                ListItem() {
                  Column() {
                    this.ConversationCell(item)
                    Divider().height(1).color('#F3F4F6').margin({ left: 78 })
                  }.width('100%')
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
    .backgroundColor('#FFFFFF')
  }
}
