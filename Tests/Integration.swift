import AppKit

let appURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fixtures = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let receiverURL = URL(fileURLWithPath: CommandLine.arguments[3], isDirectory: true)
let bundleID = "com.henry.copypath"
let defaults = UserDefaults(suiteName: bundleID)!
let originalDefaults = defaults.persistentDomain(forName: bundleID)
let pasteboard = NSPasteboard.general
let originalClipboard = (pasteboard.pasteboardItems ?? []).map { item in
    Dictionary(uniqueKeysWithValues: item.types.compactMap { type in item.data(forType: type).map { (type, $0) } })
}
var exitCode: Int32 = 0

defer {
    if let originalDefaults { defaults.setPersistentDomain(originalDefaults, forName: bundleID) }
    else { defaults.removePersistentDomain(forName: bundleID) }
    defaults.synchronize()
    pasteboard.clearContents()
    let items = originalClipboard.map { contents in
        let item = NSPasteboardItem()
        for (type, data) in contents { item.setData(data, forType: type) }
        return item
    }
    if !items.isEmpty { pasteboard.writeObjects(items) }
    print("Restored previous clipboard and settings")
    if exitCode != 0 { exit(exitCode) }
}

func waitFor(_ seconds: TimeInterval, until condition: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
        if condition() { return true }
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
    return condition()
}

func check(_ condition: Bool, _ message: String) throws {
    guard condition else { throw NSError(domain: "CopyPath.Integration", code: 1,
                                         userInfo: [NSLocalizedDescriptionKey: message]) }
    print("PASS: \(message)")
}

func openFiles(_ urls: [URL], expecting expected: String, format: PathFormat = .plain,
               forwardTo receiver: URL? = nil) throws {
    defaults.set(format.rawValue, forKey: "pathFormat")
    defaults.set(receiver != nil, forKey: "forwardEnabled")
    defaults.removeObject(forKey: "forwardApplicationBookmark")
    if let receiver { defaults.set(receiver.path, forKey: "forwardApplicationPath") }
    defaults.synchronize()
    pasteboard.clearContents()
    pasteboard.setString("CopyPath integration sentinel", forType: .string)
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = false
    var launchFinished = false
    var launchError: Error?
    NSWorkspace.shared.open(urls, withApplicationAt: appURL, configuration: configuration) { _, error in
        launchError = error
        launchFinished = true
    }
    try check(waitFor(5) { launchFinished } && launchError == nil, "macOS opened \(urls.count) item(s) using Copy Path")
    try check(waitFor(5) { pasteboard.string(forType: .string) == expected }, "Clipboard matches \(format.rawValue) paths exactly")
    try check(waitFor(5) { NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty }, "App exits automatically after copying")
}

do {
    let appInfo = Bundle(url: appURL)?.infoDictionary
    try check(appInfo != nil && appInfo?["LSUIElement"] as? Bool != true && appInfo?["LSBackgroundOnly"] as? Bool != true,
              "App is declared as a regular application for third-party Open With menus")
    try check(NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty,
              "Settings app is closed before integration tests")
    try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
    let single = fixtures.appendingPathComponent("项目 brief.pdf")
    let special = fixtures.appendingPathComponent("it's $HOME `file`.txt")
    let unknown = fixtures.appendingPathComponent("sample.unusualcopypathext")
    let folder = fixtures.appendingPathComponent("文件夹", isDirectory: true)
    for file in [single, special, unknown] { try Data("Copy Path fixture".utf8).write(to: file) }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

    for file in [single, special, folder] {
        let candidates = NSWorkspace.shared.urlsForApplications(toOpen: file)
        try check(candidates.contains { Bundle(url: $0)?.bundleIdentifier == bundleID },
                  "Registered in macOS Open With candidates for \(file.lastPathComponent)")
    }
    try openFiles([single], expecting: single.path)
    try openFiles([single, special], expecting: PathFormat.plain.string(for: [single, special]))
    try openFiles([folder], expecting: folder.path)
    try openFiles([unknown], expecting: unknown.path)
    try openFiles([special], expecting: PathFormat.shell.string(for: [special]), format: .shell)
    try openFiles([single], expecting: PathFormat.fileURL.string(for: [single]), format: .fileURL)

    let logURL = fixtures.appendingPathComponent("forwarded.json")
    if FileManager.default.fileExists(atPath: logURL.path) { try FileManager.default.removeItem(at: logURL) }
    try openFiles([single, special], expecting: PathFormat.plain.string(for: [single, special]), forwardTo: receiverURL)
    try check(waitFor(5) { FileManager.default.fileExists(atPath: logURL.path) }, "Optional forwarding delivers files to another real app")
    let forwarded = try JSONDecoder().decode([String].self, from: Data(contentsOf: logURL))
    try check(forwarded == [single.path, special.path], "Forwarded files preserve exact paths and order")
    print("All integration checks passed")
} catch {
    fputs("FAIL: \(error.localizedDescription)\n", stderr)
    // Leave the top-level scope normally so defer restores the user's state.
    exitCode = 1
}
