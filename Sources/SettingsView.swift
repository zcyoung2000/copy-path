import AppKit
import SwiftUI

private let accent = Color(red: 0.12, green: 0.58, blue: 0.43)

struct SettingsView: View {
    @ObservedObject var settings: Settings
    let copyFiles: () -> Void

    private var preview: String {
        settings.format.string(for: [URL(fileURLWithPath: "/Users/henry/Documents/项目 brief.pdf")])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 16) {
                Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage())
                    .resizable().frame(width: 68, height: 68)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Copy Path").font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("以此应用打开，路径即刻复制。")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("怎么使用", systemImage: "cursorarrow.click.2")
                    .font(.system(size: 13, weight: .semibold))
                Text("在 Finder 或其他应用中，选择文件的「打开方式」→ Copy Path。也可以将文件拖到此应用图标上。")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(accent)
                    Text("支持文件、文件夹和多选，无需常驻。")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16).background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 10) {
                Text("复制格式").font(.system(size: 13, weight: .semibold))
                Picker("复制格式", selection: $settings.format) {
                    ForEach(PathFormat.allCases) { format in Text(format.title).tag(format) }
                }.pickerStyle(.segmented).labelsHidden()
                Text(preview).font(.system(size: 11.5, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.primary.opacity(0.07)))
                Text(settings.format.detail).font(.system(size: 12)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                Toggle("复制后用指定应用打开", isOn: $settings.forwardEnabled)
                    .font(.system(size: 13, weight: .medium))
                if settings.forwardEnabled {
                    HStack(spacing: 10) {
                        if let url = settings.applicationURL {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable().frame(width: 26, height: 26)
                        } else {
                            Image(systemName: "app.dashed").font(.system(size: 22)).foregroundStyle(.secondary)
                        }
                        Text(settings.applicationName).font(.system(size: 13)).lineLimit(1)
                        Spacer()
                        Button(settings.applicationURL == nil ? "选择应用…" : "更换…") {
                            settings.chooseApplication()
                        }
                    }
                    .padding(10).background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
                    if settings.applicationURL == nil {
                        Text("尚未选择应用时，只复制路径。")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
                Toggle("复制成功时显示短暂提示", isOn: $settings.showConfirmation)
                    .font(.system(size: 13))
            }

            Divider()
            HStack {
                Text("设置自动保存").font(.system(size: 11)).foregroundStyle(.tertiary)
                Spacer()
                Button(action: copyFiles) {
                    Label("选择文件并复制…", systemImage: "doc.on.clipboard")
                }.controlSize(.large)
            }
        }
        .padding(28)
        .frame(width: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(accent)
    }
}

struct ConfirmationView: View {
    let count: Int
    let filename: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28)).foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(count == 1 ? "已复制文件路径" : "已复制 \(count) 个路径")
                    .font(.system(size: 14, weight: .semibold))
                Text(filename).font(.system(size: 12)).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(18).frame(width: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.08)))
    }
}
