import SwiftUI
import UIKit

/// 真·系统级悬浮窗接入骨架（方案③）
/// ====================================================================
/// 在「有对应 entitlement / 企业证书 / 越狱环境」下，把画板挂到一个
/// 高 windowLevel 的 UIWindow 上，即可让它突破 App 沙盒，常驻浮于
/// 任意其它 App 之上并接收触摸作画。
///
/// 没有特殊权限时，这段代码依然能编译运行——只是窗口被限制在 App 自身
/// 内（等同于普通的全屏覆盖层）。一旦 provisioning 带上
/// `com.apple.multitasking.system.overlay`，它就会变成系统级悬浮窗。
///
/// 用法（在 App 启动后调用一次）：
///     SystemOverlay.shared.show(hostedView: FloatingBoard().environmentObject(SettingsStore.shared))
/// ====================================================================

@MainActor
final class SystemOverlay {
    static let shared = SystemOverlay()

    private var overlayWindow: UIWindow?
    private var hostController: UIHostingController<AnyView>?

    /// 把任意 SwiftUI 视图挂到系统级悬浮窗
    func show<Content: View>(hostedView: Content) {
        guard let scene = UIApplication.shared
            .connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        let controller = UIHostingController(rootView: AnyView(hostedView))
        controller.view.backgroundColor = .clear
        // 关键：把窗口层级提到最高，配合 entitlement 即成为系统级常驻悬浮
        controller.view.window?.windowLevel = .alert + 1

        let win = PassThroughWindow(windowScene: scene)
        win.rootViewController = controller
        win.windowLevel = .alert + 1     // 高于所有普通窗口
        win.backgroundColor = .clear
        win.isHidden = false
        win.makeKeyAndVisible()          // 注意：设为 key 会接管触摸；见下方说明

        self.overlayWindow = win
        self.hostController = controller
    }

    func hide() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
    }
}

/// 背景透明的 UIWindow
final class PassThroughWindow: UIWindow {
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 接入示例（演示按钮）
/// 在需要"开启系统悬浮"的地方调用，例如设置面板里的开关：
///
///     Button("开启系统级悬浮画板") {
///         SystemOverlay.shared.show(hostedView: FloatingBoard().environmentObject(SettingsStore.shared))
///     }
///
/// ⚠️ 若不想接管整个屏幕的触摸（保留对下方 App 的交互），
///    不要调用 makeKeyAndVisible()，改为仅 isHidden = false，
///    并让 FloatingBoard 内部自行处理透明区域的触摸穿透。
