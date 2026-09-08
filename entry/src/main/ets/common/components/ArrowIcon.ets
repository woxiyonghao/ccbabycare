/**
 * 全局通用方向箭头组件
 * 使用用户指定的高清透明 PNG 箭头资源
 */
@Component
export struct ArrowIcon {
  arrowDirection: 'right' | 'left' = 'right';
  variant: 'gray' | 'orange' | 'dark' = 'gray';
  iconSize: number = 14;

  private getIconResource(): Resource {
    if (this.arrowDirection === 'left') {
      if (this.variant === 'dark') {
        return $r('app.media.ic_arrow_left_dark');
      }
      return $r('app.media.ic_arrow_left');
    }

    // 默认右箭头
    if (this.variant === 'orange') {
      return $r('app.media.ic_arrow_right_orange');
    }
    return $r('app.media.ic_arrow_right');
  }

  build() {
    Image(this.getIconResource())
      .width(this.iconSize)
      .height(this.iconSize)
      .objectFit(ImageFit.Contain)
  }
}
