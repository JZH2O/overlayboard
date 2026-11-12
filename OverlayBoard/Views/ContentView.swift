import SwiftUI
import UIKit

/// 主界面：模拟"另一个 App"的背景内容，悬浮透明画板覆盖其上。
/// 真实使用时，用 iPad 的 Slide Over / 系统级悬浮（见 README）即可让本 App 浮在别的 App 之上。
struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var showHint = true

    var body: some View {
        ZStack {
            // —— 模拟"其他 App"的背景 ——
            mockOtherAppBackground

            // —— 侧拉小悬浮透明画板 ——
            FloatingBoard()
                .environmentObject(settings)

            // —— 首次使用提示 ——
            if showHint {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "hand.draw")
                        Text("拖动顶部条移动 · 拖四角缩放 · 右上角可最大化/最小化 · 设置里可保存默认尺寸。在 iPad 上把本 App 用作 Slide Over 即可贴在其它 App 旁边。")
                            .font(.footnote)
                    }
                    .padding(10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .onTapGesture { withAnimation { showHint = false } }
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }

    /// 模拟一个阅读/笔记类 App 的背景，方便直观看到画板"透明覆盖"效果
    private var mockOtherAppBackground: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("参考文献草稿")
                    .font(.largeTitle.bold())
                Text("这是被画板覆盖的"其他 App"内容。把画板窗口拖到文字上方，即可看到透明叠加效果：只显示你的笔迹，背景文字依然可见。在 iPad 上，从左/右边缘调出 Dock，把本 App 拖成 Slide Over 浮窗，就能贴在 Safari、备忘录、PDF 等任何 App 旁边作画。")
                    .foregroundStyle(.secondary)
                ForEach(0..<12) { i in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("第 \(i + 1) 节 · 要点")
                            .font(.headline)
                        Text(lorem)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Divider()
                }
            }
            .padding(28)
        }
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private let lorem = "Lorem ipsum 中文占位：在真实场景中，这里可能是网页、PDF、视频字幕或任何你正在使用的 App 界面。画板保持透明，只在你落笔处显示标记，方便批注与圈点。"
}

#Preview {
    ContentView().environmentObject(SettingsStore.shared)
}
