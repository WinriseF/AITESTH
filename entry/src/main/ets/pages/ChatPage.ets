import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { simpleChat } from "../common/API"

// 定义单条聊天消息的数据模型
interface ChatMessage {
  id: number;
  text: string;
  sender: 'user' | 'bot';
  isStreaming?: boolean;
}

@Entry
@Component
struct ChatPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isSending: boolean = false;
  private listScroller: Scroller = new Scroller();

  // 平滑滚动到底部
  scrollToBottom() {
    setTimeout(() => { this.listScroller.scrollEdge(Edge.Bottom); }, 100);
  }

  /**
   * 一个用于模拟“打字”效果的函数
   * @param botMessageIndex 正在更新的机器人消息在数组中的索引
   * @param fullText AI返回的完整文本
   */
  simulateStreaming(botMessageIndex: number, fullText: string) {
    const characters = Array.from(fullText);
    let currentIndex = 0;

    this.messages[botMessageIndex].isStreaming = true;
    this.messages[botMessageIndex].text = '';

    const intervalId = setInterval(() => {
      if (currentIndex >= characters.length) {
        clearInterval(intervalId);
        this.messages[botMessageIndex].isStreaming = false;
        this.isSending = false;
        this.messages = [...this.messages];
        return;
      }

      this.messages[botMessageIndex].text += characters[currentIndex];
      this.messages = [...this.messages];

      this.scrollToBottom();
      currentIndex++;
    }, 5); // 打字速度，单位毫秒
  }

  async sendMessage() {
    const userText = this.inputText.trim();
    if (!userText || this.isSending) return;

    this.isSending = true;
    this.inputText = '';

    this.messages.push({ id: this.messages.length, text: userText, sender: 'user' });
    this.scrollToBottom();

    const botMessageIndex = this.messages.length;
    this.messages.push({ id: botMessageIndex, text: '正在思考...', sender: 'bot', isStreaming: false });
    this.scrollToBottom();

    try {
      // 一次性获取完整的AI回复
      const aiResponse = await simpleChat(userText);
      // 使用完整的回复来启动模拟打字效果
      this.simulateStreaming(botMessageIndex, aiResponse.trim());

    } catch (error) {
      const err = error as Error;
      promptAction.showToast({ message: `请求失败: ${err.message}` });
      this.messages = this.messages.filter((_, index) => index !== botMessageIndex);
      this.isSending = false;
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r("app.media.ic_back"))
          .width(24).height(24)
          .fillColor(Color.Black)
          .onClick(() => router.back())
        Blank()
        Text('AI 助手').fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Image($r("app.media.ic_back")).width(24).height(24).visibility(Visibility.Hidden)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 }).border({ width: { bottom: 1 }, color: '#F0F0F0' })

      // 聊天记录区域
      List({ scroller: this.listScroller }) {
        ForEach(this.messages, (message: ChatMessage) => {
          ListItem() {
            Row() {
              if (message.sender === 'bot') {
                Image($r('app.media.chat'))
                  .width(36).height(36).borderRadius(18).margin({ right: 8 })
              }
              if (message.sender === 'user') {
                Blank()
              }
              Row() {
                Text(message.text)
                  .fontSize(16)
                  .fontColor(message.sender === 'user' ? Color.White : Color.Black)
              }
              .padding({ top: 10, bottom: 10, left: 14, right: 14 })
              .backgroundColor(message.sender === 'user' ? '#6A67EA' : '#F0F2F5')
              .borderRadius(12)
              .constraintSize({ maxWidth: '80%' })
              if (message.sender === 'user') {
                Image($r('app.media.icon_profile'))
                  .width(36).height(36).borderRadius(18).margin({ left: 8 })
              }
            }
            .width('100%').padding({ top: 10, bottom: 10 })
            .alignItems(VerticalAlign.Top)
          }
        },
          (item: ChatMessage) => `${item.id}-${item.text}`
        )
      }
      .layoutWeight(1).padding({ left: 16, right: 16 })
      .edgeEffect(EdgeEffect.None)

      // 底部输入区域
      Row({ space: 10 }) {
        TextInput({ placeholder: '向AI发送消息...' , text: this.inputText})
          .onChange((value) => { this.inputText = value; })
          .onSubmit(() => this.sendMessage())
          .layoutWeight(1)
          .height(48)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#F0F2F5')
          .borderRadius(24)
        Button() {
          Image($r('app.media.send')).width(24).height(24).fillColor(Color.White)
        }
        .width(48).height(48).type(ButtonType.Circle)
        .backgroundColor(this.isSending ? Color.Gray : '#6A67EA')
        .enabled(!this.isSending)
        .onClick(() => this.sendMessage())
      }
      .width('100%').padding(10).border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }
}
