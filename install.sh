#!/bin/sh
set -eu

# Spellbook installer
# Usage: curl -sSfL https://raw.githubusercontent.com/Nikoro/spellbook/main/install.sh | sh

REPO="Nikoro/spellbook"
VERSION="${SPELLBOOK_VERSION:-latest}"
BASE_URL="${SPELLBOOK_REPO_URL:-https://github.com/$REPO/releases}"

main() {
    detect_platform
    download_binary
    install_binary
    setup_shell
    verify
}

detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    if [ "$OS" != "Darwin" ]; then
        echo "Error: Spellbook currently supports macOS only." >&2
        echo "Detected OS: $OS" >&2
        exit 1
    fi

    case "$ARCH" in
        arm64|aarch64) ARCH="arm64" ;;
        *)
            echo "Error: Spellbook supports Apple Silicon (arm64) only." >&2
            echo "Detected architecture: $ARCH" >&2
            exit 1
            ;;
    esac

    echo "Detected: macOS $ARCH"
}

download_binary() {
    ARTIFACT="spells-macos-$ARCH"

    if [ "$VERSION" = "latest" ]; then
        URL="$BASE_URL/latest/download/$ARTIFACT"
        CHECKSUM_URL="$BASE_URL/latest/download/$ARTIFACT.sha256"
    else
        URL="$BASE_URL/download/v$VERSION/$ARTIFACT"
        CHECKSUM_URL="$BASE_URL/download/v$VERSION/$ARTIFACT.sha256"
    fi

    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT INT TERM

    echo "Downloading $ARTIFACT..."
    curl -sSfL -o "$TMPDIR/spells" "$URL" || {
        echo "Error: Failed to download from $URL" >&2
        exit 1
    }

    echo "Verifying checksum..."
    curl -sSfL -o "$TMPDIR/checksum" "$CHECKSUM_URL" 2>/dev/null && {
        EXPECTED="$(awk '{print $1}' "$TMPDIR/checksum")"
        ACTUAL="$(shasum -a 256 "$TMPDIR/spells" | awk '{print $1}')"
        if [ "$EXPECTED" != "$ACTUAL" ]; then
            echo "Error: Checksum mismatch" >&2
            echo "  Expected: $EXPECTED" >&2
            echo "  Actual:   $ACTUAL" >&2
            exit 1
        fi
        echo "Checksum verified."
    } || echo "Warning: Could not verify checksum (continuing anyway)."

    chmod +x "$TMPDIR/spells"
}

install_binary() {
    INSTALL_DIR="$HOME/.local/bin"

    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
    fi

    cp "$TMPDIR/spells" "$INSTALL_DIR/spells"
    echo "Installed to $INSTALL_DIR/spells"
}

setup_shell() {
    SHELL_NAME="$(basename "$SHELL")"

    case "$SHELL_NAME" in
        zsh)
            RC_FILE="$HOME/.zshrc"
            INTEGRATION_LINE='eval "$(spells init zsh)"'
            ;;
        bash)
            RC_FILE="$HOME/.bashrc"
            INTEGRATION_LINE='eval "$(spells init bash)"'
            ;;
        fish)
            RC_FILE="$HOME/.config/fish/config.fish"
            INTEGRATION_LINE='spells init fish | source'
            ;;
        *)
            echo ""
            echo "Unknown shell: $SHELL_NAME"
            echo "Add ~/.local/bin and ~/.spellbook/bin to your PATH manually."
            return
            ;;
    esac

    # Check if shell integration already exists
    if [ -f "$RC_FILE" ] && grep -q "# spellbook" "$RC_FILE" 2>/dev/null; then
        echo "Shell integration already configured in $RC_FILE."
        return
    fi

    # Check if install dir is in PATH
    PATH_SETUP=""
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *)
            case "$SHELL_NAME" in
                fish) PATH_SETUP='set -gx PATH $HOME/.local/bin $PATH' ;;
                *) PATH_SETUP='export PATH="$HOME/.local/bin:$PATH"' ;;
            esac
            ;;
    esac

    echo ""
    printf "Add shell integration to %s? [Y/n] " "$RC_FILE"

    if [ -t 0 ]; then
        read -r REPLY
    else
        REPLY="y"
    fi

    case "$REPLY" in
        [nN]*)
            echo ""
            echo "Add this to your shell config manually:"
            echo ""
            if [ -n "$PATH_SETUP" ]; then
                echo "  $PATH_SETUP"
            fi
            echo "  # spellbook"
            echo "  $INTEGRATION_LINE"
            ;;
        *)
            {
                echo ""
                if [ -n "$PATH_SETUP" ]; then
                    echo "$PATH_SETUP"
                    echo ""
                fi
                echo "# spellbook"
                echo "$INTEGRATION_LINE"
            } >> "$RC_FILE"
            echo "Added shell integration to $RC_FILE."
            echo "Restart your shell or run: source $RC_FILE"
            ;;
    esac
}

verify() {
    echo ""
    if command -v spells >/dev/null 2>&1; then
        echo "Spellbook $(spells --version) installed successfully."
    elif [ -x "$HOME/.local/bin/spells" ]; then
        echo "Spellbook $("$HOME/.local/bin/spells" --version) installed."
        echo "Restart your shell to use 'spells' directly."
    else
        echo "Installation complete. Restart your shell to get started."
    fi
    echo ""
    echo "Get started:"
    echo "  spells create    # create spells.yaml"
    echo "  spells           # activate wrappers"
}

main
