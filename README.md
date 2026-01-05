# pvm - Python Version Manager

[English](#english) | [中文](#中文)

---

## English

**pvm** is a simple, cross-platform Python version manager inspired by [nvm](https://github.com/nvm-sh/nvm). It allows you to easily install, switch between, and manage multiple Python versions on your system.

### Features

- Install multiple Python versions side by side
- Switch between Python versions with a single command
- Uninstall Python versions you no longer need
- Windows support (PowerShell/CMD)
- Linux/macOS support (Bash)
- Mirror support for faster downloads in China

### Installation

#### Windows (PowerShell)

```powershell
# Run in PowerShell as Administrator
irm https://pvm.violetteam.cloud/install.ps1 | iex
```

Or manually:

```powershell
git clone https://github.com/violettoolssite/pym.git
cd pym
.\install.ps1
```

#### Windows (CMD)

After installation, you can use `pvm` command directly in CMD:

```cmd
pvm --help
pvm list available
pvm install 3.12.4
```

#### Linux/macOS

```bash
curl -fsSL https://pvm.violetteam.cloud/install.sh | bash
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

Use the `config` command to quickly configure mirrors:

```bash
# Use Tsinghua mirror (recommended for China)
pvm config tsinghua

# Use Huawei Cloud mirror
pvm config huawei

# Use Aliyun mirror
pvm config aliyun

# Use npmmirror
pvm config npmmirror

# Use official python.org
pvm config default

# Show current config
pvm config
```

Available presets:
- `tsinghua` / `qinghua` - Tsinghua University
- `huawei` - Huawei Cloud
- `aliyun` - Aliyun
- `npmmirror` - npmmirror
- `default` - python.org (Official)

### License

Apache License 2.0 - see [LICENSE](LICENSE)

---

## 中文

**pvm** 是一个简单的跨平台 Python 版本管理工具，灵感来自 [nvm](https://github.com/nvm-sh/nvm)。它可以让你轻松安装、切换和管理系统上的多个 Python 版本。

### 特性

- 并行安装多个 Python 版本
- 一条命令切换 Python 版本
- 卸载不再需要的 Python 版本
- 支持 Windows (PowerShell/CMD)
- 支持 Linux/macOS (Bash)
- 支持国内镜像加速下载

### 安装

#### Windows (PowerShell)

```powershell
# 以管理员身份在 PowerShell 中运行
irm https://pvm.violetteam.cloud/install.ps1 | iex
```

或手动安装：

```powershell
git clone https://github.com/violettoolssite/pym.git
cd pym
.\install.ps1
```

#### Windows (CMD)

安装完成后，可以直接在 CMD 中使用 `pvm` 命令：

```cmd
pvm --help
pvm list available
pvm install 3.12.4
```

#### Linux/macOS

```bash
curl -fsSL https://pvm.violetteam.cloud/install.sh | bash
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

pvm 将数据存储在 `~/.pvm` (Unix) 或 `%USERPROFILE%\.pvm` (Windows)：

```
.pvm/
├── versions/      # 已安装的 Python 版本
├── current        # 当前激活的版本
└── settings.json  # 配置文件（镜像源等）
```

#### 镜像配置

使用 `config` 命令快速配置镜像源：

```bash
# 使用清华源（推荐）
pvm config tsinghua

# 使用华为云镜像
pvm config huawei

# 使用阿里云镜像
pvm config aliyun

# 使用 npmmirror
pvm config npmmirror

# 使用官方源
pvm config default

# 查看当前配置
pvm config
```

可用预设：
- `tsinghua` / `qinghua` - 清华大学
- `huawei` - 华为云
- `aliyun` - 阿里云
- `npmmirror` - npmmirror
- `default` - python.org（官方）

### 许可证

Apache License 2.0 - 详见 [LICENSE](LICENSE)
