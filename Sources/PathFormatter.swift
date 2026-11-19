import Foundation

enum PathFormat: String, CaseIterable, Identifiable {
    case plain, shell, fileURL

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plain: return "完整路径"
        case .shell: return "终端引用"
        case .fileURL: return "文件 URL"
        }
    }

    var detail: String {
        switch self {
        case .plain: return "多个文件每行一个路径，适合粘贴到聊天、编辑器和表单。"
        case .shell: return "用单引号保护空格和特殊字符，可直接作为终端命令的参数。"
        case .fileURL: return "复制以 file:// 开头的地址，空格和中文会进行 URL 编码。"
        }
    }

    func string(for urls: [URL]) -> String {
        let values = urls.filter(\.isFileURL).map { url in
            let file = url.standardizedFileURL
            switch self {
            case .plain: return file.path
            case .shell: return "'" + file.path.replacingOccurrences(of: "'", with: "'\\''") + "'"
            case .fileURL: return file.absoluteString
            }
        }
        return values.joined(separator: self == .shell ? " " : "\n")
    }
}

func uniqueFileURLs(_ urls: [URL]) -> [URL] {
    var seen = Set<String>()
    return urls.filter(\.isFileURL).map(\.standardizedFileURL).filter {
        seen.insert($0.path).inserted
    }
}
