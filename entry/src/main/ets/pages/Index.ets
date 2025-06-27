import { promptAction } from '@kit.ArkUI';
import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';
import router from '@ohos.router';
import { QuestionModel } from '../model/QuestionModel';
import UUID from '@kingtous/uuid'; // 引入UUID库来生成批次ID

// --- 配置区域 ---
const API_BASE_URL = 'http://192.168.31.202:8080'; // 已根据您的日志填入IP
const BATCH_SIZE = 15; // 定义每个并行请求的题目数量

// --- 类型定义 ---
interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

interface GenerateQuestionDto {
  question: string;
  questionNum: number;
  difficulty: string;
  generateId: string; // 新增批次ID字段
}

@Styles function aitesCardStyle() { /* ... 样式代码省略 ... */ .backgroundColor(Color.White).borderRadius(24).padding(20).shadow({ radius: 20, color: '#1A000000', offsetX: 0, offsetY: 4 })}
@Component struct NavItem { /* ... NavItem组件代码省略 ... */ @Prop isSelected: boolean = false; label: string = ''; icon: Resource = $r('app.media.icon_home'); build() { Column({ space: 4 }) { Image(this.icon) .width(24).height(24) .fillColor(this.isSelected ? '#6A67EA' : '#888888'); Text(this.label) .fontSize(10) .fontWeight(this.isSelected ? FontWeight.Medium : FontWeight.Normal) .fontColor(this.isSelected ? '#6A67EA' : '#888888') }.padding({ top: 8, bottom: 8 }).justifyContent(FlexAlign.Center) } }

@Entry
@Component
struct Index {
  @State questionCount: number = 20;
  @State selectedDifficulty: string = '中等';
  @State selectedTab: string = '首页';
  @State currentTopic: string = 'IT 开发';
  @State isLoading: boolean = false;
  private pollIntervalId: number = -1;

  /**
   * 【重构】处理开始测验的逻辑，支持任务拆分和并行
   */
  async handleStartQuiz() {
    this.isLoading = true;
    promptAction.showToast({ message: `正在提交生成任务...` });

    // 1. 为本次所有请求生成一个统一的批次ID
    const batchId = UUID.v4();
    const totalQuestions = this.questionCount;
    let remainingQuestions = totalQuestions;

    const requestPromises: Promise<void>[] = [];

    console.info(`[AITEST] 总任务开始，ID: ${batchId}, 总数: ${totalQuestions}`);

    // 2. 将总数拆分为多个小任务
    while (remainingQuestions > 0) {
      const currentBatchSize = Math.min(remainingQuestions, BATCH_SIZE);
      const params: GenerateQuestionDto = {
        question: this.currentTopic,
        questionNum: currentBatchSize,
        difficulty: this.selectedDifficulty,
        generateId: batchId // 所有请求都使用同一个批次ID
      };
      // 3. 为每个小任务创建一个异步请求的Promise
      requestPromises.push(this.submitGenerationTask(params));
      remainingQuestions -= currentBatchSize;
    }

    try {
      // 4. 并行发送所有请求
      await Promise.all(requestPromises);
      // 5. 所有请求都成功提交后，开始轮询最终结果
      promptAction.showToast({ message: `所有任务已提交，开始获取结果...` });
      this.startPolling(batchId, totalQuestions);
    } catch (error) {
      this.handleError((error as Error).message);
    }
  }

