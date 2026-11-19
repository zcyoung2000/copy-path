import CoreServices
import Foundation

let url = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let result = LSRegisterURL(url as CFURL, true)
guard result == noErr else {
    fputs("Unable to register app: \(result)\n", stderr)
    exit(1)
}
print("Registered Copy Path with macOS")
