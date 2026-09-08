import router from '@ohos.router';
import { AppConstants } from '../../common/constants/AppConstants';
import { ArrowIcon } from '../../common/components/ArrowIcon';

/**
 * 隐私政策页面
 * 详细声明应用完全离线运行、零敏感权限、本地沙盒存储及用户数据销毁权
 */
@Entry
@Component
struct PrivacyPolicyPage {
  build() {
    Column() {
      // 1. 顶栏导航（带返回按钮）
      Row({ space: 12 }) {
        Row() {
          ArrowIcon({ arrowDirection: 'left', variant: 'dark', iconSize: 18 })
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .borderRadius(18)
        .backgroundColor('rgba(0, 0, 0, 0.05)')
        .onClick(() => {
          router.back();
        })

        Text('隐私政策')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_MAIN)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 2. 隐私正文内容区域（可滚动）
      Scroll() {
        Column({ space: 14 }) {
          // 头部声明卡片
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              Text('🛡️')
                .fontSize(22)
              Text('萌宝喂养日记隐私与安全声明')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppConstants.COLOR_TEXT_MAIN)
            }
            .width('100%')

            Text('更新生效日期：2026年9月8日\n\n“萌宝喂养日记”（以下简称“本应用”）是一款致力于为广大家庭提供极简、安全育儿记录工具的应用。我们深知育儿信息和宝宝生长健康数据的极度私密性与重要性，因此本应用在架构设计之初即贯彻“数据仅属于用户设备”的最高隐私保护原则。')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)
              .lineHeight(20)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 核心条款 1：完全本地离线运行
          Column({ space: 6 }) {
            Text('1. 完全本地离线运行，零云端上传')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)

            Text('本应用为纯单机离线工具。在运行全生命周期内：\n• 不依赖任何网络连接，在断网、飞行模式下各项功能均可完整使用。\n• 不提供任何云端同步或远程服务器上传机制，没有任何后端服务器存储您的家庭数据。\n• 无需注册、无需登录手机号、无需绑定任何第三方社交或支付账号，即开即用。')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .lineHeight(19)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 核心条款 2：零敏感系统权限索取
          Column({ space: 6 }) {
            Text('2. 零敏感权限索取原则')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)

            Text('根据系统权限最小化要求，本应用在安装与使用过程中：\n• 不索取通讯录、通话记录与短信权限。\n• 不索取精确或模糊地理位置权限。\n• 不索取麦克风后台录音权限。\n• 不索取相机或相册公共存储读写权限。\n• 所有应用数据仅写入设备为本应用分配的专属本地安全沙盒目录（SQLite RdbStore），外部应用无法随意窥探。')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .lineHeight(19)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 核心条款 3：数据彻底销毁与清除机制
          Column({ space: 6 }) {
            Text('3. 完整数据掌控权与彻底清除机制')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)

            Text('您对记录在本应用中的一切数据拥有绝对的控制权：\n• 您可以随时在“档案与设置”中点击【清除所有数据】功能。\n• 确认清除后，本地沙盒内的所有喂养流水、排泄记录、睡眠打卡、疫苗计划与成长评测数据将被彻底物理擦除，清除后数据永久不可逆、不可恢复。')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .lineHeight(19)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 核心条款 4：无第三方 SDK 与无广告跟踪
          Column({ space: 6 }) {
            Text('4. 无广告、无统计、无第三方追踪')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)

            Text('本应用代码完全纯净：\n• 未嵌入任何商业广告 SDK 或推广跟踪组件。\n• 未嵌入任何用户行为采集、埋点统计或分析 SDK。\n• 不会对您的使用习惯做任何画像或营销推送。')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .lineHeight(19)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 核心条款 5：未成年人个人信息保护
          Column({ space: 6 }) {
            Text('5. 儿童个人信息特别保护说明')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_TEXT_MAIN)

            Text('我们充分理解宝宝出生日期、身高、体重及喂养健康状况属于高度敏感的儿童个人信息。正因如此，本应用坚决采用零云端、纯单机的设计模式，从根源上杜绝网络传输拦截、数据库泄露或商业贩售的一切可能性。')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_MUTED)
              .lineHeight(19)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD_BG)
          .borderRadius(16)
          .border({ width: 1, color: AppConstants.COLOR_BORDER })

          // 底部返回按钮
          Button('我已阅读并知晓')
            .width('100%')
            .height(44)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(AppConstants.COLOR_PRIMARY)
            .fontColor(Color.White)
            .borderRadius(22)
            .margin({ top: 12, bottom: 30 })
            .onClick(() => {
              router.back();
            })
        }
        .width('94%')
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BG_CREAM)
  }
}
