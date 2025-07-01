import { promptAction } from '@kit.ArkUI';
import router from '@ohos.router';
import { QuestionModel } from '../model/QuestionModel';
import UUID from '@kingtous/uuid';
import { submitGenerationTask, createQuizSet, getQuestionsByBatchId, GenerateQuestionDto } from '../common/API';
import { ApiResponse } from '../utls/HttpClient';

const BATCH_SIZE = 15;

// 定义卡片样式
@Styles function aitesCardStyle() {
  .backgroundColor(Color.White)
  .borderRadius(24)
  .padding(20)
  .shadow({ radius: 20, color: '#1A000000', offsetX: 0, offsetY: 4 })
}

@Component
export struct HomePage {
  // 我们将所有与此页面相关的状态变量放在这里
  @State questionCount: number = 20;
  @State selectedDifficulty: string = '中等';
  @State currentTopic: string = 'IT 开发';
  @State isLoading: boolean = false;
  private pollIntervalId: number = -1;

  // 所有业务逻辑函数
  async handleStartQuiz() {
    this.isLoading = true;
    promptAction.showToast({ message: `正在提交生成任务...` });

    const batchId = UUID.v4();
    const totalQuestions = this.questionCount;
    let remainingQuestions = totalQuestions;
    const requestPromises = [] as Promise<ApiResponse<string>>[];

    while (remainingQuestions > 0) {
      const currentBatchSize = Math.min(remainingQuestions, BATCH_SIZE);
      const params: GenerateQuestionDto = {
        question: this.currentTopic,
        questionNum: currentBatchSize,
        difficulty: this.selectedDifficulty,
        generateId: batchId,
        category: this.currentTopic
      };
      requestPromises.push(submitGenerationTask(params));
      remainingQuestions -= currentBatchSize;
    }

    try {
      await Promise.all(requestPromises);
      promptAction.showToast({ message: `题目已在后台生成，正在创建题库记录...` });

      const quizSetParams: GenerateQuestionDto = {
        generateId: batchId,
        question: this.currentTopic,
        category: this.currentTopic,
        questionNum: totalQuestions,
        difficulty: this.selectedDifficulty,
      };
      await createQuizSet(quizSetParams);

      promptAction.showToast({ message: `题库记录创建成功，开始获取结果...` });
      this.startPolling(batchId, totalQuestions);

    } catch (error) {
      this.handleError((error as Error).message);
    }
  }

  startPolling(generateId: string, expectedCount: number) {
    if (this.pollIntervalId !== -1) {
      clearInterval(this.pollIntervalId);
    }
    this.pollIntervalId = setInterval(async () => {
      try {
        const response = await getQuestionsByBatchId(generateId);
        if (response.data && response.data.length >= expectedCount) {
          this.handleSuccess(response.data);
        } else {
          const currentCount = response.data ? response.data.length : 0;
          console.info(`[AITEST] 结果获取中: ${currentCount}/${expectedCount}`);
        }
      } catch (err) {
        console.error(`[AITEST] 轮询失败: ${(err as Error).message}`);
      }
    }, 8000);
    setTimeout(() => {
      if (this.isLoading) { this.handleError('任务超时，请稍后重试。'); }
    }, 600000);
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

  build() {
    Column() {
      // 顶部栏
      Row() {
        Image($r('app.media.chat'))
          .width(28).height(28)
          .fillColor('#6A67EA')
          .onClick(() => {
            router.pushUrl({ url: 'pages/ChatPage' });
          })
        Blank()
        Text(this.currentTopic).fontSize(18).fontWeight(FontWeight.Bold)
      }
      .width('100%').height(56).padding({ left: 24, right: 24 })

      // 可滚动的主体
      Scroll() {
        Column({ space: 16 }) {
          // 课程选择卡片
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

          // 智能练习卡片
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

          // 学习数据卡片
          Column({ space: 16 }) {
            Row() {
              Text('学习数据').fontSize(18).fontWeight(FontWeight.Bold)
              Blank()
              Text('查看详情 >').fontSize(13).fontColor(Color.Gray)
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')
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
        // 为底部导航栏留出空间
        .padding({ bottom: 80, left: 16, right: 16, top: 10 })
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F4F6F8')
  }
}
