# 🧠 Cursor Installation Script for Linux

This script install **Cursor** on **Debian Linux** systems or derivated, using the latest version available online.

Cursor is a code editor based on VS Code, optimized with artificial intelligence, ideal for developers who want an enhanced development experience.

---

## 🚀 How It Works

This script automates the following steps:

- ✅ Downloads the latest Cursor `.AppImage` version from the official repository
- ✅ Grants execution permissions
- ✅ Installs it in the `~/.local/bin/` directory
- ✅ Creates a `cursor` command to launch the editor from your terminal without blocking it
- ✅ Creates a desktop shortcut (`.desktop`) to integrate it with the application menu
- ✅ Associates a custom icon

---

## 💡 Prerequisites

- Ubuntu 20.04, 22.04, 24.04 or compatible
- Internet connection
- `curl`, `grep`, `bash`, `chmod` available

---

## 📦 How to Use This Script

1. Clone this repository or download the file

```bash
git clone https://github.com/ezeqd/cursorInstall.git 
cd cursorInstall
```

2. Run the installation script

```bash
chmod +x cursor.sh
./cursor.sh
```

---

## 📥 Version Source

This script **does not use GitHub Releases**, as the Cursor project **does not publish Linux versions there**.

Instead, it uses the JSON file [`version-history.json`](https://github.com/oslook/cursor-ai-downloads/blob/main/version-history.json) from the repository:

🔗 https://github.com/oslook/cursor-ai-downloads

That file maintains an updated history of versions and download links.  
The script takes the **first `.AppImage` link** from that file to install the latest version.

---

## 🚀 How to Run Cursor

### 📌 From the terminal:

```bash
cursor
```

---

## 🧹 How to Uninstall Cursor

To remove Cursor and all the files created by the script, just run the script with the `uninstall` argument:

```bash
./cursor.sh uninstall
```
