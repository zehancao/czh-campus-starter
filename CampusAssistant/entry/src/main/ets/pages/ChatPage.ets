import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ApiService } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { ChatMessage } from '../model/Models';

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

  aboutToAppear(): void {
    const store: AppStore = AppStore.getInstance();
    this.isLoggedIn = store.isLoggedIn;
    if (!this.isLoggedIn) {
      this.isLoading = false;
      return;
    }
    this.resolveParams();
    this.loadOnlineStatus();
    this.prepareConversation();
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

  private async loadMessages(): Promise<void> {
    if (this.conversationId <= 0) {
      this.errorMsg = '会话不存在';
      this.isLoading = false;
      return;
    }
    const result = await ApiService.getMessages(this.conversationId);
    if (result.code === 200 && result.data !== undefined) {
      this.messages = ApiService.parseMessageList(result.data);
      this.errorMsg = '';
    } else {
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
    const result = await ApiService.sendMessage(this.conversationId, content, 'text');
    if (result.code === 200) {
      this.inputText = '';
      await this.loadMessages();
    } else {
      AlertDialog.show({ title: '发送失败', message: result.msg || '请稍后重试', confirm: { value: '好的', action: () => {} } });
    }
    this.isSending = false;
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

  private displayContent(item: ChatMessage): string {
    if (item.msgType === 'product') {
      return '商品卡片：' + item.content;
    }
    if (item.msgType === 'image') {
      return '[图片]';
    }
    return item.content;
  }

  @Builder
  MessageBubble(item: ChatMessage) {
    Row() {
      if (item.isMine) {
        Blank()
        Column() {
          Text(this.displayContent(item))
            .fontSize(15)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 9, bottom: 9 })
            .backgroundColor('#2563EB')
            .borderRadius(14)
            .maxLines(8)
          Text(this.formatTime(item.createTime))
            .fontSize(11).fontColor('#9CA3AF').margin({ top: 4, right: 4 })
        }.alignItems(HorizontalAlign.End).constraintSize({ maxWidth: '76%' })
      } else {
        Column() {
          Text(this.displayContent(item))
            .fontSize(15)
            .fontColor('#111827')
            .padding({ left: 12, right: 12, top: 9, bottom: 9 })
            .backgroundColor('#FFFFFF')
            .borderRadius(14)
            .maxLines(8)
          Text(this.formatTime(item.createTime))
            .fontSize(11).fontColor('#9CA3AF').margin({ top: 4, left: 4 })
        }.alignItems(HorizontalAlign.Start).constraintSize({ maxWidth: '76%' })
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 7, bottom: 7 })
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor('#374151').width(34).onClick(() => { router.back() })
        Column() {
          Text(this.otherUserName).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#111827')
          Row() {
            Text('')
              .width(7).height(7).borderRadius(4)
              .backgroundColor(this.isOtherUserOnline ? '#22C55E' : '#9CA3AF')
              .margin({ right: 5 })
            Text(this.isOtherUserOnline ? '在线' : '离线')
              .fontSize(11)
              .fontColor(this.isOtherUserOnline ? '#16A34A' : '#6B7280')
          }.margin({ top: 2 })
          if (this.productId > 0) {
            Text('商品 #' + this.productId.toString()).fontSize(11).fontColor('#6B7280').margin({ top: 2 })
          }
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Text('刷新').fontSize(14).fontColor('#2563EB').onClick(() => {
          this.isLoading = true;
          this.loadOnlineStatus();
          this.loadMessages();
        })
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 10, bottom: 10 })
      .backgroundColor('#FFFFFF')

      if (!this.isLoggedIn) {
        Column() {
          Text('请先登录').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#111827')
          Text('登录后可以联系卖家').fontSize(14).fontColor('#6B7280').margin({ top: 8 })
          Button('去登录')
            .type(ButtonType.Capsule).backgroundColor('#2563EB').fontColor('#FFFFFF')
            .margin({ top: 20 })
            .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }) })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#2563EB')
          Text('正在加载消息').fontSize(14).fontColor('#6B7280').margin({ top: 12 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.errorMsg.length > 0) {
        Column() {
          Text(this.errorMsg).fontSize(16).fontColor('#6B7280')
          Button('重试')
            .type(ButtonType.Capsule).backgroundColor('#2563EB').fontColor('#FFFFFF')
            .margin({ top: 18 })
            .onClick(() => { this.prepareConversation() })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          if (this.messages.length === 0) {
            ListItem() {
              Column() {
                Text('还没有消息').fontSize(16).fontColor('#6B7280')
                Text('发送第一条消息开始沟通').fontSize(13).fontColor('#9CA3AF').margin({ top: 6 })
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
        .backgroundColor('#F3F4F6')

        Row() {
          TextInput({ placeholder: '输入消息', text: this.inputText })
            .height(42).fontSize(15).backgroundColor('#F3F4F6').borderRadius(21)
            .layoutWeight(1)
            .onChange((value: string) => { this.inputText = value })
            .onSubmit(() => { this.sendText() })
          Button(this.isSending ? '发送中' : '发送')
            .type(ButtonType.Capsule)
            .height(40)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(this.inputText.trim().length > 0 ? '#2563EB' : '#9CA3AF')
            .margin({ left: 10 })
            .enabled(this.inputText.trim().length > 0 && !this.isSending)
            .onClick(() => { this.sendText() })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }
}
