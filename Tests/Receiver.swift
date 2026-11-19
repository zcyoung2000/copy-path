import AppKit

final class Receiver: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        let output = Bundle.main.object(forInfoDictionaryKey: "CopyPathTestOutput") as! String
        let data = try! JSONEncoder().encode(urls.map { $0.standardizedFileURL.path })
        try! data.write(to: URL(fileURLWithPath: output))
        application.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = Receiver()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
