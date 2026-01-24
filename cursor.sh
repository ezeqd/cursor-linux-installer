#!/bin/bash

set -e

# Variables
CURSOR_DIR="$HOME/.local/bin"
CURSOR_BIN="$CURSOR_DIR/cursor"
VERSION_FILE="$CURSOR_DIR/.cursor-version"
DESKTOP_FILE="$HOME/.local/share/applications/cursor.desktop"
ICON_TARGET="$HOME/.local/share/icons/cursor.png"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SOURCE="$SCRIPT_DIR/cursor.png"
VERSION_JSON="https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/version-history.json"

# Check if Cursor is already installed
check_installation() {
    if [ -f "$CURSOR_BIN" ]; then
        return 0  # Installed
    else
        return 1  # Not installed
    fi
}

# Check if Cursor is currently running
is_cursor_running() {
    if pgrep -f "$CURSOR_BIN" > /dev/null 2>&1; then
        return 0  # Running
    else
        return 1  # Not running
    fi
}

# Get installation status text
get_status_text() {
    if check_installation; then
        local version
        version=$(get_installed_version)
        if [[ "$version" == "unknown" ]]; then
            echo "Installed (version unknown)"
        else
            echo "Installed (v$version)"
        fi
    else
        echo "Not installed"
    fi
}

# Get installed version (from version file)
get_installed_version() {
    if check_installation; then
        if [ -f "$VERSION_FILE" ]; then
            cat "$VERSION_FILE"
        else
            echo "unknown"
        fi
    else
        echo "not installed"
    fi
}

# Get the latest AppImage URL and extract version
get_latest_appimage_url() {
    echo "🔍 Fetching version-history.json..."
    APPIMAGE_URL=$(curl -s "$VERSION_JSON" | grep -oP 'https.*?Cursor-.*?\.AppImage' | head -n 1)
    
    if [[ -z "$APPIMAGE_URL" ]]; then
        echo "❌ Could not get AppImage file from version-history.json. Aborting."
        exit 1
    fi
    
    # Extract version from URL (format: Cursor-X.X.X.AppImage)
    LATEST_VERSION=$(echo "$APPIMAGE_URL" | grep -oP 'Cursor-\K\d+\.\d+\.\d+')
}

# Download and install the AppImage
download_appimage() {
    echo "📥 Downloading AppImage:"
    echo "$APPIMAGE_URL"
    curl -L "$APPIMAGE_URL" -o "$CURSOR_BIN"
    chmod +x "$CURSOR_BIN"
    
    # Save version to file for future reference
    echo "$LATEST_VERSION" > "$VERSION_FILE"
}

# Full installation (new install)
install_cursor() {
    # Check if already installed
    if check_installation; then
        echo ""
        read -p "⚠️ Cursor is already installed. Reinstall? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            return
        fi
        
        # Check if Cursor is running before reinstalling
        if is_cursor_running; then
            echo ""
            echo "❌ Cursor is currently running."
            echo "   Please close Cursor before reinstalling."
            return
        fi
    fi

    echo ""
    echo "🚀 Installing Cursor for Linux (.AppImage)..."
    
    # 1. Create necessary directories
    mkdir -p "$CURSOR_DIR" "$HOME/.local/share/icons" "$HOME/.local/share/applications"
    
    # 2. Get and download AppImage
    get_latest_appimage_url
    download_appimage
    
    # 3. Copy icon if exists
    if [ -f "$ICON_SOURCE" ]; then
        echo "🎨 Copying icon from $ICON_SOURCE"
        cp "$ICON_SOURCE" "$ICON_TARGET"
        ICON_PATH="$ICON_TARGET"
    else
        echo "⚠️ cursor.png not found next to the script. Icon will not be set."
        ICON_PATH=""
    fi
    
    # 4. Create .desktop file
    echo "🧩 Creating .desktop file at $DESKTOP_FILE"
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Cursor
Exec=$CURSOR_BIN --no-sandbox
Icon=$ICON_PATH
Type=Application
Categories=Development;IDE;
Terminal=false
EOF
    
    # 5. Create alias
    SHELL_RC="$HOME/.bashrc"
    if [[ "$SHELL" =~ "zsh" ]]; then
        SHELL_RC="$HOME/.zshrc"
    fi
    
    if ! grep -q "alias cursor=" "$SHELL_RC"; then
        echo "🔗 Adding alias to $SHELL_RC"
        echo "alias cursor=\"$CURSOR_BIN --no-sandbox\"" >> "$SHELL_RC"
    else
        echo "✔️ Alias already exists in $SHELL_RC"
    fi
    
    echo ""
    echo "✅ Cursor installed successfully."
    echo "👉 You can run it from terminal with: cursor"
    echo "🎉 It's also available from the application menu."
    echo ""
    echo "💡 Run 'source $SHELL_RC' or restart your terminal to use the alias."
}

