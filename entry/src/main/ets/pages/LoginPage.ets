import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { loginUser, registerUser, UserLoginDto, UserRegistrationDto } from '../common/API';
import { AppDataSource } from '../common/AppDataSource';

// 定义输入框样式
@Styles function inputStyle() {
  .height(50)
  .padding({ left: 16, right: 16 })
  .backgroundColor('#F3F4F6')
  .borderRadius(12)
}

@Entry
@Component
export struct LoginPage {
  @State isLoginMode: boolean = true;
  @State username: string = '';
  @State email: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;

  // 表单提交处理函数
  async handleSubmit() {
    this.isLoading = true;
    try {
      if (this.isLoginMode) {
        // 执行登录逻辑
        if (!this.username || !this.password) {
          promptAction.showToast({ message: '用户名和密码不能为空！' });
          return;
        }
        const params: UserLoginDto = { username: this.username, password: this.password };
        const response = await loginUser(params);
        if (response.code === 200 && response.data) {
          promptAction.showToast({ message: '登录成功！' });
          // 将获取的Token存储起来
          AppDataSource.getInstance().setToken(response.data);
          // 替换到首页，这样用户无法通过返回键回到登录页
          router.replaceUrl({ url: 'pages/Index' });
        } else {
          throw new Error(response.message || '登录失败');
        }
      } else {
        // 执行注册逻辑
        if (!this.username || !this.password || !this.email) {
          promptAction.showToast({ message: '用户名、邮箱和密码均不能为空！' });
          return;
        }
        const params: UserRegistrationDto = { username: this.username, password: this.password, email: this.email };
        const response = await registerUser(params);
        if (response.code === 200) {
          promptAction.showToast({ message: '注册成功，请登录！' });
          // 注册成功后自动切换到登录模式
          this.isLoginMode = true;
        } else {
          throw new Error(response.message || '注册失败');
        }
      }
    } catch (err) {
      promptAction.showToast({ message: (err as Error).message });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部标题
      Text(this.isLoginMode ? '欢迎回来！' : '创建您的账户')
        .fontSize(32).fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 40 })
        .alignSelf(ItemAlign.Start)

      // 输入表单
      Column({ space: 16 }) {
        TextInput({ placeholder: '用户名', text: this.username })
          .onChange((val) => { this.username = val })
          .inputStyle()

        if (!this.isLoginMode) {
          TextInput({ placeholder: '邮箱地址', text: this.email }).type(InputType.Email)
            .onChange((val) => { this.email = val })
            .inputStyle()
        }

        TextInput({ placeholder: '密码', text: this.password }).type(InputType.Password)
          .onChange((val) => { this.password = val })
          .inputStyle()
      }

      // 主操作按钮
      Button(this.isLoading ? '请稍候...' : (this.isLoginMode ? '登 录' : '立即注册'))
        .width('100%').height(50).fontSize(16).fontWeight(FontWeight.Bold)
        .backgroundColor(this.isLoading ? '#B0B0B0' : '#6A67EA')
        .enabled(!this.isLoading)
        .margin({ top: 40 })
        .onClick(() => this.handleSubmit())

      // 切换模式的文本按钮
      Row({ space: 4 }) {
        Text(this.isLoginMode ? '还没有账户？' : '已经有账户了？')
          .fontSize(14).fontColor(Color.Gray)
        Text(this.isLoginMode ? '立即注册' : '前往登录')
          .fontSize(14).fontColor('#6A67EA').fontWeight(FontWeight.Medium)
      }
      .margin({ top: 20 })
      .onClick(() => { this.isLoginMode = !this.isLoginMode })

    }
    .width('100%').height('100%')
    .padding({ left: 24, right: 24 })
    .backgroundColor(Color.White)
  }
}