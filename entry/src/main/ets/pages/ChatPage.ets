import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { streamChat } from '../common/API';
import { BusinessError } from '@kit.BasicServicesKit';

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

  scrollToBottom() {
    setTimeout(() => { this.listScroller.scrollEdge(Edge.Bottom); }, 100);
  }

  /**
   * sendMessage函数现在非常简洁清晰
   */
  sendMessage() {
    const userText = this.inputText.trim();
    if (!userText || this.isSending) return;

    this.isSending = true;
    this.inputText = '';

    // 1. 添加用户消息
    this.messages.push({ id: this.messages.length, text: userText, sender: 'user' });
    this.scrollToBottom();

    // 2. 添加机器人消息占位符
    const botMessageIndex = this.messages.length;
    this.messages.push({ id: botMessageIndex, text: '', sender: 'bot', isStreaming: true });
    this.scrollToBottom();

    // 3. 调用封装好的API，并传入回调函数来处理流式数据
    streamChat(userText, {
      onData: (textChunk) => {
        // 【关键修复】使用 .map 来创建一个全新的数组和全新的消息对象，确保UI能够检测到变化
        this.messages = this.messages.map((msg, index) => {
          // 只更新当前正在流式输出的机器人消息
          if (index === botMessageIndex) {
            // 返回一个带有更新后文本的新对象
            return {
              id: msg.id,
              text: msg.text + textChunk,
              sender: msg.sender,
              isStreaming: msg.isStreaming
            };
          }
          // 其他消息保持原样
          return msg;
        });
        this.scrollToBottom();
      },
      onClose: () => {
        this.isSending = false;
        const botMessage = this.messages[botMessageIndex];
        if (botMessage) {
          botMessage.isStreaming = false; // 结束加载动画
          this.messages = [...this.messages];
        }
        console.info('[ChatPage] Stream closed successfully.');
      },
      onError: (error) => {
        this.isSending = false;
        promptAction.showToast({ message: `聊天请求失败: ${error.message}` });
        // 发生错误时，移除机器人的占位消息气泡
        const botMessage = this.messages[botMessageIndex];
        if (botMessage && botMessage.isStreaming) {
          this.messages.pop();
        }
      }
    });
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
        Image($r("app.media.ic_back")).width(24).height(24).visibility(Visibility.Hidden) // 占位
      }
      .width('100%').height(56).padding({ left: 16, right: 16 }).border({ width: { bottom: 1 }, color: '#F0F0F0' })

      // 聊天记录区域
      List({ scroller: this.listScroller }) {
        ForEach(this.messages, (message: ChatMessage) => {
          ListItem() {
            Row() {
              if (message.sender === 'bot') {
                Image($r('app.media.chat')) // 假设您有AI头像资源
                  .width(36).height(36).borderRadius(18).margin({ right: 8 })
              }
              if (message.sender === 'user') {
                Blank()
              }
              Row() {
                Text(message.text)
                  .fontSize(16)
                  .fontColor(message.sender === 'user' ? Color.White : Color.Black)
                if (message.isStreaming) {
                  Text().width(3).height(16).backgroundColor(Color.Black).margin({ left: 4 })
                    .animation({ iterations: -1, duration: 1000, curve: Curve.EaseInOut })
                }
              }
              .padding({ top: 10, bottom: 10, left: 14, right: 14 })
              .backgroundColor(message.sender === 'user' ? '#6A67EA' : '#F0F2F5')
              .borderRadius(12)
              .constraintSize({ maxWidth: '80%' })
              if (message.sender === 'user') {
                Image($r('app.media.icon_profile')) // 假设您有用户头像资源
                  .width(36).height(36).borderRadius(18).margin({ left: 8 })
              }
            }
            .width('100%').padding({ top: 10, bottom: 10 })
          }
        }, (item: ChatMessage) => item.id.toString())
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
        .backgroundColor('#6A67EA')
        .enabled(!this.isSending)
        .onClick(() => this.sendMessage())
      }
      .width('100%').padding(10).border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }
}
