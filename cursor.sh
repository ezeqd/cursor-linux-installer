#!/bin/bash

set -e

# Variables
CURSOR_DIR="$HOME/.local/bin"
CURSOR_BIN="$CURSOR_DIR/cursor"
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

# Get installation status text
get_status_text() {
    if check_installation; then
        echo "Installed"
    else
        echo "Not installed"
    fi
}

# Get the latest AppImage URL
get_latest_appimage_url() {
    echo "🔍 Fetching version-history.json..."
    APPIMAGE_URL=$(curl -s "$VERSION_JSON" | grep -oP 'https.*?Cursor-.*?\.AppImage' | head -n 1)
    
    if [[ -z "$APPIMAGE_URL" ]]; then
        echo "❌ Could not get AppImage file from version-history.json. Aborting."
        exit 1
    fi
}

# Download and install the AppImage
download_appimage() {
    echo "📥 Downloading AppImage:"
    echo "$APPIMAGE_URL"
    curl -L "$APPIMAGE_URL" -o "$CURSOR_BIN"
    chmod +x "$CURSOR_BIN"
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
        return
    fi

    echo ""
    echo "🔄 Updating Cursor..."
    
    # Get and download AppImage (replaces existing)
    get_latest_appimage_url
    download_appimage
    
    echo ""
    echo "✅ Cursor updated successfully."
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
                update_cursor
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