# Update existing installation
update_cursor() {
    if ! check_installation; then
        echo ""
        echo "❌ Cursor is not installed. Please install it first."
        return 1
    fi

    # Check if Cursor is running
    if is_cursor_running; then
        echo ""
        echo "❌ Cursor is currently running."
        echo "   Please close Cursor before updating."
        echo ""
        echo "   Tip: Save your work and close all Cursor windows,"
        echo "   then try again."
        return 1
    fi

    echo ""
    echo "🔄 Checking for updates..."
    
    # Get installed version
    local installed_version
    installed_version=$(get_installed_version)
    
    if [[ "$installed_version" == "unknown" ]]; then
        echo "📦 Installed version: unknown (installed before version tracking)"
    else
        echo "📦 Installed version: $installed_version"
    fi
    
    # Get latest version available
    get_latest_appimage_url
    echo "🌐 Latest version: $LATEST_VERSION"
    
    # Compare versions (if unknown, always update)
    if [[ "$installed_version" == "$LATEST_VERSION" ]]; then
        echo ""
        echo "✅ You already have the latest version installed."
        return 1
    fi
    
    # If version is unknown, ask for confirmation
    if [[ "$installed_version" == "unknown" ]]; then
        echo ""
        read -p "⚠️ Cannot determine current version. Update anyway? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Update cancelled."
            return 1
        fi
    fi
    
    echo ""
    echo "📥 Downloading new version..."
    download_appimage
    
    echo ""
    if [[ "$installed_version" == "unknown" ]]; then
        echo "✅ Cursor updated successfully to v$LATEST_VERSION"
    else
        echo "✅ Cursor updated successfully: $installed_version → $LATEST_VERSION"
    fi
    return 0
}

# Uninstall Cursor
uninstall_cursor() {
    if ! check_installation; then
        echo ""
        echo "❌ Cursor is not installed. Nothing to uninstall."
        return
    fi

    echo ""
    read -p "⚠️ Are you sure you want to uninstall Cursor? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        return
    fi

    echo ""
    echo "🗑️ Uninstalling Cursor..."

    # Remove binary
    if [ -f "$CURSOR_BIN" ]; then
        rm -f "$CURSOR_BIN"
        echo "   Removed $CURSOR_BIN"
    fi

    # Remove version file
    if [ -f "$VERSION_FILE" ]; then
        rm -f "$VERSION_FILE"
        echo "   Removed $VERSION_FILE"
    fi

    # Remove desktop file
    if [ -f "$DESKTOP_FILE" ]; then
        rm -f "$DESKTOP_FILE"
        echo "   Removed $DESKTOP_FILE"
    fi

    # Remove icon
    if [ -f "$ICON_TARGET" ]; then
        rm -f "$ICON_TARGET"
        echo "   Removed $ICON_TARGET"
    fi

    # Remove alias from .bashrc
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/alias cursor=/d' "$HOME/.bashrc" 2>/dev/null
        echo "   Removed alias from .bashrc"
    fi

    # Remove alias from .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        sed -i '/alias cursor=/d' "$HOME/.zshrc" 2>/dev/null
        echo "   Removed alias from .zshrc"
    fi

    echo ""
    echo "✅ Cursor uninstalled successfully."
    echo "💡 Restart your terminal to apply changes."
}

# Show interactive menu
show_menu() {
    while true; do
        clear
        echo "========================================"
        echo "     Cursor Installer for Linux"
        echo "========================================"
        echo ""
        echo "Current status: $(get_status_text)"
        echo ""
        echo "1) Install Cursor"
        echo "2) Update Cursor"
        echo "3) Uninstall Cursor"
        echo "4) Exit"
        echo ""
        read -p "Select an option [1-4]: " choice

        case $choice in
            1)
                install_cursor
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                if update_cursor; then
                    echo ""
                    echo "👋 Goodbye!"
                    exit 0
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                uninstall_cursor
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo ""
                echo "❌ Invalid option. Please select 1-4."
                sleep 2
                ;;
        esac
    done
}

# Main entry point
show_menu
