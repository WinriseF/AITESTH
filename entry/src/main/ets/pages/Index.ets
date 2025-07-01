// 文件路径: src/main/ets/pages/Index.ts
// 这个文件现在是应用的主入口和容器

import { HomePage } from './HomePage';
import { QuizBankPage } from './QuizBankPage';
import router from '@ohos.router';

// 为导航栏项目定义一个明确的接口
interface NavTabInfo {
  label: string;
  icon: Resource;
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
    .padding({ top: 8, bottom: 8 })
    .justifyContent(FlexAlign.Center)
  }
}

@Entry
@Component
struct Index {
  @State private currentIndex: number = 0;
  @State private quizBankRefreshCounter: number = 0;

  private swiperController: SwiperController = new SwiperController();

  // 【修复】使用新定义的接口来声明数组类型
  private navTabs: NavTabInfo[] = [
    { label: '首页', icon: $r('app.media.icon_home') },
    { label: '题库', icon: $r('app.media.icon_quiz') },
    { label: '错题', icon: $r('app.media.icon_mistake') },
    { label: '报告', icon: $r('app.media.icon_report') },
    { label: '我的', icon: $r('app.media.icon_profile') }
  ];

  build() {
    Column() {
      // Swiper 作为内容区域，可以左右滑动
      Swiper(this.swiperController) {
        // 第1页: 首页
        HomePage()

        // 第2页: 题库
        QuizBankPage()

        // 其他页面的占位符
        Text('错题本页面').width('100%').height('100%').fontSize(30).textAlign(TextAlign.Center).backgroundColor(Color.Pink)
        Text('学习报告页面').width('100%').height('100%').fontSize(30).textAlign(TextAlign.Center).backgroundColor(Color.Orange)
        Text('我的主页').width('100%').height('100%').fontSize(30).textAlign(TextAlign.Center).backgroundColor(Color.Yellow)
      }
      .indicator(false) // 隐藏默认的指示点
      .loop(false)
      .onChange((index: number) => {
        // 当用户手动滑动Swiper时，更新底部导航栏的状态
        this.currentIndex = index;
      })
      .layoutWeight(1) // 让Swiper占据所有剩余空间

      // 底部导航栏
      Row() {
        ForEach(this.navTabs, (item: NavTabInfo, index: number) => {
          NavItem({
            isSelected: this.currentIndex === index,
            label: item.label,
            icon: item.icon
          })
            .onClick(() => {
              // 点击导航项时，切换Swiper的页面
              this.currentIndex = index;
              this.swiperController.changeIndex(this.currentIndex);
              if (index === 1) {
                this.quizBankRefreshCounter++;
              }
            })
        }, (item: NavTabInfo) => item.label) // 使用label作为唯一的key
      }
      .width('100%')
      .height(64)
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#F0F0F0' })
      .padding({ bottom: 'env(safe-area-inset-bottom)' }) // 适配底部安全区域
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%').height('100%')
  }
}
