import SwiftUI

/// 设置面板：设定/保存默认窗口尺寸与位置、透明度、默认画笔等。
struct SettingsPanel: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    // 当前窗口运行时状态（用于在面板里"存为默认"）
    @Binding var currentOrigin: CGPoint
    @Binding var currentSize: CGSize

    // 本地编辑副本
    @State private var width: Double
    @State private var height: Double
    @State private var posX: Double
    @State private var posY: Double

    init(currentOrigin: Binding<CGPoint>, currentSize: Binding<CGSize>) {
        _currentOrigin = currentOrigin
        _currentSize = currentSize
        _width  = State(initialValue: currentSize.wrappedValue.width)
        _height = State(initialValue: currentSize.wrappedValue.height)
        _posX   = State(initialValue: currentOrigin.wrappedValue.x)
        _posY   = State(initialValue: currentOrigin.wrappedValue.y)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("默认窗口尺寸") {
                    HStack { Text("宽"); Spacer(); TextField("宽", value: $width, format: .number).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("高"); Spacer(); TextField("高", value: $height, format: .number).multilineTextAlignment(.trailing).frame(width: 100) }
                }
                Section("默认位置（相对左上角，点）") {
                    HStack { Text("X"); Spacer(); TextField("X", value: $posX, format: .number).multilineTextAlignment(.trailing).frame(width: 100) }
                    HStack { Text("Y"); Spacer(); TextField("Y", value: $posY, format: .number).multilineTextAlignment(.trailing).frame(width: 100) }
                }
                Section {
                    Button {
                        settings.saveAsDefault(width: width, height: height, x: posX, y: posY)
                    } label: { Label("保存以上为默认值", systemImage: "checkmark.seal") }

                    Button {
                        // 用当前窗口状态直接存为默认
                        settings.saveAsDefault(width: currentSize.width,
                                              height: currentSize.height,
                                              x: currentOrigin.x,
                                              y: currentOrigin.y)
                        width  = currentSize.width
                        height = currentSize.height
                        posX   = currentOrigin.x
                        posY   = currentOrigin.y
                    } label: { Label("把当前窗口存为默认", systemImage: "arrow.down.doc") }
                }

                Section("外观") {
                    Toggle("启动即最小化", isOn: $settings.startMinimized)
                    VStack(alignment: .leading) {
                        Text("板体背景不透明度（0=完全透明）")
                        Slider(value: $settings.boardOpacity, in: 0...1, step: 0.05)
                        Text(String(format: "%.0f%%", settings.boardOpacity * 100))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("默认画笔") {
                    ColorPicker(
                        "画笔颜色",
                        selection: Binding(
                            get: { settings.penColor },
                            set: { settings.penColor = $0 }
                        )
                    )
                    VStack(alignment: .leading) {
                        Text("画笔粗细：\(Int(settings.penWidth))")
                        Slider(value: $settings.penWidth, in: 1...24, step: 1)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        settings.saveAsDefault(width: 280, height: 380, x: 20, y: 20)
                        settings.penColor = .red
                        settings.penWidth = 4
                        settings.boardOpacity = 0
                        settings.startMinimized = false
                    } label: { Label("恢复出厂默认", systemImage: "arrow.counterclockwise") }
                }
            }
            .navigationTitle("画板设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
