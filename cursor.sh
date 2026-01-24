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
    
    # 6. Reload shell configuration
    echo "🔄 Reloading shell configuration..."
    source "$SHELL_RC"
    
    echo "✅ Cursor installed successfully."
    echo "👉 You can run it from terminal with: cursor"
    echo "🎉 It's also available from the application menu."
}

# Update existing installation
update_cursor() {
    echo "🔄 Updating Cursor..."
    
    # Get and download AppImage (replaces existing)
    get_latest_appimage_url
    download_appimage
    
    echo "✅ Cursor updated successfully."
}

# Main logic
if check_installation; then
    echo "📦 Cursor is already installed at $CURSOR_BIN"
    update_cursor
else
    install_cursor
fi
