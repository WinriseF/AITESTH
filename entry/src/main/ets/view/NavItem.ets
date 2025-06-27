@Component
export struct NavItem {
  @Prop isSelected: boolean = false;
  label: string = '';
  icon: Resource = $r('app.media.icon_home');

  build() {
    Column({ space: 4 }) {
      Image(this.icon)
        .width(24).height(24)
        .fillColor(this.isSelected ? '#6A67EA' : '#888888')
      Text(this.label)
        .fontSize(10)
        .fontWeight(this.isSelected ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.isSelected ? '#6A67EA' : '#888888')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}