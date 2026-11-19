# Changelog

## 1.0.1

- Declare Copy Path as a regular macOS application rather than a UI agent.
- Install to `/Applications` by default for better third-party discovery.
- Build a universal application for Apple Silicon and Intel Macs.
- Add MIT licensing, public documentation, CI, and packaged checksums.

Third-party applications may cache their Open With lists. The system candidate
list is tested; WeChat's refreshed menu has not been independently verified.

## 1.0.0

- Receive files through macOS Open With or drag and drop.
- Copy plain paths, shell-quoted paths, or file URLs.
- Support multiple files and folders, with stable deduplication.
- Optionally forward files to another selected application after copying.
- Show a brief confirmation without taking focus, then exit automatically.
