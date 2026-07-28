import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { ChatMessage } from '../model/Models';
import { WebSocketService, WsMessage, MessageCallback } from '../service/WebSocketService';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';

class ProductCardMessage {
  productId: number = 0;
  title: string = '';
  price: number = 0;
  image: string = '';
  status: number = 1;
}

@Entry
@Component
struct ChatPage {
  @State private conversationId: number = 0;
  @State private otherUserId: number = 0;
  @State private productId: number = 0;
  @State private otherUserName: string = '聊天';
  @State private messages: ChatMessage[] = [];
  @State private inputText: string = '';
  @State private isLoggedIn: boolean = false;
  @State private isLoading: boolean = true;
  @State private isSending: boolean = false;
  @State private isOtherUserOnline: boolean = false;
  @State private errorMsg: string = '';
  @State private showImagePreview: boolean = false;
  @State private previewImageUrl: string = '';
  @State private showMorePanel: boolean = false;
  private wsCallback: MessageCallback | null = null;
  private messageTimer: number = -1;
  private onlineTimer: number = -1;
  private messageScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (!this.isLoggedIn) {
      this.isLoading = false;
      return;
    }
    this.resolveParams();
    this.registerWsCallback();
    WebSocketService.getInstance().connect();
    this.loadOnlineStatus();
    this.prepareConversation();
    this.startPolling();
  }

  aboutToDisappear(): void {
    if (this.wsCallback !== null) {
      WebSocketService.getInstance().removeMessageCallback(this.wsCallback);
      this.wsCallback = null;
    }
    this.stopPolling();
  }

  private startPolling(): void {
    this.stopPolling();
    this.messageTimer = setInterval(() => {
      if (this.isLoggedIn && this.conversationId > 0 && WebSocketService.getInstance().connectionState !== 'connected') {
        this.loadMessages(false);
      }
    }, 2000) as number;
    this.onlineTimer = setInterval(() => {
      if (this.isLoggedIn && this.otherUserId > 0 && WebSocketService.getInstance().connectionState !== 'connected') {
        this.loadOnlineStatus();
      }
    }, 3000) as number;
  }

  private stopPolling(): void {
    if (this.messageTimer !== -1) {
      clearInterval(this.messageTimer);
      this.messageTimer = -1;
    }
    if (this.onlineTimer !== -1) {
      clearInterval(this.onlineTimer);
      this.onlineTimer = -1;
    }
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
      if (uid === this.otherUserId) {
        this.isOtherUserOnline = (data['online'] as boolean) ?? false;
      }
      return;
    }
    if (msg.type === 'online_users_loaded' || msg.type === 'connection_state') {
      const online: boolean = WebSocketService.getInstance().isUserOnline(this.otherUserId);
      if (online) {
        this.isOtherUserOnline = true;
      }
      return;
    }
    if (msg.type === 'message') {
      const item: ChatMessage = this.parseWsChatMessage(msg.data);
      if (item.conversationId === this.conversationId && item.conversationId > 0) {
        this.appendOrUpdateMessage(item);
        WebSocketService.getInstance().sendMarkRead(this.conversationId);
      }
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

  private appendOrUpdateMessage(item: ChatMessage): void {
    const next: ChatMessage[] = [];
    let exists: boolean = false;
    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].id === item.id && item.id > 0) {
        next.push(item);
        exists = true;
      } else {
        next.push(this.messages[i]);
      }
    }
    if (!exists) {
      next.push(item);
    }
    this.messages = next;
    this.errorMsg = '';
    this.isLoading = false;
    this.scrollToBottom();
  }

  private scrollToBottom(): void {
    if (this.messages.length === 0) {
      return;
    }
    setTimeout(() => {
      try {
        this.messageScroller.scrollToIndex(this.messages.length - 1, true, ScrollAlign.END);
      } catch (e) {
      }
    }, 50);
  }

  private getParamText(params: Record<string, Object>, key: string): string {
    const value: Object = params[key];
    if (value === null || value === undefined) {
      return '';
    }
    if (typeof value === 'number') {
      return (value as number).toString();
    }
    return value as string;
  }

  private parseNumberParam(params: Record<string, Object>, key: string): number {
    const text: string = this.getParamText(params, key);
    if (text.length === 0) {
      return 0;
    }
    const value: number = Number(text);
    if (isNaN(value)) {
      return 0;
    }
    return value;
  }

  private resolveParams(): void {
    let paramsObj: Object | undefined = undefined;
    try {
      paramsObj = router.getParams();
    } catch (e) {
      paramsObj = undefined;
    }
    if (paramsObj !== undefined && paramsObj !== null) {
      const params: Record<string, Object> = paramsObj as Record<string, Object>;
      this.conversationId = this.parseNumberParam(params, 'conversationId');
      this.otherUserId = this.parseNumberParam(params, 'otherUserId');
      this.productId = this.parseNumberParam(params, 'productId');
      const name: string = this.getParamText(params, 'otherUserName');
      if (name.length > 0) {
        this.otherUserName = name;
      }
    }
  }

  private async loadOnlineStatus(): Promise<void> {
    if (this.otherUserId <= 0) {
      this.isOtherUserOnline = false;
      return;
    }
    if (WebSocketService.getInstance().isUserOnline(this.otherUserId)) {
      this.isOtherUserOnline = true;
      return;
    }
    const result = await ApiService.getOnlineUsers();
    if (result.code === 200 && result.data !== undefined) {
      const ids: number[] = result.data as number[];
      let online: boolean = false;
      for (let i = 0; i < ids.length; i++) {
        if (ids[i] === this.otherUserId) {
          online = true;
          break;
        }
      }
      this.isOtherUserOnline = online;
    } else {
      this.isOtherUserOnline = false;
    }
  }

  private async prepareConversation(): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';
    if (this.conversationId > 0) {
      await this.loadMessages();
      return;
    }
    if (this.otherUserId <= 0 || this.productId <= 0) {
      this.errorMsg = '缺少会话参数';
      this.isLoading = false;
      return;
    }
    const result = await ApiService.createConversation(this.otherUserId, this.productId);
    if (result.code === 200 && result.data !== undefined) {
      const data: Object = result.data;
      if (typeof data === 'number') {
        this.conversationId = data as number;
      } else {
        const record: Record<string, Object> = data as Record<string, Object>;
        const conversationValue: Object = record['conversationId'];
        if (conversationValue !== null && conversationValue !== undefined) {
          if (typeof conversationValue === 'number') {
            this.conversationId = conversationValue as number;
          } else {
            const parsedId: number = Number(conversationValue as string);
            this.conversationId = isNaN(parsedId) ? 0 : parsedId;
          }
        } else {
          this.conversationId = (record['id'] as number) ?? 0;
        }
      }
      if (this.conversationId > 0) {
        await this.loadMessages();
      } else {
        this.errorMsg = '会话创建失败';
        this.isLoading = false;
      }
    } else {
      this.errorMsg = result.msg || '会话创建失败';
      this.isLoading = false;
    }
  }

  private async loadMessages(showError: boolean = true): Promise<void> {
    if (this.conversationId <= 0) {
      if (showError) {
        this.errorMsg = '会话不存在';
      }
      this.isLoading = false;
      return;
    }
    const result = await ApiService.getMessages(this.conversationId);
    if (result.code === 200 && result.data !== undefined) {
      const list: ChatMessage[] = ApiService.parseMessageList(result.data);
      const currentUserId: number = AppStore.getInstance().userInfo.id;
      for (let i = 0; i < list.length; i++) {
        list[i].isMine = list[i].senderId === currentUserId;
      }
      this.messages = list;
      this.errorMsg = '';
      WebSocketService.getInstance().sendMarkRead(this.conversationId);
      this.scrollToBottom();
    } else if (showError) {
      this.errorMsg = result.msg || '消息加载失败';
    }
    this.isLoading = false;
  }

  private async sendText(): Promise<void> {
    const content: string = this.inputText.trim();
    if (content.length === 0 || this.isSending) {
      return;
    }
    if (this.conversationId <= 0) {
      AlertDialog.show({ message: '会话还没有创建成功', confirm: { value: '好的', action: () => {} } });
      return;
    }
    this.isSending = true;
    const sent: boolean = await this.sendChatContent(content, 'text');
    if (sent) {
      this.inputText = '';
      this.showMorePanel = false;
    }
    this.isSending = false;
  }

  private async sendChatContent(content: string, msgType: string): Promise<boolean> {
    if (this.conversationId <= 0) {
      AlertDialog.show({ message: '会话还没有创建成功', confirm: { value: '好的', action: () => {} } });
      return false;
    }
    if (WebSocketService.getInstance().connectionState === 'connected') {
      WebSocketService.getInstance().sendMessage(this.conversationId, content, msgType);
      return true;
    }
    const result = await ApiService.sendMessage(this.conversationId, content, msgType);
    if (result.code === 200) {
      await this.loadMessages();
      return true;
    }
    AlertDialog.show({ title: '发送失败', message: result.msg || '请稍后重试', confirm: { value: '好的', action: () => {} } });
    return false;
  }

  private async sendImage(): Promise<void> {
    if (this.isSending) {
      return;
    }
    if (this.conversationId <= 0) {
      AlertDialog.show({ message: '会话还没有创建成功', confirm: { value: '好的', action: () => {} } });
      return;
    }
    try {
      const uris: string[] = await ApiService.pickImages();
      if (uris.length === 0) {
        return;
      }
      this.isSending = true;
      this.showMorePanel = false;
      promptAction.showToast({ message: '正在发送图片', duration: 1200 });
      const url: string = await ApiService.uploadChatMedia(uris[0]);
      if (url.startsWith('ERROR:')) {
        AlertDialog.show({ title: '发送失败', message: '图片上传失败，请重试', confirm: { value: '好的', action: () => {} } });
      } else {
        await this.sendChatContent(url, 'image');
      }
    } catch (err) {
      AlertDialog.show({ message: '相册无法打开，请用真机或模拟器运行', confirm: { value: '知道了', action: () => {} } });
    } finally {
      this.isSending = false;
    }
  }

  private async sendVideo(): Promise<void> {
    if (this.isSending) {
      return;
    }
    if (this.conversationId <= 0) {
      AlertDialog.show({ message: '会话还没有创建成功', confirm: { value: '好的', action: () => {} } });
      return;
    }
    try {
      const uris: string[] = await ApiService.pickVideos();
      if (uris.length === 0) {
        return;
      }
      this.isSending = true;
      this.showMorePanel = false;
      promptAction.showToast({ message: '正在发送视频', duration: 1200 });
      const url: string = await ApiService.uploadChatMedia(uris[0]);
      if (url.startsWith('ERROR:')) {
        AlertDialog.show({ title: '发送失败', message: '视频上传失败，请重试', confirm: { value: '好的', action: () => {} } });
      } else {
        await this.sendChatContent(url, 'video');
      }
    } catch (err) {
      AlertDialog.show({ message: '视频选择无法打开，请用真机或模拟器运行', confirm: { value: '知道了', action: () => {} } });
    } finally {
      this.isSending = false;
    }
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

  private normalizeImageUrl(path: string): string {
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('file://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return `${ApiService.baseUrl}${path}`;
    }
    return path;
  }

  private openImagePreview(url: string): void {
    this.previewImageUrl = this.normalizeImageUrl(url);
    this.showImagePreview = true;
  }

  private parseProductCard(content: string): ProductCardMessage {
    const card: ProductCardMessage = new ProductCardMessage();
    try {
      const obj: Record<string, Object> = JSON.parse(content) as Record<string, Object>;
      const idObj: Object = obj['productId'];
      if (typeof idObj === 'number') {
        card.productId = idObj as number;
      } else if (idObj !== null && idObj !== undefined) {
        const id: number = Number(idObj as string);
        card.productId = isNaN(id) ? 0 : id;
      }
      card.title = (obj['title'] as string) ?? '';
      const priceObj: Object = obj['price'];
      if (typeof priceObj === 'number') {
        card.price = priceObj as number;
      } else if (priceObj !== null && priceObj !== undefined) {
        const price: number = Number(priceObj as string);
        card.price = isNaN(price) ? 0 : price;
      }
      card.image = (obj['image'] as string) ?? '';
      card.status = (obj['status'] as number) ?? 1;
    } catch (e) {
      card.title = content;
    }
    return card;
  }

  private productCardId(content: string): number {
    return this.parseProductCard(content).productId;
  }

  private productCardTitle(content: string): string {
    const title: string = this.parseProductCard(content).title;
    return title.length > 0 ? title : '商品卡片';
  }

  private productCardPrice(content: string): string {
    return `¥${this.parseProductCard(content).price.toFixed(2)}`;
  }

  private productCardImage(content: string): string {
    return this.parseProductCard(content).image;
  }

  private displayContent(item: ChatMessage): string {
    if (item.msgType === 'product') {
      const card: ProductCardMessage = this.parseProductCard(item.content);
      return card.title.length > 0 ? `商品卡片：${card.title}` : '商品卡片';
    }
    if (item.msgType === 'image') {
      return '[图片]';
    }
    if (item.msgType === 'video') {
      return '[视频]';
    }
    return item.content;
  }

  @Builder
  MessageContent(item: ChatMessage) {
    if (item.msgType === 'image') {
      Image(this.normalizeImageUrl(item.content))
        .width(168)
        .height(168)
        .borderRadius(12)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#FFFFFF')
        .onClick(() => { this.openImagePreview(item.content) })
    } else if (item.msgType === 'video') {
      Row() {
        Text('▶')
          .fontSize(22)
          .fontColor(Theme.primary)
          .width(42)
          .height(42)
          .borderRadius(21)
          .textAlign(TextAlign.Center)
          .backgroundColor(Theme.primaryLight)
        Column() {
          Text('视频')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.textPrimary)
          Text('已发送视频文件')
            .fontSize(12)
            .fontColor(Theme.textTertiary)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width(188)
      .padding(10)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .border({ width: 1, color: Theme.border })
    } else if (item.msgType === 'product') {
      this.ProductCard(item)
    } else {
      Text(item.content)
        .fontSize(15)
        .fontColor(item.isMine ? '#FFFFFF' : Theme.textPrimary)
        .padding({ left: 12, right: 12, top: 9, bottom: 9 })
        .backgroundColor(item.isMine ? Theme.primary : '#FFFFFF')
        .borderRadius(14)
        .maxLines(8)
    }
  }

  @Builder
  ProductCard(item: ChatMessage) {
    Column() {
      Row() {
        if (this.productCardImage(item.content).length > 0) {
          Image(this.normalizeImageUrl(this.productCardImage(item.content)))
            .width(64)
            .height(64)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .backgroundColor(Theme.bgInput)
        } else {
          Column() {
            Text('商').fontSize(22).fontWeight(FontWeight.Bold).fontColor(Theme.primary)
          }
          .width(64)
          .height(64)
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Theme.primaryLight)
        }
        Column() {
          Text(this.productCardTitle(item.content))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.textPrimary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.productCardPrice(item.content))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.primary)
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      Text('查看商品详情')
        .fontSize(12)
        .fontColor(Theme.textTertiary)
        .margin({ top: 8 })
    }
    .width(238)
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: Theme.border })
    .onClick(() => {
      const id: number = this.productCardId(item.content);
      if (id > 0) {
        router.pushUrl({
          url: 'pages/ProductDetailPage',
          params: { 'productId': id.toString() } as Record<string, string>
        });
      }
    })
  }

  @Builder
  ImagePreviewOverlay() {
    Column() {
      Row() {
        Text('✕')
          .fontSize(22)
          .fontColor('#FFFFFF')
          .margin({ left: 16 })
          .onClick(() => { this.showImagePreview = false })
        Blank()
      }
      .width('100%')
      .height(56)

      Image(this.previewImageUrl)
        .width('100%')
        .layoutWeight(1)
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .position({ x: 0, y: 0 })
  }

  @Builder
  MessageBubble(item: ChatMessage) {
    Row() {
      if (item.isMine) {
        Blank()
        Column() {
          this.MessageContent(item)
          Text(this.formatTime(item.createTime))
            .fontSize(11).fontColor(Theme.textTertiary).margin({ top: 4, right: 4 })
        }.alignItems(HorizontalAlign.End).constraintSize({ maxWidth: '76%' })
      } else {
        Column() {
          this.MessageContent(item)
          Text(this.formatTime(item.createTime))
            .fontSize(11).fontColor(Theme.textTertiary).margin({ top: 4, left: 4 })
        }.alignItems(HorizontalAlign.Start).constraintSize({ maxWidth: '76%' })
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 7, bottom: 7 })
  }

  @Builder
  MoreActionItem(label: string, icon: string, actionType: number) {
    Column() {
      Text(icon)
        .fontSize(22)
        .fontColor(Theme.primary)
        .width(54)
        .height(54)
        .textAlign(TextAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(14)
        .border({ width: 1, color: Theme.border })
      Text(label)
        .fontSize(12)
        .fontColor(Theme.textSecondary)
        .margin({ top: 6 })
    }
    .width(76)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (actionType === 1) {
        this.sendImage();
      } else if (actionType === 2) {
        this.sendVideo();
      }
    })
  }

  @Builder
  MorePanel() {
    Row({ space: 14 }) {
      this.MoreActionItem('图片', '图', 1)
      this.MoreActionItem('视频', '视', 2)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 16 })
    .backgroundColor(Theme.bgPage)
  }

  build() {
    Stack() {
      Column() {
        NavHeader({ title: this.otherUserName }) {
          Text('刷新').fontSize(14).fontColor(Theme.primary).onClick(() => {
            this.isLoading = true;
            this.loadOnlineStatus();
            this.loadMessages();
          })
        }
        Row() {
          Text('')
            .width(7).height(7).borderRadius(4)
            .backgroundColor(this.isOtherUserOnline ? Theme.success : Theme.textTertiary)
            .margin({ right: 5 })
          Text(this.isOtherUserOnline ? '在线' : '离线')
            .fontSize(11).fontColor(this.isOtherUserOnline ? Theme.success : Theme.textSecondary)
          if (this.productId > 0) {
            Text('  商品 #' + this.productId.toString()).fontSize(11).fontColor(Theme.textSecondary)
          }
          Blank()
          if (this.otherUserId > 0 && this.otherUserId !== AppStore.getInstance().userInfo.id) {
            Button('投诉')
              .type(ButtonType.Capsule)
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor(Theme.danger)
              .height(28)
              .padding({ left: 14, right: 14 })
              .onClick(() => {
                const params: Record<string, Object> = {
                  'defendantId': this.otherUserId,
                  'defendantName': this.otherUserName
                }
                if (this.productId > 0) {
                  params['productId'] = this.productId
                }
                router.pushUrl({ url: 'pages/MyComplaintsPage', params: params })
              })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 8 })
        .backgroundColor('#FFFFFF')

        if (!this.isLoggedIn) {
          Column() {
            Text('请先登录').fontSize(20).fontWeight(FontWeight.Bold).fontColor(Theme.textPrimary)
            Text('登录后可以联系卖家').fontSize(14).fontColor(Theme.textSecondary).margin({ top: 8 })
            Button('去登录')
              .type(ButtonType.Capsule).backgroundColor(Theme.primary).fontColor('#FFFFFF')
              .margin({ top: 20 })
              .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }) })
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40).color(Theme.primary)
            Text('正在加载消息').fontSize(14).fontColor(Theme.textSecondary).margin({ top: 12 })
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else if (this.errorMsg.length > 0) {
          Column() {
            Text(this.errorMsg).fontSize(16).fontColor(Theme.textSecondary)
            Button('重试')
              .type(ButtonType.Capsule).backgroundColor(Theme.primary).fontColor('#FFFFFF')
              .margin({ top: 18 })
              .onClick(() => { this.prepareConversation() })
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          List({ scroller: this.messageScroller }) {
            if (this.messages.length === 0) {
              ListItem() {
                Column() {
                  Text('还没有消息').fontSize(16).fontColor(Theme.textSecondary)
                  Text('发送第一条消息开始沟通').fontSize(13).fontColor(Theme.textTertiary).margin({ top: 6 })
                }
                .width('100%')
                .padding({ top: 40, left: 16, right: 16 })
                .alignItems(HorizontalAlign.Center)
              }
            } else {
              ForEach(this.messages, (item: ChatMessage) => {
                ListItem() {
                  this.MessageBubble(item)
                }
              }, (item: ChatMessage) => item.id.toString())
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ top: 8, bottom: 8 })
          .backgroundColor(Theme.bgPage)

          Column() {
            Row() {
              Button() {
                Text('+')
                  .fontSize(26)
                  .fontColor(this.isSending ? Theme.textTertiary : Theme.primary)
              }
              .type(ButtonType.Normal)
              .width(40)
              .height(40)
              .backgroundColor(this.showMorePanel ? Theme.bgHover : Theme.primaryLight)
              .borderRadius(20)
              .enabled(!this.isSending)
              .onClick(() => { this.showMorePanel = !this.showMorePanel })
              TextInput({ placeholder: '输入消息', text: this.inputText })
                .height(42).fontSize(15).backgroundColor(Theme.bgInput).borderRadius(21)
                .layoutWeight(1)
                .margin({ left: 8 })
                .onChange((value: string) => { this.inputText = value })
                .onSubmit(() => { this.sendText() })
              Button(this.isSending ? '发送中' : '发送')
                .type(ButtonType.Capsule)
                .height(40)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor(this.inputText.trim().length > 0 ? Theme.primary : Theme.textTertiary)
                .margin({ left: 10 })
                .enabled(this.inputText.trim().length > 0 && !this.isSending)
                .onClick(() => { this.sendText() })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor('#FFFFFF')
            if (this.showMorePanel) {
              this.MorePanel()
            }
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.bgPage)

      if (this.showImagePreview) {
        this.ImagePreviewOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
}
