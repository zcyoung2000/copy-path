import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let settings = Settings()
    private var settingsWindow: NSWindow?
    private var toast: NSPanel?
    private var launchWork: DispatchWorkItem?
    private var copyWork: DispatchWorkItem?
    private var toastWork: DispatchWorkItem?
    private var quitWork: DispatchWorkItem?
    private var pendingURLs: [URL] = []
    private var receivedFiles = false
    private var forwardingCount = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.receivedFiles else { return }
            self.showSettings()
        }
        launchWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        receive(urls)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
        NSApp.setActivationPolicy(.accessory)
        scheduleQuit()
    }

    private func buildMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于 Copy Path", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "设置…", action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "退出 Copy Path", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)
        NSApp.mainMenu = mainMenu
    }

    @objc private func showAbout() { NSApp.orderFrontStandardAboutPanel(nil) }

    @objc private func showSettings() {
        quitWork?.cancel()
        NSApp.setActivationPolicy(.regular)
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
                                  styleMask: [.titled, .closable, .miniaturizable],
                                  backing: .buffered, defer: false)
            window.title = "Copy Path"
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.contentView = NSHostingView(rootView: SettingsView(settings: settings, copyFiles: { [weak self] in
                self?.chooseFiles()
            }))
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.title = "选择要复制路径的文件或文件夹"
        panel.prompt = "复制路径"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK { receive(panel.urls) }
    }

    private func receive(_ urls: [URL]) {
        receivedFiles = true
        launchWork?.cancel()
        quitWork?.cancel()
        pendingURLs.append(contentsOf: urls)
        copyWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.copyPendingFiles() }
        copyWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    private func copyPendingFiles() {
        let urls = uniqueFileURLs(pendingURLs)
        pendingURLs.removeAll()
        guard !urls.isEmpty else {
            showError("没有收到本地文件", detail: "请从应用的文件「打开方式」菜单使用 Copy Path。")
            return
        }
        let text = settings.format.string(for: urls)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            showError("无法写入剪贴板", detail: "请重试。")
            return
        }
        if settings.showConfirmation { showConfirmation(urls) }
        if settings.forwardEnabled, let target = settings.applicationURL {
            guard Bundle(url: target)?.bundleIdentifier != Bundle.main.bundleIdentifier else {
                showError("路径已复制，无法转交给自身", detail: "请在设置中选择其他应用。")
                return
            }
            forwardingCount += 1
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.open(urls, withApplicationAt: target, configuration: configuration) { [weak self] _, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.forwardingCount -= 1
                    if let error {
                        self.showError("路径已复制，但打开文件失败", detail: error.localizedDescription)
                    } else {
                        self.scheduleQuit()
                    }
                }
            }
        }
        scheduleQuit()
    }

    private func showConfirmation(_ urls: [URL]) {
        toastWork?.cancel()
        toast?.close()
        let panel = NSPanel(contentRect: .zero,
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let filename = urls.count == 1 ? urls[0].lastPathComponent : "多个文件，每个路径均已加入剪贴板"
        let host = NSHostingView(rootView: ConfirmationView(count: urls.count, filename: filename))
        panel.contentView = host
        panel.setContentSize(host.fittingSize)
        let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2, y: frame.minY + 60))
        }
        panel.orderFrontRegardless()
        toast = panel
        let work = DispatchWorkItem { [weak self] in self?.toast?.close(); self?.toast = nil }
        toastWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: work)
    }

    private func showError(_ message: String, detail: String) {
        quitWork?.cancel()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = detail
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
        scheduleQuit()
    }

    private func scheduleQuit() {
        quitWork?.cancel()
        guard settingsWindow == nil, forwardingCount == 0 else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.settingsWindow == nil, self.pendingURLs.isEmpty, self.forwardingCount == 0 else { return }
            NSApp.terminate(nil)
        }
        quitWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85, execute: work)
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
