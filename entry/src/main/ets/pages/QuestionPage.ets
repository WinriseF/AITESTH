import router from '@ohos.router';
import { prompt } from '@kit.ArkUI';
import { QuestionModel } from '../model/QuestionModel';

interface QuestionPageParams{
  questions: QuestionModel[];
}
// 答题选项的子组件
@Component
struct OptionItem {
  label: string = '';
  text: string = '';
  @Prop isSelected: boolean = false;
  @Prop isCorrect: boolean = false;
  @Prop showAnswer: boolean = false;

  build() {
    Row({ space: 12 }) {
      Text(this.label)
        .width(36).height(36).borderRadius('50%').fontSize(16).fontWeight(FontWeight.Bold)
        .fontColor(this.isSelected ? Color.White : '#6A67EA')
        .backgroundColor(this.isSelected ? '#6A67EA' : '#F0F2FF')
        .align(Alignment.Center)

      Text(this.text)
        .fontSize(16)
        .textAlign(TextAlign.Start)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor(Color.White)
    .border({
      width: 2,
      color: this.showAnswer ? (this.isCorrect ? '#28A745' : (this.isSelected ? '#DC3545' : Color.Transparent)) : Color.Transparent,
      radius: 12
    })
    .shadow(this.isSelected ? { radius: 6, color: '#206A67EA' } : { radius: 8, color: '#14000000' })
    .animation({ duration: 200, curve: Curve.EaseInOut })
  }
}

@Entry
@Component
struct QuizPage {
  @State questions: QuestionModel[] = [];
  @State currentIndex: number = 0;
  @State selectedOption: string = '';
  @State score: number = 0;
  @State showAnswer: boolean = false;
  @State isQuizFinished: boolean = false;

  aboutToAppear() {
    const params = router.getParams() as QuestionPageParams;
    if (params && params.questions) {
      // ✅ 修正：使用手动赋值替换 Object.assign，以符合ArkTS规范
      this.questions = params.questions.map(q => {
        let question = new QuestionModel();
        question.id = q.id;
        question.generateId = q.generateId;
        question.question = q.question;
        question.optionA = q.optionA;
        question.optionB = q.optionB;
        question.optionC = q.optionC;
        question.optionD = q.optionD;
        question.answer = q.answer;
        question.analysis = q.analysis;
        return question;
      });
    } else {
      prompt.showToast({ message: "题目加载失败！" });
      router.back();
    }
  }

  checkAnswer() {
    if (!this.selectedOption) {
      prompt.showToast({ message: "请选择一个答案！" });
      return;
    }
    if (this.selectedOption === (this.questions[this.currentIndex].answer ?? '')) {
      this.score++;
    }
    this.showAnswer = true;
  }

  nextQuestion() {
    if (this.currentIndex < this.questions.length - 1) {
      this.currentIndex++;
      this.selectedOption = '';
      this.showAnswer = false;
    } else {
      this.isQuizFinished = true;
    }
  }

  restartQuiz() {
    this.currentIndex = 0;
    this.selectedOption = '';
    this.score = 0;
    this.showAnswer = false;
    this.isQuizFinished = false;
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r("app.media.ic_back"))
          .width(24).height(24).onClick(() => router.back())
        Text(`第 ${this.currentIndex + 1} / ${this.questions.length} 题`)
          .fontSize(18).fontWeight(FontWeight.Bold).margin({left:16})
        Blank()
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })

      // 根据答题状态显示不同内容
      if (!this.isQuizFinished && this.questions.length > 0) {
        // ... 答题中的UI ...
        this.QuizContent()
      } else {
        // ... 答题结束的UI ...
        this.ResultContent()
      }
    }
    .width('100%').height('100%').backgroundColor('#F4F6F8')
  }

  // 答题界面
  @Builder QuizContent() {
    Scroll() {
      Column({ space: 16 }) {
        Text(this.questions[this.currentIndex].question ?? '题目加载中...')
          .fontSize(20).fontWeight(FontWeight.Bold).width('100%').textAlign(TextAlign.Start)

        OptionItem({ label: 'A', text: this.questions[this.currentIndex].optionA ?? '', isSelected: this.selectedOption === 'A', showAnswer: this.showAnswer, isCorrect: (this.questions[this.currentIndex].answer ?? '') === 'A' })
          .onClick(() => { if (!this.showAnswer) this.selectedOption = 'A' })
        OptionItem({ label: 'B', text: this.questions[this.currentIndex].optionB ?? '', isSelected: this.selectedOption === 'B', showAnswer: this.showAnswer, isCorrect: (this.questions[this.currentIndex].answer ?? '') === 'B' })
          .onClick(() => { if (!this.showAnswer) this.selectedOption = 'B' })
        OptionItem({ label: 'C', text: this.questions[this.currentIndex].optionC ?? '', isSelected: this.selectedOption === 'C', showAnswer: this.showAnswer, isCorrect: (this.questions[this.currentIndex].answer ?? '') === 'C' })
          .onClick(() => { if (!this.showAnswer) this.selectedOption = 'C' })
        OptionItem({ label: 'D', text: this.questions[this.currentIndex].optionD ?? '', isSelected: this.selectedOption === 'D', showAnswer: this.showAnswer, isCorrect: (this.questions[this.currentIndex].answer ?? '') === 'D' })
          .onClick(() => { if (!this.showAnswer) this.selectedOption = 'D' })

        if (this.showAnswer) {
          Column() {
            Text(`正确答案：${this.questions[this.currentIndex].answer ?? 'N/A'}`)
              .fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
            Text(this.questions[this.currentIndex].analysis ?? '暂无解析')
              .fontSize(14).fontColor(Color.Gray)
          }
          .width('100%').padding(16).borderRadius(12).backgroundColor(Color.White)
          .alignItems(HorizontalAlign.Start).margin({top: 10})
        }

        Button(this.showAnswer ? `下一题 (${this.currentIndex + 1}/${this.questions.length})` : '确认答案')
          .width('100%').height(50).fontSize(16).fontWeight(FontWeight.Bold)
          .backgroundColor('#007bff').margin({ top: 20 })
          .onClick(() => {
            this.showAnswer ? this.nextQuestion() : this.checkAnswer()
          })
      }.padding(16)
    }
  }

  // 结果界面
  @Builder ResultContent() {
    Column({ space: 20 }) {
      Text('答题完成！').fontSize(32).fontWeight(FontWeight.Bold)
      Text(`您的得分是：${this.score} / ${this.questions.length}`)
        .fontSize(20)
      Button('再来一次').onClick(() => this.restartQuiz())
        .width('80%').height(50).margin({ top: 30 })
      Button('返回首页').onClick(() => router.back())
        .width('80%').height(50).type(ButtonType.Normal)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}