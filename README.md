# 货运标注：iOS 地图标注 App（无 Mac 也能装）

跑通完整链路的 SwiftUI 应用：

```
写 Swift 代码  →  GitHub Actions 的云 Mac 编译  →  未签名 .ipa  →  Windows 上用 Sideloadly 签名  →  装进 iPhone
```

你只有 Windows + 普通 Apple ID 也能装，不需要 Mac，不需要 99 美元的开发者账号。

## 现在能做什么（v1）

- **地图标注**：地图上显示所有标注点，按类型区分颜色和图标
- **六种类型**：装货点 / 卸货点 / 仓库 / 客户 / 限行路况 / 其他
- **新增与编辑**：点右下角 `+` 把标注加在地图中心，点任意标注气泡打开详情
- **字段**：名称、类型、地址、联系人 / 电话、备注
- **导航**：详情页一键调起 Apple 地图驾车导航
- **打电话**：联系人里填了号码，可直接拨号
- **筛选**：顶部胶囊按钮按类型过滤地图上的点
- **列表与搜索**：按名称 / 地址 / 备注搜索，点击跳回地图对应位置
- **本地存储**：写入应用沙盒的 `cargo_pins.json`，不联网、不上传
- **导出 CSV**：菜单 → 导出 CSV，生成带 BOM 的表格文件，微信 / 邮件发给同事，Excel 打开不乱码
- **示例数据**：首次启动自带 3 个上海示例点，可直接删掉

## 目录结构

```
project.yml                         # XcodeGen 工程描述（替代手写 .xcodeproj）
App/Info.plist                      # 应用信息（显示名、版本、定位权限文案）
App/Resources/Assets.xcassets/      # App 图标（1024 单尺寸，Xcode 自动切图）
App/Sources/CustomApp.swift         # 入口，注入 PinStore
App/Sources/Models/CargoPin.swift   # 数据模型：标注点 + 六种类型
App/Sources/Stores/PinStore.swift   # 本地 JSON 存取 + CSV 导出
App/Sources/Views/MapScreen.swift   # 主界面：地图、筛选、右下角按钮、导出
App/Sources/Views/PinEditorView.swift # 新增 / 编辑 / 删除 / 导航 / 拨号
App/Sources/Views/PinListSheet.swift  # 列表搜索
scripts/build-unsigned-ipa.sh       # 编译 + 打包脚本（CI 里执行）
scripts/make_app_icon.py            # 重新生成 App 图标（可选）
.github/workflows/build-ipa.yml     # GitHub Actions 流水线
codemagic.yaml                      # 备用云构建
```

## 第 1 步：推到 GitHub

在 `custom-ios-app` 目录执行（替换用户名）：

```bash
git init
git add .
git commit -m "init cargo map app"
git branch -M main
git remote add origin https://github.com/<你的用户名>/custom-ios-app.git
git push -u origin main
```

仓库建议设为 **Public**：macOS runner 在公开仓库上基本不占免费额度。

## 第 2 步：跑构建，拿 IPA

1. 仓库页面 → **Actions** → 左侧 `Build unsigned IPA`
2. **Run workflow** → 等 5～10 分钟（首次主要花在 `brew install xcodegen`）
3. 该次 run 页面底部 **Artifacts** → 下载 `CustomApp-unsigned-ipa.zip`
4. 解压得到 `CustomApp-unsigned.ipa`

## 第 3 步：签名安装（你有 Sideloadly / 爱思助手，任意一个都行）

1. 用数据线连 iPhone，手机上点「信任此电脑」
2. 把 `.ipa` 拖进工具，Apple ID 登录（双重认证账号用 **App 专用密码**，不要给主密码）
3. 开始签名，等待完成
4. 手机：**设置 → 通用 → VPN与设备管理 → 信任该开发者**
5. 首次打开若提示需要开发者模式：**设置 → 隐私与安全性 → 开发者模式** 打开并重启，重启后再确认一次

## 免费签名的限制

- **7 天过期**：到期后 App 打不开，重新签一次即可，数据不丢
- 最多同时装 3 个自签 App
- 不支持远程推送等部分能力
- 需要一年有效 / 推送 / 发给别人（TestFlight，最多 100 台），才需要 99 美元/年的开发者账号

## 改功能

- 改界面和交互：`App/Sources/Views/`
- 改字段 / 类型：`App/Sources/Models/CargoPin.swift`（注意同时改 `PinEditorView` 表单和 `PinStore` 的 CSV 表头）
- 加权限：在 `App/Info.plist` 里加对应的 `NS*UsageDescription`，否则调用系统能力会被直接拒绝

## 下一步可以加（说一声我就做）

- 地址自动反查（拖点后自动填地址，需要联网）
- 每个点存照片（提货单 / 现场照片）
- 轨迹记录与历史路线回放
- 多设备同步（需要先定后端：自建 API 或 CloudKit）
- 深浅色主题、字号适配

## 常见问题

- **构建报 `unsupported SDK` / Xcode 版本问题**：把日志贴给我，我在 workflow 里加 `xcode-select` 指定版本
- **安装失败 / bundle id 冲突**：改 `project.yml` 里 `PRODUCT_BUNDLE_IDENTIFIER` 加个后缀，重新构建
- **地图上不显示位置点**：先确认系统定位权限已允许；模拟器或没有定位信号时，手动长按/拖动地图定位即可
- **CSV 中文乱码**：文件已带 UTF-8 BOM，用 Excel / WPS 直接双击打开；用 Numbers 打开也正常
