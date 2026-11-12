# 悬浮画板 OverlayBoard（iPad · Slide Over 路线）

一个 iPad 应用：侧拉小悬浮窗口，窗口大小可调节，可设置默认值；界面透明，用来在其他 App 上做画板；支持最大化 / 最小化。

本版本走 **Slide Over 多任务** 路线——App 本身就是可被 iPad 系统当作"侧拉小浮窗"的应用，能贴在 Safari、备忘录、PDF、视频等任何 App 旁边使用。**无需任何特殊权限、可正常上架、开箱即可编译运行。**

---

## 功能清单

| 需求 | 实现 |
|---|---|
| 侧拉小悬浮窗口 | 本 App 作为 Slide Over 浮窗出现在其它 App 旁边；App 内另有一个可拖拽的悬浮画板窗口 |
| 窗口大小可调节 | 四角白色圆点拖拽缩放（最小 80×80，最大约屏幕 95%） |
| 可设置默认值 | 设置面板「保存为默认值」，写入 `UserDefaults`，下次启动自动套用 |
| 界面透明 | 板体背景不透明度可调（默认 0 = 完全透明，只显示笔迹）；画板 `backgroundColor = .clear` |
| 在其他 App 上做画板 | 用 iPad **Slide Over** 把本 App 贴在目标 App 旁边，在透明画板上标注 |
| 最大 / 最小化 | 顶栏按钮：最大化展开近满屏、最小化收缩为悬浮小圆钮（点击恢复） |
| 画笔 | 7 色 + 粗细 1–24 + 清除 / 撤销上一笔 |

---

## 运行环境

- Xcode 15+，iPadOS 17+（用到 iOS 17 的 `onChange` 两参闭包与 `#Preview`）
- 目标设备：iPad（`TARGETED_DEVICE_FAMILY = 2`）

> 因为启用了多任务（`UIRequiresFullScreen = false`），本 App **必须跑在真机或 iPad 模拟器上**；iPhone 模拟器不支持 Slide Over。

---

## 怎么装到 iPad（两种办法）

> iOS App 必须在 **macOS + Xcode** 里编译并签名，无法在 Linux 服务器上直接产出 `.ipa`。
> 工程我已经替你生成好合法的 `OverlayBoard.xcodeproj`，你只需在 Mac 上**打开 → 选 Team → Run** 即自动安装到 iPad。

### 办法一：一键脚本（推荐，Mac 上执行）
```bash
cd ipad-floating-board
chmod +x build_install.sh
TEAM_ID=你的TeamID ./build_install.sh     # 免费 Apple ID 也行，7 天有效
```
脚本会：编译 → 生成 `.app` → 通过 `xcrun devicectl` 装到已连接的 iPad。
（未连设备时会自动改回手动步骤提示。）

### 办法二：Xcode 手动 Run（最简单）
1. 把整个 `ipad-floating-board/` 文件夹拷到 Mac。
2. 双击 `OverlayBoard.xcodeproj` 用 Xcode 打开。
3. 左侧选 `OverlayBoard` target → **Signing & Capabilities** → Team 选你的 Apple ID（没有就点 Add，免费即可）。
4. 用数据线连上 iPad，Xcode 顶部设备选该 iPad，点 ▶︎ **Run**。
5. 首次安装需在 iPad 上：设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID。

> 想要 `.xcodeproj` 由代码重新生成？`brew install xcodegen && xcodegen generate` 即可（`project.yml` 已配好）。

---

## 🚀 没有 Mac？云端编译 + 侧载（推荐给无 Mac 用户）

全程不需要 Mac、不需要付费。原理：用 **GitHub 的云端 Mac** 把代码编译成 IPA，你用 **Windows / Linux 电脑**通过侧载工具 + 自己的（免费）Apple ID 装到 iPad。

### 第 1 步：把代码推到 GitHub（公开仓库，macOS 构建免费）
```bash
cd ipad-floating-board
git init && git add -A && git commit -m "OverlayBoard"
# 在 github.com 新建一个公开仓库，然后把下面两行里的 URL 换成你的
git remote add origin https://github.com/<你的用户名>/overlayboard.git
git push -u origin main
```
推送后，GitHub Actions 会自动跑 `.github/workflows/build-ipa.yml`，在云端 Mac 上编译。

