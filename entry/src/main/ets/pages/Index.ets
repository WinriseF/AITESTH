import { promptAction } from '@kit.ArkUI';
import UUID from '@kingtous/uuid';
import router from '@ohos.router';
import { asyncGenerateQuestion, selectQuestionByGenerateId, GenerateQuestionDto } from '../common/API';
import { QuestionModel } from '../model/QuestionModel';
import { NavItem } from '../view/NavItem';

@Styles function aitesCardStyle() {
  .backgroundColor(Color.White)
  .borderRadius(24)
  .padding(20)
  .shadow({ radius: 20, color: '#1A000000', offsetX: 0, offsetY: 4 })
}

@Entry
@Component
struct Index {
  @State questionCount: number = 20;
  @State selectedDifficulty: string = '中等';
  @State selectedTab: string = '首页';
  @State currentTopic: string = 'IT 开发';

  @State isLoading: boolean = false;
  private pollIntervalId: number = -1;

  async handleStartQuiz() {
    this.isLoading = true;
    promptAction.showToast({ message: '正在加载...' });

    const params = new GenerateQuestionDto();
    params.question = this.currentTopic;
    params.questionNum = this.questionCount;

    try {
      const startResult = await asyncGenerateQuestion(params);

      if (startResult.code === 200 && startResult.data) {
        const innerResult = startResult.data;
        if (innerResult.code === 200 && innerResult.data) {
          this.startPolling(innerResult.data);
          promptAction.showToast({ message: '任务已在后台运行，正在获取结果...' });
        } else {
          throw new Error(innerResult.message || '启动生成任务失败 (内部结果)');
        }
      } else {
        throw new Error(startResult.message || '启动生成任务失败 (外部结果)');
      }

    } catch (error) {
      // [诊断优化] 打印完整的错误对象以帮助定位问题
      console.error('[AITEST] 捕获到错误对象: ' + JSON.stringify(error));
      this.handleError(error.message || '发生未知网络或逻辑错误');
    }
  }

  startPolling(generateId: string) {
    if (this.pollIntervalId !== -1) {
      clearInterval(this.pollIntervalId);
    }

    this.pollIntervalId = setInterval(async () => {
      try {
        console.info(`[AITEST] 正在轮询结果, ID: ${generateId}`);
        const result = await selectQuestionByGenerateId(generateId);

        if (result.code === 200 && result.data) {
          const innerResult = result.data;
          if (innerResult.code === 200 && innerResult.data && innerResult.data.length > 0) {
            this.handleSuccess(innerResult.data);
          }
        }
      } catch (error) {
        // [诊断优化]
        console.error('[AITEST] 轮询时捕获到错误对象: ' + JSON.stringify(error));
        this.handleError(error.message || '轮询过程中发生错误');
      }
    }, 3000);

    setTimeout(() => {
      if (this.isLoading) {
        this.handleError('任务超时，请稍后重试。');
      }
    }, 120000);
  }

  handleSuccess(questions: QuestionModel[]) {
    clearInterval(this.pollIntervalId);
    this.pollIntervalId = -1;
    this.isLoading = false;
    promptAction.showToast({ message: '题目生成成功！即将跳转...' });

    router.pushUrl({
      url: 'pages/QuizPage',
      params: {
        questions: JSON.stringify(questions)
      }
    });
  }

  handleError(errorMessage: string) {
    clearInterval(this.pollIntervalId);
    this.pollIntervalId = -1;
    this.isLoading = false;
    promptAction.showToast({ message: `发生错误: ${errorMessage}` });
    console.error(`[AITEST] 最终错误信息: ${errorMessage}`);
  }

  // UI 构建部分与您提供的代码相同，因此省略以保持简洁...
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 第一层：页面主内容
      Column() {
        // 1. 顶部栏
        Row() {
          Text('logo')
            .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#6A67EA')
          Blank()
          // 顶部标题现在会动态显示当前选择的主题
          Text(this.currentTopic).fontSize(18).fontWeight(FontWeight.Bold)
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
              }
              .padding(20).borderRadius(20).layoutWeight(1).linearGradient({
                angle: 135,
                colors: [['#4D81F3', 0], ['#818CF8', 1]]
              }).shadow({ radius: 10, color: '#304D81F3' })
              .onClick(() => { this.currentTopic = 'IT 开发' }) // 点击时切换主题

              Column({ space: 8 }) {
                Text('金融理财').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                Text('已完成 30%').fontSize(12).fontColor(Color.White).opacity(0.9)
                Progress({ value: 30, type: ProgressType.Linear }).color(Color.White).margin({ top: 10 })
              }
              .padding(20).borderRadius(20).layoutWeight(1).linearGradient({
                angle: 135,
                colors: [['#8C52FF', 0], ['#C084FC', 1]]
              }).shadow({ radius: 10, color: '#308C52FF' })
              .onClick(() => { this.currentTopic = '金融理财' }) // 点击时切换主题
            }

            // 2.2 智能练习卡片
            Column({ space: 16 }) {
              Text('开始智能练习').fontSize(18).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start)
              Text('AI 将为您生成专业题目').fontSize(13).fontColor(Color.Gray).alignSelf(ItemAlign.Start)
              Divider().strokeWidth(1).color('#F0F0F0').margin({ top: 4, bottom: 4 })
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

              // ✅ “开始”按钮现在绑定了完整的业务逻辑
              Button(this.isLoading ? '正在生成...' : '开始')
                .width('100%').height(50).fontSize(16).fontWeight(FontWeight.Bold)
                .backgroundColor(this.isLoading ? '#B0B0B0' : '#6A67EA')
                .borderRadius(25).margin({ top: 12 })
                .enabled(!this.isLoading) // 加载时禁用按钮
                .onClick(() => {
                  this.handleStartQuiz();
                })
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
                    Progress({ value: 85, type: ProgressType.Ring }).width(100).height(100).style({ strokeWidth: 12 })
                      .color('#4D81F3')
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
          .padding({ left: 16, right: 16, top: 10, bottom: 120 })
        }
      }
      .width('100%').backgroundColor('#F4F6F8')

      // --- 第二层：底部悬浮导航栏 ---
      Row() {
        NavItem({ isSelected: this.selectedTab === '首页', icon: $r('app.media.icon_home'), label: '首页' }).layoutWeight(1).onClick(() => { this.selectedTab = '首页' })
        NavItem({ isSelected: this.selectedTab === '题库', icon: $r('app.media.icon_quiz'), label: '题库' }).layoutWeight(1).onClick(() => { this.selectedTab = '题库' })
        NavItem({ isSelected: this.selectedTab === '错题', icon: $r('app.media.icon_mistake'), label: '错题' }).layoutWeight(1).onClick(() => { this.selectedTab = '错题' })
        NavItem({ isSelected: this.selectedTab === '报告', icon: $r('app.media.icon_report'), label: '报告' }).layoutWeight(1).onClick(() => { this.selectedTab = '报告' })
        NavItem({ isSelected: this.selectedTab === '我的', icon: $r('app.media.icon_profile'), label: '我的' }).layoutWeight(1).onClick(() => { this.selectedTab = '我的' })
      }
      .width('90%')
      .height(64)
      .padding({left: 8, right: 8})
      .backgroundColor(Color.White)
      .borderRadius(32)
      .shadow({ radius: 15, color: '#2A000000', offsetY: 5 })
      .margin({ bottom: 34 })
    }
    .width('100%').height('100%')
  }
}
