// 文件路径: src/main/ets/pages/Index.ets

// 定义卡片样式
@Styles function aitesCardStyle() {
  .backgroundColor(Color.White)
  .borderRadius(24)
  .padding(20)
  .shadow({ radius: 20, color: '#1A000000', offsetX: 0, offsetY: 4 })
}

// 底部导航栏单个项目的子组件
@Component
struct NavItem {
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
    // ✅ 修正：移除了内部的 .layoutWeight(1)，因为它应该在外部使用
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

@Entry
@Component
struct Index {
  @State questionCount: number = 20;
  @State selectedDifficulty: string = '中等';
  @State selectedTab: string = '首页';

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 第一层：页面主内容
      Column() {
        // 1. 顶部栏
        Row() {
          Text('logo').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#6A67EA')
          Blank()
          Text('IT 开发').fontSize(18).fontWeight(FontWeight.Bold)
        }
        .width('100%').height(56).padding({ left: 24, right: 24 })

        // 2. 可滚动的主体
        Scroll() {
          Column({ space: 16 }) {
            // 2.1 课程选择卡片
            Row({ space: 16 }) {
              Column({ space: 8 }) {
                Text('IT 开发').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                Text('已完成 45%').fontSize(12).fontColor(Color.White).opacity(0.9)
                Progress({ value: 45, type: ProgressType.Linear }).color(Color.White).margin({ top: 10 })
              }.padding(20).borderRadius(20).layoutWeight(1).linearGradient({ angle: 135, colors: [['#4D81F3', 0], ['#818CF8', 1]] }).shadow({ radius: 10, color: '#304D81F3' })
              Column({ space: 8 }) {
                Text('金融理财').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                Text('已完成 30%').fontSize(12).fontColor(Color.White).opacity(0.9)
                Progress({ value: 30, type: ProgressType.Linear }).color(Color.White).margin({ top: 10 })
              }.padding(20).borderRadius(20).layoutWeight(1).linearGradient({ angle: 135, colors: [['#8C52FF', 0], ['#C084FC', 1]] }).shadow({ radius: 10, color: '#308C52FF' })
            }

            // 2.2 智能练习卡片
            Column({ space: 16 }) {
              Text('开始智能练习').fontSize(18).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start)
              Text('AI 将为您生成专业题目').fontSize(13).fontColor(Color.Gray).alignSelf(ItemAlign.Start)
              Divider().strokeWidth(1).color('#F0F0F0').margin({ top: 4, bottom: 4})
              Row() {
                Text('题目数量').fontSize(14)
                Blank()
                Text(`${this.questionCount.toFixed(0)}题`).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#6A67EA')
              }
              Slider({ value: this.questionCount, min: 5, max: 50, step: 1, style: SliderStyle.OutSet })
                .blockColor('#6A67EA').trackColor('#E5E7F0').selectedColor('#6A67EA')
                .onChange((value: number) => { this.questionCount = value; })
              Text('难度等级').fontSize(14).alignSelf(ItemAlign.Start)
              Row({ space: 10 }) {
                ForEach(['简单', '中等', '困难'], (item: string) => {
                  Button(item)
                    .backgroundColor(this.selectedDifficulty === item ? '#6A67EA' : '#F3F4F6')
                    .fontColor(this.selectedDifficulty === item ? Color.White : Color.Black)
                    .fontWeight(this.selectedDifficulty === item ? FontWeight.Bold : FontWeight.Normal)
                    .layoutWeight(1).height(40).type(ButtonType.Normal).borderRadius(20)
                    .onClick(() => { this.selectedDifficulty = item; })
                })
              }
              .width('100%')
              Button('开始')
                .width('100%').height(50).fontSize(16).fontWeight(FontWeight.Bold)
                .backgroundColor('#6A67EA').borderRadius(25).margin({ top: 12 })
            }.aitesCardStyle()

            // 2.3 学习数据卡片
            Column({ space: 16 }) {
              Row() {
                Text('学习数据').fontSize(18).fontWeight(FontWeight.Bold)
                Blank()
                Text('查看详情 >').fontSize(13).fontColor(Color.Gray)
              }
              Row({ space: 20 }) {
                Column({ space: 10 }) {
                  Text('答题正确率').fontSize(14).fontColor(Color.Gray)
                  Stack({ alignContent: Alignment.Center }) {
                    Progress({ value: 85, type: ProgressType.Ring }).width(100).height(100).style({ strokeWidth: 12 }).color('#4D81F3')
                    Text('85%').fontSize(24).fontWeight(FontWeight.Bold)
                  }
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)
                Column({ space: 10 }) {
                  Text('知识点掌握').fontSize(14).fontColor(Color.Gray)
                  Row({ space: 24 }) {
                    Rect().width(28).height(60).fill('#A9C0F8').radius(6)
                    Rect().width(28).height(100).fill('#4D81F3').radius(6)
                  }.alignItems(VerticalAlign.Bottom).height(100)
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)
              }
            }.aitesCardStyle()
          }
          .padding({left: 16, right: 16, top: 10, bottom: 120}) // 增加更多底部边距
        }
      }
      .width('100%').height('100%').backgroundColor('#F4F6F8')

      // --- 第二层：底部悬浮导航栏 (已修正) ---
      Row() {
        // ✅ 修正：将 .layoutWeight(1) 应用在 NavItem 的调用上，而不是其内部
        NavItem({ isSelected: this.selectedTab === '首页', icon: $r('app.media.icon_home'), label: '首页' })
          .layoutWeight(1).onClick(() => { this.selectedTab = '首页' })
        NavItem({ isSelected: this.selectedTab === '题库', icon: $r('app.media.icon_quiz'), label: '题库' })
          .layoutWeight(1).onClick(() => { this.selectedTab = '题库' })
        NavItem({ isSelected: this.selectedTab === '错题', icon: $r('app.media.icon_mistake'), label: '错题' })
          .layoutWeight(1).onClick(() => { this.selectedTab = '错题' })
        NavItem({ isSelected: this.selectedTab === '报告', icon: $r('app.media.icon_report'), label: '报告' })
          .layoutWeight(1).onClick(() => { this.selectedTab = '报告' })
        NavItem({ isSelected: this.selectedTab === '我的', icon: $r('app.media.icon_profile'), label: '我的' })
          .layoutWeight(1).onClick(() => { this.selectedTab = '我的' })
      }
      .width('90%')
      .height(64)
      .padding({left: 8, right: 8}) // 调整内边距
      .backgroundColor(Color.White)
      .borderRadius(32)
      .shadow({ radius: 15, color: '#2A000000', offsetY: 5 })
      .margin({ bottom: 34 }) // 使用margin来制造与屏幕安全区的间距

    }
    .width('100%').height('100%')
  }
}