### 第 2 步：下载未签名 IPA
- 进你的仓库 → **Actions** → 最新一次 **Build IPA** 运行 → 右侧 **Artifacts** → 下载 `OverlayBoard-unsigned-ipa`（里面是 `OverlayBoard-unsigned.ipa`）。

### 第 3 步：侧载到 iPad
- **Windows 用户**：装 [Sideloadly](https://sideloadly.io/) → 数据线连 iPad → 选刚下的 IPA → 填你的 Apple ID（就是 iCloud 那个）→ 点 Start → 在 iPad 上 设置 → 通用 → VPN与设备管理 → 信任该 Apple ID。
- **Linux 用户**：用 [AltServer-Python](https://github.com/powenn/AltServer-Linux)（或 SideStore）先在 iPad 上装好 AltStore，再用 AltStore 打开 IPA 安装（免费 Apple ID，每 7 天需刷新一次，AltStore 可自动刷新）。

> 免费 Apple ID 签名的 App 有效期 7 天；Sideloadly / AltStore 都支持一键刷新，日常用没问题。若要长期/无限期，才需要 $99/年的开发者账号（见文末"后续路线"）。

### 装好之后
iPad 上打开「悬浮画板」，再用 **Slide Over**（从底部上滑出 Dock → 长按本 App 拖到屏幕左/右边缘）把它贴到 Safari、备忘录、PDF 等任意 App 旁边，在透明画板上标注即可。

---

## 怎么用 Slide Over 把它贴到别的 App 上

1. 先打开你想"画在上面"的 App（比如 Safari、备忘录、PDF 阅读器）。
2. 从 iPad 屏幕底部边缘**向上轻扫调出 Dock**。
3. 长按本 App 的图标，拖到当前 App 界面的**左侧或右侧边缘**，松手——本 App 即以**侧拉浮窗**形式停靠在旁边。
4. 拖动浮窗顶部的小横条可让它在左右两侧切换；向上轻扫浮窗可临时收起。
5. 在浮窗里用透明画板标注，画完随时滑走浮窗、回到原 App 看效果。

> 想"透过画板看到背后 App 的内容"：把板体背景不透明度设为 0（默认即是），画板只显示你的笔迹，背后浮窗内的内容（或你并排摆放的另一个 App）依然可见。

---

## 代码结构

```
OverlayBoard/
├── OverlayBoardApp.swift        # @main 入口，注入全局 SettingsStore
├── Models/
│   └── SettingsStore.swift      # @Published + UserDefaults 持久化：默认尺寸/位置/画笔/透明度
├── Views/
│   ├── ContentView.swift        # 主界面（含模拟"其他 App"背景，便于看透明效果）
│   ├── FloatingBoard.swift      # 核心：悬浮窗（拖拽/缩放/最大最小/透明）
│   ├── DrawingCanvas.swift      # 透明画板（UIKit 触摸绘制，backgroundColor=.clear）
│   ├── SettingsPanel.swift      # 设置：保存默认尺寸/位置、透明度、画笔
│   └── SystemOverlay.swift      # （可选）真·系统级悬浮接入骨架，见下
├── Resources/
│   └── Info.plist               # UIRequiresFullScreen=false → 支持 Slide Over/分屏
└── OverlayBoard.entitlements    # 本路线为空即可正常签名
project.yml                      # XcodeGen 工程定义
```

---

## 后续可升级的两条路线（本版本未启用）

- **② 画中画 PiP 叠加层**：让画板以 PiP 形式真正浮在任意 App 之上（`SystemOverlay.swift` 已留接入点；需给 Info.plist 加回 `UIBackgroundModes: audio`）。限制：手指不能直接在 PiP 里作画。
- **③ 真·系统级悬浮窗**：突破沙盒、常驻浮于任意 App 之上且可直接手指作画。需要在拿到企业证书 / 越狱自签 / Apple 特殊授权后，向 `OverlayBoard.entitlements` 加回 `com.apple.multitasking.system.overlay`。无法走 App Store 分发。

---

## 已知限制 / 可扩展

- 当前笔画保存在内存，重启不保留；如需持久可把 `strokes` 序列化到文件。
- Slide Over 浮窗本身由系统接管外观，因此"画板透明"指的是 App 内画板透明叠加，而非穿透系统浮窗看到背后 App——这是 iPad 多任务的固有限制。若要穿透式覆盖，请走路线 ②③。
- 可加：橡皮擦、形状识别、导出 PNG、多画板分页。
