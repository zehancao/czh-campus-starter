import { ApiService, ApiResult } from '../service/ApiService';
import { AppStore } from '../service/AppStore';
import { UserInfo } from '../model/Models';
import { router } from '@kit.ArkUI';
import { Theme, ShadowStyle } from '../common/Theme';
import { NavHeader } from '../common/NavHeader';
import { AvatarView } from '../common/AvatarView';

@Entry
@Component
struct EditProfilePage {
  @State private user: UserInfo = new UserInfo();
  @State private avatar: string = '';
  @State private userName: string = '';
  @State private isUploading: boolean = false;
  @State private isSavingName: boolean = false;
  @State private showAvatarSheet: boolean = false;
  @State private errorMsg: string = '';
  private emojiList: string[] = ['🐱','🐶','🦊','🐼','🐨','🦁','🐯','🐸','🦉','🐲','🌸','🌻','🍀','🌙','⭐','💎','🦋','🐝','🐙','🐧'];

  aboutToAppear(): void {
    this.initUser();
  }

  private initUser(): void {
    const source: UserInfo = AppStore.getInstance().userInfo;
    const copy: UserInfo = new UserInfo();
    copy.id = source.id;
    copy.studentId = source.studentId;
    copy.name = source.name;
    copy.avatar = source.avatar;
    copy.college = source.college;
    copy.major = source.major;
    copy.grade = source.grade;
    copy.classId = source.classId;
    copy.className = source.className;
    copy.hometown = source.hometown;
    copy.phone = source.phone;
    copy.role = source.role;
    copy.creditScore = source.creditScore;
    this.user = copy;
    this.avatar = copy.avatar;
    this.userName = copy.name;
  }

  private updateLocalUser(nextName: string, nextAvatar: string): void {
    const next: UserInfo = this.user;
    next.name = nextName;
    next.avatar = nextAvatar;
    this.user = next;
    AppStore.getInstance().setUserInfo(next);
  }

  private showAvatarOptions(): void {
    if (this.isUploading) {
      return;
    }
    this.showAvatarSheet = true;
  }

  private async uploadFromAlbum(): Promise<void> {
    if (this.isUploading) {
      return;
    }
    this.errorMsg = '';
    this.showAvatarSheet = false;
    this.isUploading = true;
    try {
      const uris: string[] = await ApiService.pickImages();
      if (uris.length > 0) {
        const url: string = await ApiService.uploadAvatar(uris[0]);
        if (url.length > 0 && !url.startsWith('ERROR:')) {
          this.avatar = url;
          this.updateLocalUser(this.userName, this.avatar);
          this.getUIContext().getPromptAction().showToast({ message: '头像已更新' });
        } else {
          this.errorMsg = '头像上传失败';
        }
      }
    } catch (_err) {
      this.errorMsg = '头像上传失败';
    } finally {
      this.isUploading = false;
    }
  }

  private async selectEmoji(emoji: string): Promise<void> {
    if (this.isUploading) {
      return;
    }
    this.showAvatarSheet = false;
    this.isUploading = true;
    try {
      const result: ApiResult = await ApiService.updateAvatar(emoji);
      if (result.code === 200) {
        this.avatar = emoji;
        this.updateLocalUser(this.userName, this.avatar);
        this.getUIContext().getPromptAction().showToast({ message: '头像已更新' });
      } else {
        this.errorMsg = result.msg.length > 0 ? result.msg : '设置失败';
      }
    } catch (_err) {
      this.errorMsg = '头像设置失败';
    } finally {
      this.isUploading = false;
    }
  }

  private async saveUserName(): Promise<void> {
    if (this.isSavingName) {
      return;
    }
    const nextName: string = this.userName.trim();
    if (nextName.length === 0) {
      this.errorMsg = '用户名不能为空';
      return;
    }
    this.errorMsg = '';
    this.isSavingName = true;
    const result: ApiResult = await ApiService.updateName(nextName);
    if (result.code === 200) {
      this.userName = nextName;
      this.updateLocalUser(nextName, this.avatar);
      this.getUIContext().getPromptAction().showToast({ message: '用户名已保存' });
    } else {
      this.errorMsg = result.msg.length > 0 ? result.msg : '保存失败';
    }
    this.isSavingName = false;
  }

