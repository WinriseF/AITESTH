import {  promptAction } from '@kit.ArkUI';
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

  // --- 异步流程控制的状态变量 ---
  @State isLoading: boolean = false; // 控制是否显示加载状态
  private pollIntervalId: number = -1; // 存储轮询定时器的ID

  // --- 核心业务逻辑函数 ---

  /**
   * 当点击"开始生成"按钮时触发的主函数
   */
  async handleStartQuiz() {
    this.isLoading = true; // 1. 进入加载状态，UI会自动更新
    promptAction.showToast({ message: '正在加载...' });

    // a. 前端生成一个唯一的批次ID
    const generateId = UUID.v4();

    const params = new GenerateQuestionDto();
    params.question = this.currentTopic;
    params.questionNum = this.questionCount;
    params.generateId = generateId;

    try {
      const startResult = await asyncGenerateQuestion(params);
      // prompt.hideLoading();

      if (startResult.code === 200 && startResult.data) {
        this.startPolling(startResult.data.generateId);
        promptAction.showToast({ message: '任务已在后台运行，正在获取结果...' });
      } else {
        throw new Error(startResult.message || '启动生成任务失败');
      }

    } catch (error) {
      this.handleError(error.message);
    }
  }

  /**
   * 开始轮询结果的函数
   * @param generateId 后端任务的唯一ID
   */
  startPolling(generateId: string) {
    // 先清除上一次可能存在的定时器，防止内存泄漏
    if (this.pollIntervalId !== -1) {
      clearInterval(this.pollIntervalId);
    }

    this.pollIntervalId = setInterval(async () => {
      try {
        console.info(`[AITEST] 正在轮询结果, ID: ${generateId}`);
        const result = await selectQuestionByGenerateId(generateId);

        // e. 检查是否收到了包含题目的成功结果
        if (result.code === 200 && result.data && result.data.length > 0) {
          this.handleSuccess(result.data);
        }
        // 如果没收到，不做任何事，安静地等待下一次轮询
      } catch (error) {
        this.handleError(error.message);
      }
    }, 3000); // 每3秒查询一次

    // 设置一个超时，比如2分钟后如果还没结果，就自动停止，防止无限轮询
    setTimeout(() => {
      // 如果2分钟后仍在加载状态，则判定为超时
      if (this.isLoading) {
        this.handleError('任务超时，请稍后重试。');
      }
    }, 120000);
  }

  /**
   * 成功获取题目后的处理函数
   * @param questions 获取到的题目列表
   */
  handleSuccess(questions: QuestionModel[]) {
    clearInterval(this.pollIntervalId); // 停止轮询
    this.pollIntervalId = -1;
    this.isLoading = false;
    promptAction.showToast({ message: '题目生成成功！即将跳转...' });

    // f. 跳转到答题页面，并将题目作为参数传递过去
    router.pushUrl({
      url: 'pages/QuizPage',
      params: {
        questions: questions
      }
    });
  }

  /**
   * 统一的错误处理函数
   * @param errorMessage 错误消息
   */
  handleError(errorMessage: string) {
    clearInterval(this.pollIntervalId);
    this.pollIntervalId = -1;
    this.isLoading = false;
    promptAction.showToast({ message: `发生错误: ${errorMessage}` });
    console.error(`[AITEST] Error: ${errorMessage}`);
  }

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