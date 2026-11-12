import SwiftUI

/// 侧拉小悬浮窗：可拖拽移动、四角缩放、最大化/最小化、透明画板。
struct FloatingBoard: View {
    @EnvironmentObject var settings: SettingsStore

    // 运行时状态（不持久化，除非"存为默认"）
    @State private var origin: CGPoint       // 窗口左上角位置（相对容器）
    @State private var size: CGSize
    @State private var minimized = false
    @State private var maximized = false

    // 最大化前记住的窗口尺寸/位置，便于还原
    @State private var savedOrigin: CGPoint?
    @State private var savedSize: CGSize?

    // 画板内容
    @State private var strokes: [Stroke] = []
    @State private var showSettings = false
    @State private var showPenPanel = true

    // 缩放手势起点（基于手势开始时的尺寸/位置计算，避免累加误差）
    @State private var rsSize: CGSize = .zero
    @State private var rsOrigin: CGPoint = .zero
    @State private var rsActive = false

    // 容器尺寸（用于边界约束 & 最大化）
    @State private var containerSize: CGSize = .zero

    // 最小/最大尺寸
    private let minSize = CGSize(width: 80, height: 80)
    private let maxSizeRatio: CGFloat = 0.92

    init() {
        // 用默认设置初始化（可用"存为默认"覆盖）
        _origin = State(initialValue: SettingsStore.shared.defaultOrigin)
        _size   = State(initialValue: SettingsStore.shared.defaultSize)
        _minimized = State(initialValue: SettingsStore.shared.startMinimized)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if minimized {
                    minimizedPill
                } else {
                    board(geo: geo)
                }
            }
            .onAppear {
                containerSize = geo.size
                if settings.startMinimized { minimized = true }
            }
            .onChange(of: geo.size) { _, newSize in
                containerSize = newSize
                clampPosition()
            }
        }
    }

    // MARK: - 最小化后的小圆钮
    private var minimizedPill: some View {
        Button {
            withAnimation(.spring()) { minimized = false }
        } label: {
            Image(systemName: "pencil.tip.crop.circle")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1.5))
                .shadow(radius: 6)
        }
        .position(x: origin.x + 28, y: origin.y + 28)
        .draggablePosition($origin, size: CGSize(width: 56, height: 56), container: containerSize)
    }

    // MARK: - 主窗口
    private func board(geo: GeometryProxy) -> some View {
        let isMax = maximized
        let base = ZStack(alignment: .topLeading) {
            // —— 透明画板本体 ——
            DrawingCanvas(
                strokes: $strokes,
                currentColor: Binding(
                    get: { settings.penColor },
                    set: { settings.penColor = $0 }
                ),
                currentWidth: Binding(
                    get: { CGFloat(settings.penWidth) },
                    set: { settings.penWidth = Double($0) }
                )
            )
            .background(
                // 板体背景透明度可调：0 = 完全透明（只看到笔迹）
                Color.black.opacity(settings.boardOpacity)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .allowsHitTesting(true) // 触摸交给画板绘图

            // —— 顶部标题条（用于拖拽 + 控制按钮） ——
            topBar
                .padding(6)

            // —— 画笔工具条 ——
            if showPenPanel {
                penPanel
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(width: size.width, height: size.height)
        .position(x: origin.x + size.width/2, y: origin.y + size.height/2)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1.5)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        )
        .onChange(of: containerSize) { _, _ in clampPosition() }

        // 四角缩放手柄：用 overlay(alignment:) 精确贴在四角
        if !isMax {
            return AnyView(base
                .overlay(alignment: .topLeading)     { cornerDot(pos: .topLeft) }
                .overlay(alignment: .topTrailing)    { cornerDot(pos: .topRight) }
                .overlay(alignment: .bottomLeading)  { cornerDot(pos: .bottomLeft) }
                .overlay(alignment: .bottomTrailing) { cornerDot(pos: .bottomRight) }
            )
        }
        return AnyView(base)
    }

    // MARK: - 顶栏
    private var topBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.white.opacity(0.9))
            Text("画板")
                .font(.caption.bold())
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 6) {
                Button { withAnimation { showPenPanel.toggle() } } label: {
                    Image(systemName: showPenPanel ? "pencil" : "pencil.slash")
                        .font(.caption).foregroundStyle(.white)
                }
                Button { withAnimation { showSettings.toggle() } } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption).foregroundStyle(.white)
                }
                Button { toggleMaximize() } label: {
                    Image(systemName: maximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.caption).foregroundStyle(.white)
                }
                Button { withAnimation { minimized = true } } label: {
                    Image(systemName: "minus")
                        .font(.caption.bold()).foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        // 整条标题栏可拖拽移动窗口
        .draggablePosition($origin, size: size, container: containerSize)
        .sheet(isPresented: $showSettings) {
            SettingsPanel(currentOrigin: $origin, currentSize: $size)
                .environmentObject(settings)
        }
    }

    // MARK: - 画笔工具条
    private var penPanel: some View {
        HStack(spacing: 14) {
            ForEach(["#FF3B30","#FF9500","#FFCC00","#34C759","#007AFF","#FFFFFF","#000000"], id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex) ?? .gray)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                    .onTapGesture { settings.penColor = Color(hex: hex) ?? .red }
            }
            Divider().frame(height: 20)
            Button { if settings.penWidth > 1 { settings.penWidth -= 1 } }
                label: { Image(systemName: "minus.magnifyingglass").foregroundStyle(.white) }
            Text("\(Int(settings.penWidth))")
                .font(.caption).foregroundStyle(.white).frame(width: 18)
            Button { if settings.penWidth < 24 { settings.penWidth += 1 } }
                label: { Image(systemName: "plus.magnifyingglass").foregroundStyle(.white) }
            Divider().frame(height: 20)
            Button { strokes.removeAll() } label: {
                Image(systemName: "trash").foregroundStyle(.white)
            }
            Button { if !strokes.isEmpty { strokes.removeLast() } } label: {
                Image(systemName: "arrow.uturn.backward").foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - 四角缩放手柄
    private func cornerDot(pos: Corner) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 20, height: 20)
            .shadow(radius: 2)
            .overlay(Circle().stroke(.black.opacity(0.2), lineWidth: 1))
            .padding(8)
            .contentShape(Circle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !rsActive { rsSize = size; rsOrigin = origin; rsActive = true }
                        resize(from: pos, translation: value.translation,
                               startSize: rsSize, startOrigin: rsOrigin)
                    }
                    .onEnded { _ in rsActive = false }
            )
    }

    // MARK: - 行为与约束
    private func toggleMaximize() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if maximized {
                // 还原
                if let s = savedSize { size = s }
                if let o = savedOrigin { origin = o }
                maximized = false
            } else {
                savedSize = size
                savedOrigin = origin
                size = CGSize(width: containerSize.width * maxSizeRatio,
                              height: containerSize.height * maxSizeRatio)
                origin = CGPoint(x: (containerSize.width - size.width)/2,
                                 y: (containerSize.height - size.height)/2)
                maximized = true
            }
        }
    }

    private func clampPosition() {
        let maxX = max(0, containerSize.width  - size.width)
        let maxY = max(0, containerSize.height - size.height)
        origin.x = min(max(origin.x, 0), maxX)
        origin.y = min(max(origin.y, 0), maxY)
    }

    private func resize(from corner: Corner,
                        translation: CGSize,
                        startSize: CGSize,
                        startOrigin: CGPoint) {
        var newSize = startSize
        var newOrigin = startOrigin
        let dx = translation.width
        let dy = translation.height
        switch corner {
        case .topLeft:
            newSize.width  = clamp(startSize.width  - dx, minSize.width, maxW())
            newSize.height = clamp(startSize.height - dy, minSize.height, maxH())
            newOrigin.x = startOrigin.x + (startSize.width - newSize.width)
            newOrigin.y = startOrigin.y + (startSize.height - newSize.height)
        case .topRight:
            newSize.width  = clamp(startSize.width  + dx, minSize.width, maxW())
            newSize.height = clamp(startSize.height - dy, minSize.height, maxH())
            newOrigin.y = startOrigin.y + (startSize.height - newSize.height)
        case .bottomLeft:
            newSize.width  = clamp(startSize.width  - dx, minSize.width, maxW())
            newSize.height = clamp(startSize.height + dy, minSize.height, maxH())
            newOrigin.x = startOrigin.x + (startSize.width - newSize.width)
        case .bottomRight:
            newSize.width  = clamp(startSize.width  + dx, minSize.width, maxW())
            newSize.height = clamp(startSize.height + dy, minSize.height, maxH())
        }
        size = newSize
        origin = newOrigin
        clampPosition()
    }

    private func maxW() -> CGFloat { max(minSize.width, containerSize.width  * 0.95) }
    private func maxH() -> CGFloat { max(minSize.height, containerSize.height * 0.95) }

    private enum Corner { case topLeft, topRight, bottomLeft, bottomRight }
}

private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    min(max(v, lo), hi)
}

// MARK: - 可拖拽位置修饰器（基于位移增量，与坐标系无关）
struct DraggablePosition: ViewModifier {
    @Binding var origin: CGPoint
    let size: CGSize
    let container: CGSize
    @State private var start: CGPoint = .zero
    @State private var active = false

    func body(content: Content) -> some View {
        content.gesture(
            DragGesture()
                .onChanged { value in
                    if !active { start = origin; active = true }
                    var o = CGPoint(x: start.x + value.translation.width,
                                    y: start.y + value.translation.height)
                    // 约束在容器内，保证整个窗口可见
                    let maxX = max(0, container.width  - size.width)
                    let maxY = max(0, container.height - size.height)
                    o.x = min(max(o.x, 0), maxX)
                    o.y = min(max(o.y, 0), maxY)
                    origin = o
                }
                .onEnded { _ in active = false }
        )
    }
}

extension View {
    func draggablePosition(_ origin: Binding<CGPoint>,
                           size: CGSize,
                           container: CGSize) -> some View {
        self.modifier(DraggablePosition(origin: origin, size: size, container: container))
    }
}
