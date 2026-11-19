import Foundation
import UniformTypeIdentifiers

let template = URL(fileURLWithPath: CommandLine.arguments[1])
let extensionsFile = URL(fileURLWithPath: CommandLine.arguments[2])
let destination = URL(fileURLWithPath: CommandLine.arguments[3])
var info = try PropertyListSerialization.propertyList(from: Data(contentsOf: template), format: nil) as! [String: Any]
let extensions = try String(contentsOf: extensionsFile, encoding: .utf8)
    .split(whereSeparator: { $0.isWhitespace }).map(String.init)
let types = Set(extensions.flatMap {
    UTType.types(tag: $0, tagClass: .filenameExtension, conformingTo: nil).map(\.identifier)
}).sorted()
var declarations = info["CFBundleDocumentTypes"] as! [[String: Any]]
declarations.append([
    "CFBundleTypeName": "Common Files",
    "CFBundleTypeRole": "Viewer",
    "LSHandlerRank": "Alternate",
    "CFBundleTypeExtensions": extensions,
    "LSItemContentTypes": types,
])
info["CFBundleDocumentTypes"] = declarations
try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: destination)
print("Declared \(types.count) file types for Open With menus")
