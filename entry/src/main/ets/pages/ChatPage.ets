import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { simpleChat } from '../utls/HttpClient'; // 导入新的simpleChat方法

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

  async sendMessage() {
    const userText = this.inputText.trim();
    if (!userText || this.isSending) return;

    this.isSending = true;
    this.inputText = '';

    // 1. 添加用户消息
    this.messages.push({ id: this.messages.length, text: userText, sender: 'user' });
    this.scrollToBottom();

    // 2. 添加占位符
    const botMessageIndex = this.messages.length;
    this.messages.push({ id: botMessageIndex, text: '正在思考...', sender: 'bot', isStreaming: true });
    this.scrollToBottom();

    try {
      const aiResponse = await simpleChat(userText);

      this.messages = this.messages.map((msg, index) => {
        if (index === botMessageIndex) {
          // 返回一个带有AI回复的、全新的消息对象
          return {
            id: msg.id,
            text: aiResponse,
            sender: 'bot',
            isStreaming: false
          };
        }
        // 其他消息保持原样
        return msg;
      });

    } catch (error) {
      const err = error as Error;
      promptAction.showToast({ message: `请求失败: ${err.message}` });
      // 从数组中移除失败的占位符
      this.messages = this.messages.filter((_, index) => index !== botMessageIndex);
    } finally {
      this.isSending = false;
      this.scrollToBottom();
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
        Image($r("app.media.ic_back")).width(24).height(24).visibility(Visibility.Hidden) // 占位
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
                // “正在输入”的光标动画
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
                Image($r('app.media.icon_profile'))
                  .width(36).height(36).borderRadius(18).margin({ left: 8 })
              }
            }
            .width('100%').padding({ top: 10, bottom: 10 })
          }
        },
          // 使用 消息ID + 消息文本 作为唯一的key，强制UI在文本更新时重新渲染
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
        .backgroundColor(this.isSending ? Color.Gray : '#6A67EA') // 发送中按钮变灰
        .enabled(!this.isSending)
        .onClick(() => this.sendMessage())
      }
      .width('100%').padding(10).border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }
}
