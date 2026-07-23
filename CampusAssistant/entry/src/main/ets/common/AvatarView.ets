import { ApiService } from '../service/ApiService';
import { Theme } from './Theme';

@Component
export struct AvatarView {
  @Prop avatar: string = '';
  @Prop name: string = '';
  avatarSize: number = 40;

  private isImageUrl(url: string): boolean {
    return url.startsWith('/') || url.startsWith('http') || url.startsWith('https');
  }

  build() {
    if (this.isImageUrl(this.avatar)) {
      Image(this.avatar.startsWith('/') ? `${ApiService.baseUrl}${this.avatar}` : this.avatar)
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .objectFit(ImageFit.Cover)
    } else if (this.avatar.length > 0) {
      Text(this.avatar)
        .fontSize(this.avatarSize * 0.5)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .backgroundColor(Theme.primary)
    } else {
      Text(this.name.length > 0 ? this.name[0] : 'U')
        .fontSize(this.avatarSize * 0.5)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .backgroundColor(Theme.primary)
    }
  }
}