  /**
   * 【新增】封装的单个生成任务的提交函数
   * @param params 请求参数
   * @returns 一个Promise，成功或失败
   */
  async submitGenerationTask(params: GenerateQuestionDto): Promise<void> {
    const url = `${API_BASE_URL}/question/asyncGenerateQuestion`;
    console.info(`[AITEST] 提交子任务: ${JSON.stringify(params)}`);
    let httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(params),
        connectTimeout: 15000,
        readTimeout: 15000,
      });

      if (response.responseCode === 200) {
        const resultJson: ApiResponse<string> = JSON.parse(response.result as string);
        if (resultJson.code === 200) {
          console.info(`[AITEST] 子任务提交成功, generateId: ${resultJson.data}`);
          return Promise.resolve(); // 表示这个子任务提交成功
        }
      }
      // 如果任何一个环节出错，就抛出异常
      throw new Error(`一个子任务提交失败: ${response.result}`);
    } finally {
      httpRequest.destroy();
    }
  }


  /**
   * 【重构】轮询获取结果，增加期望数量的判断
   * @param generateId 批次ID
   * @param expectedCount 期望得到的题目总数
   */
  startPolling(generateId: string, expectedCount: number) {
    if (this.pollIntervalId !== -1) {
      clearInterval(this.pollIntervalId);
    }

    this.pollIntervalId = setInterval(async () => {
      const url = `${API_BASE_URL}/question/question/${generateId}`;
      let httpRequest = http.createHttp();
      try {
        const response = await httpRequest.request(url, { method: http.RequestMethod.GET });
        if (response.responseCode === 200) {
          const resultJson: ApiResponse<QuestionModel[]> = JSON.parse(response.result as string);
          if (resultJson.code === 200 && resultJson.data) {
            // 【关键修改】判断当前获取的数量是否已达到期望值
            if (resultJson.data.length >= expectedCount) {
              this.handleSuccess(resultJson.data);
            } else {
              console.info(`[AITEST] 结果获取中: ${resultJson.data.length}/${expectedCount}`);
            }
          }
        }
      } catch (err) {
        // ...
      } finally {
        httpRequest.destroy();
      }
    }, 5000); // 轮询间隔可以适当延长到5秒

    setTimeout(() => {
      if (this.isLoading) {
        this.handleError('任务超时，请稍后重试。');
      }
    }, 600000); // 将总超时延长到10分钟以应对大批量请求
  }

  handleSuccess(questions: QuestionModel[]) {
    clearInterval(this.pollIntervalId);
    this.pollIntervalId = -1;
    this.isLoading = false;
    promptAction.showToast({ message: '题目生成成功！即将跳转...' });

    try {
      router.pushUrl({
        url: 'pages/QuestionPage',
        params: { questions: JSON.stringify(questions) }
      });
    } catch (err) {
      this.handleError(`页面跳转失败: ${(err as Error).message}.`);
    }
  }

  handleError(errorMessage: string) {
    clearInterval(this.pollIntervalId);
    this.pollIntervalId = -1;
    this.isLoading = false;
    promptAction.showToast({ message: `发生错误: ${errorMessage}` });
    console.error(`[AITEST] 最终错误信息: ${errorMessage}`);
  }

  // UI build() 方法保持不变，因此省略...
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Row() {
          Text('logo').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#6A67EA')
          Blank()
          Text(this.currentTopic).fontSize(18).fontWeight(FontWeight.Bold)
        }
        .width('100%').height(56).padding({ left: 24, right: 24 })

        Scroll() {
          Column({ space: 16 }) {
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
              .onClick(() => { this.currentTopic = 'IT 开发'; })

              Column({ space: 8 }) {
                Text('金融理财').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
                Text('已完成 30%').fontSize(12).fontColor(Color.White).opacity(0.9)
                Progress({ value: 30, type: ProgressType.Linear }).color(Color.White).margin({ top: 10 })
              }
              .padding(20).borderRadius(20).layoutWeight(1).linearGradient({
                angle: 135,
                colors: [['#8C52FF', 0], ['#C084FC', 1]]
              }).shadow({ radius: 10, color: '#308C52FF' })
              .onClick(() => { this.currentTopic = '金融理财'; })
            }

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
              Button(this.isLoading ? '正在生成...' : '开始')
                .width('100%').height(50).fontSize(16).fontWeight(FontWeight.Bold)
                .backgroundColor(this.isLoading ? '#B0B0B0' : '#6A67EA')
                .borderRadius(25).margin({ top: 12 })
                .enabled(!this.isLoading)
                .onClick(() => {
                  this.handleStartQuiz();
                })
            }.aitesCardStyle()

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
          .padding({ left: 16, right: 16, top: 10, bottom: 80 })
        }
      }
      .width('100%').backgroundColor('#F4F6F8')

      Row() {
        NavItem({ isSelected: this.selectedTab === '首页', icon: $r('app.media.icon_home'), label: '首页' })
          .onClick(() => { this.selectedTab = '首页' })
        NavItem({ isSelected: this.selectedTab === '题库', icon: $r('app.media.icon_quiz'), label: '题库' })
          .onClick(() => { this.selectedTab = '题库' })
        NavItem({ isSelected: this.selectedTab === '错题', icon: $r('app.media.icon_mistake'), label: '错题' })
          .onClick(() => { this.selectedTab = '错题' })
        NavItem({ isSelected: this.selectedTab === '报告', icon: $r('app.media.icon_report'), label: '报告' })
          .onClick(() => { this.selectedTab = '报告' })
        NavItem({ isSelected: this.selectedTab === '我的', icon: $r('app.media.icon_profile'), label: '我的' })
          .onClick(() => { this.selectedTab = '我的' })
      }
      .width('100%')
      .height(64)
      .justifyContent(FlexAlign.SpaceAround)
      .border({ width: { top: 1 }, color: '#EAEAEA' })
      .backgroundColor(Color.White)
      .padding({ bottom: 'env(safe-area-inset-bottom)' })

    }
    .width('100%').height('100%')
    .backgroundColor('#F4F6F8')
  }
}
