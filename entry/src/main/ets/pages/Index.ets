import { promptAction } from '@kit.ArkUI';
import http from '@ohos.net.http'; // 引入 http 模块
import { BusinessError } from '@kit.BasicServicesKit'; // 引入 BusinessError
import router from '@ohos.router';
// 引入我们需要的模型和DTO
import { GenerateQuestionDto } from '../common/API';
import { QuestionModel } from '../model/QuestionModel';

// --- 配置区域 ---
// !!!【请务必修改这里】!!!
// 将 "YOUR_COMPUTER_IP" 替换为您电脑的真实局域网IP地址
const API_BASE_URL = 'http://192.168.31.202:8080'; // 已根据您的日志填入IP

// 为后端返回的统一结果定义明确的类型
interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}


// 定义卡片样式 (来自您的布局)
@Styles function aitesCardStyle() {
  .backgroundColor(Color.White)
  .borderRadius(24)
  .padding(20)
  .shadow({ radius: 20, color: '#1A000000', offsetX: 0, offsetY: 4 })
}

// 底部导航栏单个项目的子组件 (来自您的布局)
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
  // --- UI状态变量 (来自您的布局) ---
  @State questionCount: number = 5;
  @State selectedDifficulty: string = '中等';
  @State selectedTab: string = '首页';

  // --- 新增的功能状态变量 ---
  @State currentTopic: string = 'IT 开发';
  @State isLoading: boolean = false;
  private pollIntervalId: number = -1;

  // --- 新增的核心业务逻辑函数 ---
  /**
   * 核心网络请求函数 - 启动题目生成
   */
  async handleStartQuiz() {
    this.isLoading = true;
    promptAction.showToast({ message: '正在提交任务...' });

    const url = `${API_BASE_URL}/question/asyncGenerateQuestion`;
    const params: GenerateQuestionDto = {
      question: this.currentTopic,
      questionNum: this.questionCount
    };

    console.info('[AITEST] 准备发送请求到: ' + url);
    console.info('[AITEST] 请求参数: ' + JSON.stringify(params));

    let httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(params),
        connectTimeout: 10000,
        readTimeout: 10000,
      });

      console.info('[AITEST] 收到响应码: ' + response.responseCode);
      console.info('[AITEST] 收到响应体: ' + response.result);

      if (response.responseCode === 200) {
        const resultJson: ApiResponse<string> = JSON.parse(response.result as string);
        if (resultJson.code === 200 && resultJson.data) {
          promptAction.showToast({ message: '任务已提交，开始轮询结果...' });
          this.startPolling(resultJson.data);
        } else {
          throw new Error(resultJson.message || '后端返回业务错误');
        }
      } else {
        throw new Error(`HTTP 错误，状态码: ${response.responseCode}`);
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error('[AITEST] 网络请求捕获到严重错误: ' + JSON.stringify(error));
      this.handleError(error.message || '网络连接失败，请检查IP地址和网络权限');
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 轮询获取结果
   */
  startPolling(generateId: string) {
    if (this.pollIntervalId !== -1) {
      clearInterval(this.pollIntervalId);
    }

    this.pollIntervalId = setInterval(async () => {
      const url = `${API_BASE_URL}/question/question/${generateId}`;
      console.info(`[AITEST] 正在轮询: ${url}`);
      let httpRequest = http.createHttp();
      try {
        const response = await httpRequest.request(url, { method: http.RequestMethod.GET });
        if (response.responseCode === 200) {
          const resultJson: ApiResponse<QuestionModel[]> = JSON.parse(response.result as string);
          if (resultJson.code === 200 && resultJson.data && resultJson.data.length > 0) {
            this.handleSuccess(resultJson.data);
          } else {
            console.info('[AITEST] 结果尚未就绪，继续轮询...');
          }
        }
      } catch (err) {
        // ...
      } finally {
        httpRequest.destroy();
      }
    }, 3000);

    setTimeout(() => {
      if (this.isLoading) {
        this.handleError('任务超时，请稍后重试。');
      }
    }, 300000); // 5分钟超时
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
      const error = err as BusinessError;
      this.handleError(`页面跳转失败: ${error.message}. 请检查页面路径是否正确并在 module.json5 中注册.`);
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
    Stack({ alignContent: Alignment.Bottom }) {
      // 第一层：页面主内容
      Column() {
        // 1. 顶部栏
        Row() {
          Text('logo').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#6A67EA')
          Blank()
          //【功能集成】标题栏现在动态显示当前主题
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
              //【功能集成】点击时切换当前主题
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
              //【功能集成】点击时切换当前主题
              .onClick(() => { this.currentTopic = '金融理财'; })
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
              //【功能集成】将按钮与业务逻辑和加载状态绑定
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
          // 确保滚动到底部时，内容不会被新的导航栏遮挡。
          .padding({ left: 16, right: 16, top: 10, bottom: 80 }) // 增加了底部padding
        }
      }
      .width('100%').backgroundColor('#F4F6F8')


      // --- 第二层：底部导航栏 (来自您的布局) ---
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
