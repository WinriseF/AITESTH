@Styles function baseCardStyle() {
  .backgroundColor(Color.White)
  .borderRadius(16)
  .padding(20)
  .shadow({ radius: 8, color: '#20000000', offsetX: 0, offsetY: 2 })
}

// 底部导航栏单个项目的组件
@Component
struct NavItem {
  // @Prop装饰器允许父组件向子组件传递数据
  @Prop isSelected: boolean = false;
  label: string = '';
  icon: Resource = $r('app.media.iconhome');

  build() {
    Column({ space: 4 }) {
      Image(this.icon)
        .width(24).height(24)
        .fillColor(this.isSelected ? '#6A67EA' : '#999999') // 选中和未选中颜色
      Text(this.label)
        .fontSize(10)
        .fontColor(this.isSelected ? '#6A67EA' : '#999999')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}

@Entry
@Component
struct Index {
  // --- 状态变量定义 ---
  @State questionCount: number = 20;
  @State selectedDifficulty: string = '中等';
  @State selectedTab: string = '首页'; // 用于控制底部导航栏的选中状态

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 主内容区域
      Column() {
        // 1. 顶部栏 (Header)
        Row() {
          Text('logo')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#6A67EA')
          Blank()
          Text('IT 开发')
            .fontSize(18).fontWeight(FontWeight.Medium)
        }
        .width('100%').height(56).padding({ left: 20, right: 20 }).backgroundColor(Color.White)

        // 2. 主体内容滚动区 (对应HTML的 main-content)
        Scroll() {
          Column({ space: 16 }) {
            // 2.1 课程选择卡片 (subject-selection)
            Row({ space: 16 }) {
              // IT开发
              Column({ space: 8 }) {
                Text('IT 开发').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                Text('已完成 45%').fontSize(12).fontColor(Color.White).opacity(0.9)
                Progress({ value: 45, type: ProgressType.Linear }).color(Color.White).margin({ top: 4 })
              }
              .padding(16).borderRadius(16).layoutWeight(1)
              .linearGradient({ angle: 135, colors: [['#4D81F3', 0], ['#60A5FA', 1]] })
              .shadow({ radius: 6, color: '#304D81F3' })

              // 金融理财
              Column({ space: 8 }) {
                Text('金融理财').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                Text('已完成 30%').fontSize(12).fontColor(Color.White).opacity(0.9)
                Progress({ value: 30, type: ProgressType.Linear }).color(Color.White).margin({ top: 4 })
              }
              .padding(16).borderRadius(16).layoutWeight(1)
              .linearGradient({ angle: 135, colors: [['#8C52FF', 0], ['#C56EFF', 1]] })
              .shadow({ radius: 6, color: '#308C52FF' })
            }

            // 2.2 智能练习卡片 (practice-card)
            Column({ space: 12 }) {
              Text('开始智能练习').fontSize(18).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start)
              Text('AI 将为您生成专业题目').fontSize(13).fontColor(Color.Gray).alignSelf(ItemAlign.Start)
                .margin({ top: -8, bottom: 8 })

              Row() {
                Text('题目数量').fontSize(14)
                Blank()
                Text(`${this.questionCount.toFixed(0)}题`).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#6A67EA')
              }
              Slider({ value: this.questionCount, min: 5, max: 50, step: 1, style: SliderStyle.OutSet })
                .blockColor('#6A67EA').trackColor('#E5E7F0').selectedColor('#6A67EA')
                .onChange((value: number) => { this.questionCount = value; })

              Text('难度等级').fontSize(14).alignSelf(ItemAlign.Start).margin({ top: 8 })
              Row({ space: 10 }) {
                ForEach(['简单', '中等', '困难'], (item: string) => {
                  Button(item)
                    .backgroundColor(this.selectedDifficulty === item ? '#6A67EA' : '#F3F4F6')
                    .fontColor(this.selectedDifficulty === item ? Color.White : Color.Black)
                    .fontWeight(this.selectedDifficulty === item ? FontWeight.Bold : FontWeight.Normal)
                    .layoutWeight(1).height(40).type(ButtonType.Normal)
                    .onClick(() => { this.selectedDifficulty = item; })
                })
              }
              .width('100%')

              Button('开始')
                .width('100%').height(48).fontSize(16).fontWeight(FontWeight.Bold).backgroundColor('#6A67EA').margin({ top: 12 })
            }
            .baseCardStyle()

            // 2.3 学习数据卡片 (data-card)
            Column({ space: 16 }) {
              Row() {
                Text('学习数据').fontSize(18).fontWeight(FontWeight.Bold)
                Blank()
                Text('查看详情 >').fontSize(13).fontColor(Color.Gray)
              }
              Row({ space: 20 }) {
                Column({ space: 8 }) {
                  Text('答题正确率').fontSize(14)
                  Stack({ alignContent: Alignment.Center }) {
                    Progress({ value: 85, type: ProgressType.Ring }).width(90).style({ strokeWidth: 10 }).color('#4D81F3')
                    Text('85%').fontSize(20).fontWeight(FontWeight.Bold)
                  }
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)

                Column({ space: 8 }) {
                  Text('知识点掌握').fontSize(14)
                  Row({ space: 24 }) {
                    Rect().width(25).height(50).fill('#A9C0F8').radius(4)
                    Rect().width(25).height(80).fill('#4D81F3').radius(4)
                  }.alignItems(VerticalAlign.Bottom).height(80)
                }.layoutWeight(1).alignItems(HorizontalAlign.Center)
              }
            }
            .baseCardStyle()

            // 2.4 智能推荐卡片 (data-card)
            Column({ space: 12 }) {
              Row() {
                Text('智能推荐').fontSize(18).fontWeight(FontWeight.Bold)
                Blank()
                Text('更多 >').fontSize(13).fontColor(Color.Gray)
              }
              // ... 这里可以循环渲染推荐列表 ...
            }
            .baseCardStyle()

          }
          .padding(16) // 对应HTML的 .container
        }
      }
      .backgroundColor('#F4F6F8')

      // 底部导航栏 (bottom-nav)
      Row() {
        // 使用我们上面定义的NavItem组件
        NavItem({ isSelected: this.selectedTab === '首页', icon: $r('app.media.iconhome'), label: '首页' })
          .onClick(() => { this.selectedTab = '首页' })
        NavItem({ isSelected: this.selectedTab === '题库', icon: $r('app.media.iconbook'), label: '题库' })
          .onClick(() => { this.selectedTab = '题库' })
        NavItem({ isSelected: this.selectedTab === '错题', icon: $r('app.media.iconwrite'), label: '错题' })
          .onClick(() => { this.selectedTab = '错题' })
        NavItem({ isSelected: this.selectedTab === '报告', icon: $r('app.media.iconreport'), label: '报告' })
          .onClick(() => { this.selectedTab = '报告' })
        NavItem({ isSelected: this.selectedTab === '我的', icon: $r('app.media.iconmy'), label: '我的' })
          .onClick(() => { this.selectedTab = '我的' })
      }
      .width('100%').height(60).backgroundColor(Color.White).padding({ top: 5 })
      .shadow({ radius: 10, color: '#1F000000', offsetY: -2 })
    }
  }
}