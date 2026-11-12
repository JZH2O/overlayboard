import SwiftUI
import UIKit

/// 一条笔画 = 一串点
struct Stroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: UIColor
    var width: CGFloat
}

/// 透明画板：UIKit 实现，捕获触摸并绘制。
/// 背景完全透明（isOpaque=false, clear），可叠加在其它内容之上。
struct DrawingCanvas: UIViewRepresentable {
    @Binding var strokes: [Stroke]
    @Binding var currentColor: Color
    @Binding var currentWidth: CGFloat
    var onChange: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> DrawingView {
        let v = DrawingView()
        v.isOpaque = false
        v.backgroundColor = .clear
        v.coordinator = context.coordinator
        return v
    }

    func updateUIView(_ uiView: DrawingView, context: Context) {
        // 刷新 coordinator 指向最新的 parent（否则 strokes/画笔会停留在旧值）
        context.coordinator.parent = self
        uiView.coordinator = context.coordinator
        uiView.setNeedsDisplay()
    }

    // MARK: - Coordinator
    final class Coordinator {
        var parent: DrawingCanvas
        init(_ p: DrawingCanvas) { parent = p }
    }
}

final class DrawingView: UIView {
    var coordinator: DrawingCanvas.Coordinator?
    private var current: Stroke?

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        let all = (coordinator?.parent.strokes ?? []) + (current.map { [$0] } ?? [])
        for s in all {
            guard s.points.count > 1 else { continue }
            ctx.setStrokeColor(s.color.cgColor)
            ctx.setLineWidth(s.width)
            ctx.beginPath()
            ctx.move(to: s.points[0])
            for p in s.points.dropFirst() { ctx.addLine(to: p) }
            ctx.strokePath()
        }
    }

    // MARK: - 触摸
    override func touchesBegan(_ touches: Set<UITouch>, with e: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        let c = UIColor(coordinator?.parent.currentColor ?? .red)
        let w = coordinator?.parent.currentWidth ?? 4
        current = Stroke(points: [p], color: c, width: w)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with e: UIEvent?) {
        guard let t = touches.first, var cur = current else { return }
        cur.points.append(t.location(in: self))
        current = cur
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with e: UIEvent?) {
        if let cur = current {
            coordinator?.parent.strokes.append(cur)
            coordinator?.parent.onChange?()
        }
        current = nil
        setNeedsDisplay()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with e: UIEvent?) {
        current = nil
        setNeedsDisplay()
    }
}
