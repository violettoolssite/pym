# pvm - Python Version Manager

[English](#english) | [中文](#中文)

---

## English

**pvm** is a simple, cross-platform Python version manager inspired by [nvm](https://github.com/nvm-sh/nvm). It allows you to easily install, switch between, and manage multiple Python versions on your system.

### Features

- 📦 Install multiple Python versions side by side
- 🔄 Switch between Python versions with a single command
- 🗑️ Uninstall Python versions you no longer need
- 🪟 Windows support (PowerShell/Batch)
- 🐧 Linux/macOS support (Bash)
- 🌏 Mirror support for faster downloads in China

### Installation

#### Windows (PowerShell)

```powershell
# Run in PowerShell as Administrator
irm https://raw.githubusercontent.com/violettoolssite/pym/main/install.ps1 | iex
```

Or manually:

```powershell
git clone https://github.com/violettoolssite/pym.git
cd pym
.\install.ps1
```

#### Linux/macOS

```bash
curl -o- https://raw.githubusercontent.com/violettoolssite/pym/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/violettoolssite/pym.git
cd pym
./install.sh
```

### Usage

```bash
# List installed Python versions
pvm list

# List available Python versions for download
pvm list available

# Install a specific Python version
pvm install 3.12.4

# Use a specific Python version
pvm use 3.12.4

# Show currently active Python version
pvm current

# Uninstall a Python version
pvm uninstall 3.11.9

# Show help
pvm --help
```

### Configuration

pvm stores its data in `~/.pvm` (Unix) or `%USERPROFILE%\.pvm` (Windows):

```
.pvm/
├── versions/      # Installed Python versions
├── current        # Currently active version
└── settings.json  # Configuration (mirrors, etc.)
```

#### Mirror Configuration

Edit `settings.json` to use a mirror:

```json
{
  "mirror": "https://mirrors.huaweicloud.com/python"
}
```

Available mirrors:
- Default: `https://www.python.org/ftp/python`
- Huawei Cloud: `https://mirrors.huaweicloud.com/python`
- npmmirror: `https://registry.npmmirror.com/-/binary/python`

### License

Apache License 2.0 - see [LICENSE](LICENSE)

---

## 中文

**pvm** 是一个简单的跨平台 Python 版本管理工具，灵感来自 [nvm](https://github.com/nvm-sh/nvm)。它可以让你轻松安装、切换和管理系统上的多个 Python 版本。

### 特性

- 📦 并行安装多个 Python 版本
- 🔄 一条命令切换 Python 版本
- 🗑️ 卸载不再需要的 Python 版本
- 🪟 支持 Windows（PowerShell/Batch）
- 🐧 支持 Linux/macOS（Bash）
- 🌏 支持国内镜像加速下载

### 安装

#### Windows (PowerShell)

```powershell
# 以管理员身份在 PowerShell 中运行
irm https://raw.githubusercontent.com/violettoolssite/pym/main/install.ps1 | iex
```

或手动安装：

```powershell
git clone https://github.com/violettoolssite/pym.git
cd pym
.\install.ps1
```

#### Linux/macOS

```bash
curl -o- https://raw.githubusercontent.com/violettoolssite/pym/main/install.sh | bash
```

或手动安装：

```bash
git clone https://github.com/violettoolssite/pym.git
cd pym
./install.sh
```

### 使用方法

```bash
# 列出已安装的 Python 版本
pvm list

# 列出可下载的 Python 版本
pvm list available

# 安装指定版本的 Python
pvm install 3.12.4

# 切换到指定版本
pvm use 3.12.4

# 显示当前使用的版本
pvm current

# 卸载指定版本
pvm uninstall 3.11.9

# 显示帮助
pvm --help
```

### 配置

pvm 将数据存储在 `~/.pvm`（Unix）或 `%USERPROFILE%\.pvm`（Windows）：

```
.pvm/
├── versions/      # 已安装的 Python 版本
├── current        # 当前激活的版本
└── settings.json  # 配置文件（镜像源等）
```

#### 镜像配置

编辑 `settings.json` 使用镜像源：

```json
{
  "mirror": "https://mirrors.huaweicloud.com/python"
}
```

可用镜像：
- 默认：`https://www.python.org/ftp/python`
- 华为云：`https://mirrors.huaweicloud.com/python`
- npmmirror：`https://registry.npmmirror.com/-/binary/python`

### 许可证

Apache License 2.0 - 详见 [LICENSE](LICENSE)

