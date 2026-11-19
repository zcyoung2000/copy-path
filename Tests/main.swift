import Foundation

func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    guard condition() else { fatalError("FAIL: \(name)") }
    print("PASS: \(name)")
}

let first = URL(fileURLWithPath: "/tmp/项目 brief.pdf")
let second = URL(fileURLWithPath: "/tmp/it's $HOME `file`.txt")
check(PathFormat.plain.string(for: [first, second]) == "/tmp/项目 brief.pdf\n/tmp/it's $HOME `file`.txt", "Unicode, spaces and multiple paths")
let quoted = PathFormat.shell.string(for: [second])
check(quoted == "'/tmp/it'\\''s $HOME `file`.txt'", "Shell quoting protects apostrophes and expansion")
let shell = Process()
shell.executableURL = URL(fileURLWithPath: "/bin/zsh")
shell.arguments = ["-c", "printf '%s' " + quoted]
let output = Pipe()
shell.standardOutput = output
try shell.run()
let roundTrip = output.fileHandleForReading.readDataToEndOfFile()
shell.waitUntilExit()
check(shell.terminationStatus == 0 && String(data: roundTrip, encoding: .utf8) == second.path, "Quoted path survives actual zsh parsing")
let fileURL = PathFormat.fileURL.string(for: [first])
check(URL(string: fileURL)?.path == first.path && fileURL.contains("%20"), "File URL round trip")
check(uniqueFileURLs([first, first, second, URL(string: "https://example.com")!]) == [first, second], "Deduplication preserves order and excludes web URLs")
check(PathFormat.plain.string(for: [URL(fileURLWithPath: "/tmp/a/../folder")]) == "/tmp/folder", "Path normalization")
check(PathFormat.plain.string(for: []) == "", "Empty input")
