import SwiftUI

@main
struct OverlayBoardApp: App {
    // 全局设置（默认尺寸/位置/画笔）通过 @AppStorage 持久化
    @StateObject private var settings = SettingsStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .ignoresSafeArea() // 让画板可铺满到边缘
        }
    }
}
