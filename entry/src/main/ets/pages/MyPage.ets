import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AppDataSource } from '../common/AppDataSource';

// 定义列表项的统一样式
@Styles function actionItemStyle() {
  .width('100%')
  .height(56)
  .padding({ left: 20, right: 20 })
  .backgroundColor(Color.White)
  .borderRadius(12)
}

@Entry
@Component
export struct MyPage {
  // 登出处理函数
  async handleLogout() {
    try {
      // --- 这里是核心修正 ---
      // 1. 使用 await 等待弹窗的返回结果
      const result = await promptAction.showDialog({
        title: '确认退出',
        message: '您确定要退出当前账号吗？',
        buttons: [
        // 按钮对象中只包含 text 和 color
          { text: '取消', color: '#333333' },      // 这是按钮 0
          { text: '确认退出', color: '#FF4D4F' }    // 这是按钮 1
        ]
      });

      // 2. 检查返回结果的 index
      if (result.index === 1) {
        // 如果用户点击了第二个按钮（“确认退出”）
        await AppDataSource.getInstance().clearToken();
        promptAction.showToast({ message: '您已成功退出' });
        router.replaceUrl({ url: 'pages/LoginPage' });
      } else {
        // 用户点击了第一个按钮（“取消”）或关闭了弹窗
        console.info('用户取消了退出操作。');
      }
      // --- 修正结束 ---

    } catch(err) {
      console.error(`显示退出弹窗时发生错误: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      // 顶部个人信息区域
      Column({ space: 10 }) {
        Image($r('app.media.icon_profile'))
          .width(80).height(80).borderRadius('50%')
          .border({ width: 3, color: Color.White })
          .shadow({ radius: 10, color: '#20000000' })

        Text('欢迎回来')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White)
      }
      .width('100%')
      .height(220)
      .justifyContent(FlexAlign.Center)
      .linearGradient({
        angle: 135,
        colors: [['#6A67EA', 0], ['#8A2BE2', 1]]
      })

      // 操作列表
      // 操作列表
      Column({ space: 16 }) {
        // 账号管理
        Column({ space: 1 }) {
          //Text('').fontSize(14).fontColor(Color.Gray).margin({ bottom: 8 }).alignSelf(ItemAlign.Start)
          Row() {
            Image($r('app.media.icon_profile')).width(20).height(20)
            Text('编辑个人资料').fontSize(16).margin({ left: 12 })
            Blank()
            Image($r('app.media.ic_arrow_right')).width(16).height(16).fillColor(Color.Gray)
          }.actionItemStyle()

          Row() {
            Image($r('app.media.ic_password')).width(20).height(20) // 假设您有这样一个图标
            Text('修改密码').fontSize(16).margin({ left: 12 })
            Blank()
            Image($r('app.media.ic_arrow_right')).width(16).height(16).fillColor(Color.Gray)
          }.actionItemStyle()
        }

        // 登出操作
        Column({ space: 1 }) {
          Text('操作').fontSize(14).fontColor(Color.Gray).margin({ bottom: 8 }).alignSelf(ItemAlign.Start)
          Row() {
            Image($r('app.media.ic_logout')).width(20).height(20) // 假设您有这样一个图标
            Text('退出登录').fontSize(16).margin({ left: 12 }).fontColor('#FF4D4F')
          }
          .actionItemStyle()
          .onClick(() => {
            this.handleLogout()
          })
        }
      }
      .width('100%')
      .padding(16)
      .margin({ top: -40 }) // 让操作列表向上偏移，覆盖一部分顶部背景，产生层次感
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%').height('100%')
    .backgroundColor('#F4F6F8')
  }
}