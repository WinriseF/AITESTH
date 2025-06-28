import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { getQuizSets, getQuestionsByBatchId, QuizSet } from '../common/API';
import { QuestionModel } from '../model/QuestionModel';

// 题库卡片子组件
@Builder function QuizCard(quizSet: QuizSet) {
  Row({ space: 16 }) {
    // 左侧图标
    Column() {
      // 这里可以根据 quizSet.category 显示不同图标
      Image(quizSet.category === 'IT 开发' ? $r('app.media.ic_code') : $r('app.media.ic_finance'))
        .width(24).height(24)
    }
    .width(48).height(48).borderRadius('50%')
    .backgroundColor(quizSet.category === 'IT 开发' ? '#eef2ff' : '#fdeee_f')
    .justifyContent(FlexAlign.Center)

    // 右侧信息
    Column({ space: 6 }) {
      Text(quizSet.title)
        .fontSize(16).fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Start)
      Text(`共 ${quizSet.totalQuestions} 题 · 创建于 ${new Date(quizSet.createdAt).toLocaleDateString()}`)
        .fontSize(12).fontColor(Color.Gray)
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Start)
  }
  .width('100%')
  .padding(20)
  .borderRadius(12)
  .backgroundColor(Color.White)
  .shadow({ radius: 8, color: '#14000000' })
  .onClick(async () => {
    try {
      promptAction.showToast({ message: `正在加载“${quizSet.title}”...` });
      // 点击时，根据题库的generateId获取对应的所有题目
      const response = await getQuestionsByBatchId(quizSet.generateId);
      if (response.data && response.data.length > 0) {
        // 获取成功后，跳转到答题页面
        router.pushUrl({
          url: 'pages/QuestionPage',
          params: { questions: JSON.stringify(response.data) }
        });
      } else {
        promptAction.showToast({ message: '该题库下暂无题目' });
      }
    } catch (error) {
      promptAction.showToast({ message: `加载失败: ${(error as Error).message}` });
    }
  })
}

@Entry
@Component
struct QuizBankPage {
  @State allQuizSets: QuizSet[] = [];
  @State displayedQuizSets: QuizSet[] = [];
  @State selectedCategory: string = '全部';
  // 模拟的分类数据
  private categories: string[] = ['全部', 'IT 开发', '金融理财'];

  async aboutToAppear() {
    await this.fetchQuizSets();
  }

  async fetchQuizSets() {
    try {
      const response = await getQuizSets();
      this.allQuizSets = response.data;
      this.filterQuizSets(); // 初始加载后进行一次过滤
    } catch (error) {
      promptAction.showToast({ message: `获取题库列表失败: ${(error as Error).message}` });
    }
  }

  // 根据选择的分类过滤题库
  filterQuizSets() {
    if (this.selectedCategory === '全部') {
      this.displayedQuizSets = this.allQuizSets;
    } else {
      this.displayedQuizSets = this.allQuizSets.filter(set => set.category === this.selectedCategory);
    }
  }


  build() {
    Column() {
      // 1. 顶部导航栏
      Row() {
        Image($r("app.media.ic_back"))
          .width(24).height(24).onClick(() => router.back())
        Blank()
        Text('题库').fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Image($r("app.media.ic_back")).width(24).height(24).visibility(Visibility.Hidden)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })
      .backgroundColor(Color.White).shadow({ radius: 4, color: '#10000000', offsetY: 2 })

      // 2. 搜索和分类
      Column({ space: 16 }) {
        // 搜索框 (目前为静态UI)
        Row() {
          Image($r('app.media.search')).width(16).height(16).margin({ left: 15 })
          TextInput({ placeholder: '搜索题库、知识点...' }).layoutWeight(1).backgroundColor(Color.Transparent)
        }
        .width('100%').height(40).backgroundColor(Color.White).borderRadius(20)

        // 分类标签
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.categories, (category: string) => {
              Text(category)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .fontSize(14)
                .backgroundColor(this.selectedCategory === category ? '#6A67EA' : Color.White)
                .fontColor(this.selectedCategory === category ? Color.White : Color.Black)
                .borderRadius(20)
                .onClick(() => {
                  this.selectedCategory = category;
                  this.filterQuizSets();
                })
            })
          }
        }.scrollable(ScrollDirection.Horizontal).edgeEffect(EdgeEffect.None)

      }.width('100%').padding(16)


      // 3. 题库列表
      List({ space: 16 }) {
        ForEach(this.displayedQuizSets, (quizSet: QuizSet) => {
          ListItem() {
            QuizCard(quizSet)
          }
        }, (item: QuizSet) => item.id.toString())
      }
      .layoutWeight(1).padding({ left: 16, right: 16 })

    }
    .width('100%').height('100%').backgroundColor('#F4F6F8')
  }
}
