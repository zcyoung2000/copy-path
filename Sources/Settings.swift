import AppKit
import Combine
import UniformTypeIdentifiers

final class Settings: ObservableObject {
    @Published var format: PathFormat {
        didSet { UserDefaults.standard.set(format.rawValue, forKey: "pathFormat") }
    }
    @Published var showConfirmation: Bool {
        didSet { UserDefaults.standard.set(showConfirmation, forKey: "showConfirmation") }
    }
    @Published var forwardEnabled: Bool {
        didSet { UserDefaults.standard.set(forwardEnabled, forKey: "forwardEnabled") }
    }
    @Published private(set) var applicationURL: URL?

    var applicationName: String {
        guard let url = applicationURL else { return "选择应用…" }
        return FileManager.default.displayName(atPath: url.path)
    }

    init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: ["showConfirmation": true])
        format = PathFormat(rawValue: defaults.string(forKey: "pathFormat") ?? "") ?? .plain
        showConfirmation = defaults.bool(forKey: "showConfirmation")
        forwardEnabled = defaults.bool(forKey: "forwardEnabled")
        if let data = defaults.data(forKey: "forwardApplicationBookmark") {
            var stale = false
            applicationURL = try? URL(resolvingBookmarkData: data, options: .withoutUI,
                                      relativeTo: nil, bookmarkDataIsStale: &stale)
        }
        if applicationURL == nil, let path = defaults.string(forKey: "forwardApplicationPath") {
            applicationURL = URL(fileURLWithPath: path, isDirectory: true)
        }
    }

    func chooseApplication() {
        let panel = NSOpenPanel()
        panel.title = "选择复制路径后打开文件的应用"
        panel.prompt = "选择应用"
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard Bundle(url: url)?.bundleIdentifier != Bundle.main.bundleIdentifier else {
            let alert = NSAlert()
            alert.messageText = "请选择其他应用"
            alert.informativeText = "Copy Path 负责复制路径，转交给自身会造成循环。"
            alert.runModal()
            return
        }
        applicationURL = url
        let defaults = UserDefaults.standard
        defaults.set(url.path, forKey: "forwardApplicationPath")
        if let bookmark = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil,
                                               relativeTo: nil) {
            defaults.set(bookmark, forKey: "forwardApplicationBookmark")
        } else {
            defaults.removeObject(forKey: "forwardApplicationBookmark")
        }
        forwardEnabled = true
    }
}