  build() {
    Stack() {
      Column() {
        NavHeader({ title: '编辑资料' })

        Scroll() {
          Column() {
            Column() {
              Stack() {
                AvatarView({ avatar: this.avatar, name: this.userName, avatarSize: 96 })
                Column() {
                  Text('📷').fontSize(13)
                }
                .width(26)
                .height(26)
                .borderRadius(13)
                .backgroundColor('rgba(0,0,0,0.5)')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .offset({ x: 30, y: 30 })
              }
              .width(96)
              .height(96)
              .onClick(() => {
                this.showAvatarOptions();
              })

              Text(this.isUploading ? '上传中...' : this.userName)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.isUploading ? Theme.primary : Theme.textPrimary)
                .margin({ top: 12 })

              Text(this.isUploading ? '' : '点击头像可更换')
                .fontSize(12)
                .fontColor(Theme.textTertiary)
                .margin({ top: 4 })
            }
            .width('100%')
            .padding({ top: 34, bottom: 30 })
            .backgroundColor(Theme.bgCard)
            .alignItems(HorizontalAlign.Center)
            .borderRadius(Theme.heroRadius)
            .shadow(ShadowStyle.nmRaisedLg)

            Column() {
              Row() {
                Text('用户名')
                  .fontSize(15)
                  .fontColor(Theme.textPrimary)
                  .width(76)
                TextInput({ placeholder: '请输入用户名', text: this.userName })
                  .layoutWeight(1)
                  .height(44)
                  .fontSize(15)
                  .fontColor(Theme.textPrimary)
                  .placeholderColor(Theme.textDisabled)
                  .textAlign(TextAlign.End)
                  .backgroundColor(Color.Transparent)
                  .padding({ left: 8, right: 0 })
                  .onChange((value: string) => {
                    this.userName = value;
                    this.errorMsg = '';
                  })
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })

              Row()
                .width('100%')
                .height(0.5)
                .margin({ left: 16 })
                .backgroundColor(Theme.border)

              Row() {
                Text('修改密码')
                  .fontSize(15)
                  .fontColor(Theme.textPrimary)
                Blank()
                Text('›')
                  .fontSize(22)
                  .fontColor(Theme.textDisabled)
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/PasswordChangePage' });
              })
            }
            .width('100%')
            .backgroundColor(Theme.bgCard)
            .borderRadius(Theme.cardRadius)
            .margin({ top: 16 })
            .shadow(ShadowStyle.nmRaised)

            if (this.errorMsg.length > 0) {
              Text(this.errorMsg)
                .fontSize(13)
                .fontColor(Theme.danger)
                .width('100%')
                .textAlign(TextAlign.Center)
                .margin({ top: 12 })
            }

            Button(this.isSavingName ? '保存中...' : '保存修改')
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor(Theme.primary)
              .borderRadius(24)
              .margin({ top: 30 })
              .shadow(ShadowStyle.sm)
              .enabled(!this.isSavingName)
              .onClick(() => {
                this.saveUserName();
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 40 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.bgPage)

      if (this.showAvatarSheet) {
        this.AvatarSheet()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  AvatarSheet() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.28)')
        .onClick(() => {
          this.showAvatarSheet = false;
        })

      Column() {
        Text('修改头像')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.textPrimary)
          .width('100%')
          .padding({ left: 24, right: 24, top: 22, bottom: 14 })

        Row() {
          Text('从相册选择')
            .fontSize(16)
            .fontColor(Theme.textPrimary)
          Blank()
          Text('›')
            .fontSize(22)
            .fontColor(Theme.textDisabled)
        }
        .width('100%')
        .height(56)
        .padding({ left: 24, right: 24 })
        .onClick(() => {
          this.uploadFromAlbum();
        })

        Text('选择表情做头像')
          .fontSize(13)
          .fontColor(Theme.textSecondary)
          .width('100%')
          .padding({ left: 24, right: 24, top: 12, bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.emojiList, (emoji: string) => {
            Text(emoji)
              .fontSize(26)
              .width(44)
              .height(44)
              .textAlign(TextAlign.Center)
              .backgroundColor(Theme.bgInput)
              .borderRadius(10)
              .margin({ right: 10, bottom: 10 })
              .onClick(() => {
                this.selectEmoji(emoji);
              })
          }, (emoji: string) => emoji)
        }
        .width('100%')
        .padding({ left: 24, right: 24, bottom: 12 })

        Row()
          .width('100%')
          .height(8)
          .backgroundColor(Theme.bgPage)

        Text('取消')
          .fontSize(16)
          .fontColor(Theme.textSecondary)
          .width('100%')
          .height(56)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.showAvatarSheet = false;
          })
      }
      .width('100%')
      .backgroundColor(Theme.bgCard)
      .borderRadius({ topLeft: 28, topRight: 28 })
      .shadow(ShadowStyle.nmRaisedLg)
    }
    .width('100%')
    .height('100%')
  }
}
