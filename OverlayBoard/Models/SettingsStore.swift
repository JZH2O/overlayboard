import SwiftUI

/// 全局设置：默认窗口尺寸、位置、画笔属性。
/// 用 @Published + UserDefaults 持久化（比在 ObservableObject 里用 @AppStorage 更可靠，
/// 因为后者不会触发 objectWillChange，导致视图不刷新）。App 重启后依然生效。
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private let ud = UserDefaults.standard

    // MARK: - 默认窗口尺寸（针对 Slide Over 窄窗 ~320pt 宽优化）
    @Published var defaultWidth:  Double = 280 { didSet { ud.set(defaultWidth,  forKey: "defaultBoardWidth") } }
    @Published var defaultHeight: Double = 380 { didSet { ud.set(defaultHeight, forKey: "defaultBoardHeight") } }
    @Published var defaultX:      Double = 20  { didSet { ud.set(defaultX,      forKey: "defaultBoardX") } }
    @Published var defaultY:      Double = 20  { didSet { ud.set(defaultY,      forKey: "defaultBoardY") } }

    // MARK: - 画笔
    @Published var penColorHex: String = "#FF3B30" { didSet { ud.set(penColorHex, forKey: "penColorHex") } }
    @Published var penWidth:    Double = 4.0      { didSet { ud.set(penWidth,    forKey: "penWidth") } }
    @Published var penOpacity:  Double = 1.0      { didSet { ud.set(penOpacity,  forKey: "penOpacity") } }

    // MARK: - 行为
    @Published var startMinimized: Bool   = false { didSet { ud.set(startMinimized, forKey: "startMinimized") } }
    @Published var boardOpacity:  Double = 0.0   { didSet { ud.set(boardOpacity,  forKey: "boardOpacity") } }

    init() {
        defaultWidth  = loadD("defaultBoardWidth",  280)
        defaultHeight = loadD("defaultBoardHeight", 380)
        defaultX      = loadD("defaultBoardX",      20)
        defaultY      = loadD("defaultBoardY",      20)
        penColorHex   = ud.string(forKey: "penColorHex") ?? "#FF3B30"
        penWidth      = loadD("penWidth",    4.0)
        penOpacity    = loadD("penOpacity",  1.0)
        startMinimized = ud.object(forKey: "startMinimized") as? Bool ?? false
        boardOpacity  = loadD("boardOpacity", 0.0)
    }

    /// 读取 Double；若 key 不存在（而非值为 0）则使用默认值
    private func loadD(_ key: String, _ fallback: Double) -> Double {
        (ud.object(forKey: key) as? Double) ?? fallback
    }

    var penColor: Color {
        get { Color(hex: penColorHex) ?? .red }
        set { penColorHex = newValue.toHex() }
    }

    /// 把当前窗口的尺寸/位置写入"默认"
    func saveAsDefault(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) {
        defaultWidth  = Double(width)
        defaultHeight = Double(height)
        defaultX      = Double(x)
        defaultY      = Double(y)
    }

    /// 读取默认尺寸
    var defaultSize: CGSize { CGSize(width: defaultWidth, height: defaultHeight) }
    /// 读取默认位置
    var defaultOrigin: CGPoint { CGPoint(x: defaultX, y: defaultY) }
}

// MARK: - Color <-> Hex 工具
extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let v = UInt64(h, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red:   Double((v >> 16) & 0xFF) / 255.0,
            green: Double((v >> 8)  & 0xFF) / 255.0,
            blue:  Double( v        & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
    func toHex() -> String {
        #if canImport(UIKit)
        let c = UIColor(self)
        #else
        let c = NSColor(self)
        #endif
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(r * 255), gi = Int(g * 255), bi = Int(b * 255)
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
