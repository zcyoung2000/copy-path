# Copy Path

[English](README.md) · [下载应用](https://github.com/zcyoung2000/copy-path/releases/latest) · [MIT 许可证](LICENSE)

一个原生 macOS 应用：在其他应用的“打开方式”中选择 **Copy Path**，即可复制所选文件的完整路径。

## 使用

1. 从 [Releases](https://github.com/zcyoung2000/copy-path/releases/latest) 下载并解压，将 `Copy Path.app` 放入 `/Applications`（推荐）。
2. 在 Finder 或第三方应用中选择文件的 **打开方式 → Copy Path**。
3. 粘贴即可得到文件路径。多选时，默认每行一个路径。

PDF、文本、图片、Office 文档、音视频、压缩包及常见代码文件都声明了对应类型，可进入系统的“打开方式”候选列表；任意其他文件也可交给此应用处理。

如果菜单中没有出现，选择 **打开方式 → 其他…**，定位到 `Copy Path.app`。如果选择器过滤了应用，切换到“所有应用”。macOS 不会将通配类型自动列入每一种文件的推荐菜单，所以罕见或新增类型可能需要此步骤。能否直接出现在菜单中还取决于第三方应用是否使用 macOS 的打开方式机制。只提供自定义、固定应用列表的软件，仍需它自身支持添加外部应用。

也可拖放文件到应用图标，或直接启动应用，使用 **选择文件并复制…**。

## 设置

双击应用即可打开设置，修改后自动保存：

- **完整路径**（默认）：多文件按行排列，保留中文、空格和特殊字符。
- **终端引用**：将每个路径安全地用单引号包裹，多文件以空格分隔，可粘贴作为命令参数。
- **文件 URL**：生成经过 URL 编码的 `file://` 地址。
- **复制后用指定应用打开**（默认关闭）：通过系统应用选择器指定一个接收文件的应用。
- **复制成功时显示短暂提示**（默认开启）：提示不抢焦点，也不需要通知权限。

只打开文件时，复制后自动退出；打开设置窗口时保持运行。没有登录启动项、网络访问或辅助功能权限要求，也不会修改文件类型的默认打开应用。

复制的是收到文件的本地路径。云盘或第三方应用若提供临时副本，路径会指向该临时副本，Copy Path 不会把文件另存到永久位置。

## 构建

需要 Xcode 或 Apple Command Line Tools。构建产物同时支持 Apple Silicon 和 Intel，最低 macOS 13。

```sh
git clone https://github.com/zcyoung2000/copy-path.git
cd copy-path
bash scripts/build.sh
bash scripts/test.sh
bash scripts/install.sh
bash scripts/package.sh
# 可选：实测文件打开、剪贴板和转发。会暂时使用并恢复剪贴板和设置。
bash scripts/integration-test.sh "/完整路径/Copy Path.app"
```

产物：`build/Copy Path.app`。本机构建使用 ad-hoc 签名，便于直接在当前 Mac 上运行；如需向其他用户正式分发，应使用 Developer ID 签名并进行公证。

公开下载包尚未进行 Apple 公证，macOS 可能拦截首次打开。查看源码或自行构建确认后，如有需要可使用系统「隐私与安全性 → 仍要打开」。

`install.sh` 默认安装到 `/Applications` 并注册到 macOS，也可以传入完整的目标 `.app` 路径。更新前需关闭正在运行的 Copy Path。

1.0.1 移除了 `LSUIElement` 后台应用声明，改为普通应用，提升第三方“打开方式”菜单的兼容性。文件处理期间仍采用不抢焦点的界面策略，复制完成后自动退出。

若第三方应用在安装前已启动，可能仍使用旧的候选列表。重新打开菜单；仍未更新时，完全退出并重新启动该第三方应用后再查看。系统候选列表和第三方应用实际显示的菜单可能不同。

已验证系统对文本、PDF 和文件夹的候选列表；尚未独立确认微信刷新后的实际菜单。

## 实现

Swift、AppKit、SwiftUI，无第三方依赖。通过应用的文件类型声明接收系统文件打开事件，将路径写入系统剪贴板；可选转发使用 `NSWorkspace`。

GitHub Actions 自动执行路径格式测试、通用应用构建、架构与签名检查，并保存应用压缩包。桌面集成测试说明见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

采用 [MIT 许可证](LICENSE)。应用图标由仓库中的绘图脚本生成，同样适用 MIT 许可证。
