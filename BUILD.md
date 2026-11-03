# 一页操作卡：拿到能装的 IPA

这个项目本身已经写完，编译必须在 macOS 上跑。下面是**不需要命令行、不需要 Mac**的最短路径（约 12 分钟，其中 8 分钟是等机器编译）。

## 前提

一个 GitHub 账号（免费，2 分钟注册）。为什么必须是它：iOS 编译只能在苹果的 macOS + Xcode 上跑，免费的 macOS 构建机挂在 GitHub 账号下，账号只能你来注册，编译跑完 IPA 也只存在你的账号里。

## 步骤

### 1. 建仓库

登录 github.com → 右上角 `+` → **New repository**
- Repository name：`cargo-map-ios`
- 选 **Public**
- 点 **Create repository**

### 2. 上传项目（网页拖拽，不用命令行）

在新建的仓库页面 → **Add file** → **Upload files**
把 `cargo-map-ios-project` 里的**全部内容**（包括隐藏的 `.github` 文件夹）拖进网页 → 底部 **Commit changes**

判断成功：仓库文件列表里能看到 `App/`、`project.yml`、`scripts/`，并且顶部出现 **Actions** 标签。

⚠️ 如果拖拽后 `.github` 没上传成功（Actions 标签不出现或者没有 workflow）：
点 **Add file → Create new file**，文件名填 `.github/workflows/build-ipa.yml`（输入 `/` 会自动建目录），把项目里同名文件的内容贴进去，提交即可。

### 3. 等编译

- 上传后 Actions 会自动开始跑；如果没跑：**Actions** → 左侧 `Build unsigned IPA` → **Run workflow**
- 首次约 5～10 分钟
- 完成后 run 页面是绿色 ✅

### 4. 下载 IPA

进那次 run 的页面 → 拉到最底部 **Artifacts** → 下载 `CustomApp-unsigned-ipa.zip`
解压 → 得到 `CustomApp-unsigned.ipa`

### 5. 签名安装（用你现成的安装器）

**未签名的 IPA 直接装一定失败**，必须让安装器用 Apple ID 重新签：

1. iPhone 连电脑，手机上「信任此电脑」
2. IPA 拖进 Sideloadly / 爱思助手
3. 登录 Apple ID（开了双重认证的用 **App 专用密码**，别给主密码）
4. 开始签名 → 完成后手机「设置 → 通用 → VPN与设备管理 → 信任开发者」
5. 首次打开若提示开发者模式：**设置 → 隐私与安全性 → 开发者模式** → 打开 → 重启 → 再确认

免费 Apple ID 签名 **7 天过期**，到期重新签一次即可，标注数据不会丢。

## 失败了怎么办

run 页面点进红色 ❌ 的那一步 → 右上角复制完整日志 → 发给我。常见原因：
- Xcode 版本 / SDK 不匹配（我改 workflow）
- `.github` 没上传成功（见步骤 2 的补救）
- 图标 asset catalog 格式问题（我改 JSON）

## 有 Mac 的替代路径

`brew install xcodegen` → 在项目目录跑 `bash scripts/build-unsigned-ipa.sh` → 得到未签名 IPA → 同样用安装器签名安装。或者 Xcode 直接打开工程（先 `xcodegen generate`），选个人免费 Team 跑真机。
