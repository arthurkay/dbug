#!/usr/bin/env bash
set -euo pipefail

# ─── dbug installer & updater ───────────────────────────────────────────────
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/arthurkay/dbug/main/install.sh | bash
#   ./install.sh                  # install or update to latest
#   ./install.sh --version 0.0.1  # install a specific version
#   ./install.sh --uninstall      # remove dbug from system
#   ./install.sh --check          # check if an update is available
#   ./install.sh --force          # reinstall even if up-to-date
#   ./install.sh --help           # show usage
# ─────────────────────────────────────────────────────────────────────────────

REPO="arthurkay/dbug"
APP_NAME="dbug"
GITHUB_API="https://api.github.com/repos/${REPO}/releases"

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

info()  { printf "${BLUE}▸${RESET} %s\n" "$*"; }
ok()    { printf "${GREEN}✔${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}⚠${RESET} %s\n" "$*"; }
err()   { printf "${RED}✖${RESET} %s\n" "$*" >&2; exit 1; }

# Removes the download/staging dir however the script exits.
TMP_DIR=""
trap 'rm -rf "${TMP_DIR:-}"' EXIT

# ─── Parse arguments ────────────────────────────────────────────────────────
VERSION=""
ACTION="install"
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || err "--version requires a value (e.g. --version 0.1.6)"
            VERSION="${2#v}"; shift 2 ;;
        --uninstall) ACTION="uninstall"; shift ;;
        --check)     ACTION="check"; shift ;;
        --force)     FORCE=true; shift ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --version VER   Install a specific version (e.g. 0.0.1)"
            echo "  --uninstall     Remove dbug from this system"
            echo "  --check         Check if an update is available"
            echo "  --force         Reinstall even if already up-to-date"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *) err "Unknown option: $1. Use --help for usage." ;;
    esac
done

# ─── Platform detection ──────────────────────────────────────────────────────
detect_platform() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"

    case "$os" in
        Linux*)  PLATFORM="linux" ;;
        Darwin*) PLATFORM="macos" ;;
        MINGW*|MSYS*|CYGWIN*)
            err "Windows detected. Download the installer or .zip from https://github.com/${REPO}/releases"
            ;;
        *) err "Unsupported OS: $os" ;;
    esac

    case "$arch" in
        x86_64|amd64) ARCH="x64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        *) err "Unsupported architecture: $arch" ;;
    esac

    if [[ "$PLATFORM" == "linux" ]]; then
        # Fail before any network calls rather than after a fruitless lookup.
        [[ "$ARCH" == "x64" ]] || err "Linux ${ARCH} builds are not published yet. Build from source: https://github.com/${REPO}"
        ARCHIVE_NAME="${APP_NAME}-linux-${ARCH}.tar.gz"
    else
        # macOS releases ship a single universal bundle (no arch suffix).
        ARCHIVE_NAME="${APP_NAME}-macos.zip"
    fi
}

# ─── Dependency checks ───────────────────────────────────────────────────────
check_deps() {
    local missing=()
    for cmd in curl tar; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ "$PLATFORM" == "macos" ]]; then
        command -v unzip &>/dev/null || missing+=("unzip")
        command -v shasum &>/dev/null || missing+=("shasum")
    else
        command -v sha256sum &>/dev/null || missing+=("sha256sum")
    fi
    if [[ ${#missing[@]} -gt 0 ]]; then
        err "Missing required commands: ${missing[*]}"
    fi
}

# ─── GitHub API helpers ──────────────────────────────────────────────────────
github_curl() {
    local url="$1"
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        curl -fsSL -H "Authorization: token ${GITHUB_TOKEN}" "$url"
    else
        curl -fsSL "$url"
    fi
}

# Fetch JSON from GitHub API with fallback
github_fetch() {
    local url="$1"
    local output
    if output=$(github_curl "$url" 2>/dev/null); then
        echo "$output"
        return 0
    fi
    return 1
}

# Parse tag_name from release JSON
# ([[:space:]] instead of \s — BSD sed/grep on macOS don't support \s)
parse_version() {
    grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name":[[:space:]]*"v?([^"]+)".*/\1/'
}

# Parse browser_download_url for a given asset name
parse_download_url() {
    local json="$1" asset="$2"
    echo "$json" | grep -oE "\"browser_download_url\":[[:space:]]*\"[^\"]*${asset}[^\"]*\"" \
        | head -1 | sed -E 's/.*"browser_download_url":[[:space:]]*"([^"]+)".*/\1/'
}

# ─── Version management ─────────────────────────────────────────────────────
VERSION_FILE=""
get_install_dir() {
    case "$PLATFORM" in
        linux)
            INSTALL_DIR="${HOME}/.local/share/${APP_NAME}"
            VERSION_FILE="${INSTALL_DIR}/.version"
            BIN_DIR="${HOME}/.local/bin"
            ;;
        macos)
            # An existing install wherever it lives wins; otherwise prefer
            # /Applications and fall back to ~/Applications without admin rights.
            if [[ -d "${HOME}/Applications/${APP_NAME}.app" && ! -d "/Applications/${APP_NAME}.app" ]]; then
                INSTALL_DIR="${HOME}/Applications/${APP_NAME}.app"
            elif [[ -w "/Applications" ]]; then
                INSTALL_DIR="/Applications/${APP_NAME}.app"
            else
                INSTALL_DIR="${HOME}/Applications/${APP_NAME}.app"
            fi
            VERSION_FILE="${HOME}/.local/share/${APP_NAME}/.version"
            ;;
    esac
    mkdir -p "$(dirname "$VERSION_FILE")"
}

get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Prints -1, 0 or 1 as $1 is older than, equal to or newer than $2.
compare_versions() {
    if [[ "$1" == "$2" ]]; then echo 0; return; fi
    local lowest
    lowest=$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)
    if [[ "$lowest" == "$1" ]]; then echo -1; else echo 1; fi
}

get_latest_version() {
    local json
    json=$(github_fetch "${GITHUB_API}/latest") || \
    json=$(github_fetch "${GITHUB_API}") || \
    err "Failed to fetch releases from GitHub. Check your network connection."
    parse_version <<< "$json"
}

get_release_json() {
    local ver="$1"
    local json=""
    json=$(github_fetch "${GITHUB_API}/tags/v${ver}") || \
    json=$(github_fetch "${GITHUB_API}/tags/${ver}") || \
    err "Version v${ver} not found on GitHub."
    echo "$json"
}

# ─── Download & extract ──────────────────────────────────────────────────────
download_release() {
    local version="$1"
    TMP_DIR=$(mktemp -d)

    info "Fetching release info for v${version}..."
    local release_json
    release_json=$(get_release_json "$version")

    local download_url
    download_url=$(parse_download_url "$release_json" "$ARCHIVE_NAME")
    [[ -z "$download_url" ]] && err "Could not find asset '${ARCHIVE_NAME}' in release."

    info "Downloading ${ARCHIVE_NAME}..."
    curl -fSL -o "${TMP_DIR}/${ARCHIVE_NAME}" "$download_url" || err "Download failed."

    verify_checksum "$release_json"
}

# Verifies the archive against the release's SHA256SUMS. Releases published
# before checksums existed have no sums file; those only get a warning.
verify_checksum() {
    local release_json="$1"
    local sums_url
    sums_url=$(parse_download_url "$release_json" "SHA256SUMS")
    if [[ -z "$sums_url" ]]; then
        warn "This release has no SHA256SUMS; skipping checksum verification."
        return 0
    fi

    curl -fsSL -o "${TMP_DIR}/SHA256SUMS" "$sums_url" || err "Failed to download SHA256SUMS."

    local expected
    expected=$(awk -v f="$ARCHIVE_NAME" '$2 == f || $2 == "*" f { print $1; exit }' "${TMP_DIR}/SHA256SUMS")
    [[ -n "$expected" ]] || err "SHA256SUMS has no entry for ${ARCHIVE_NAME}; refusing to install."

    local actual
    if [[ "$PLATFORM" == "macos" ]]; then
        actual=$(shasum -a 256 "${TMP_DIR}/${ARCHIVE_NAME}" | awk '{ print $1 }')
    else
        actual=$(sha256sum "${TMP_DIR}/${ARCHIVE_NAME}" | awk '{ print $1 }')
    fi
    [[ "$actual" == "$expected" ]] || err "Checksum mismatch for ${ARCHIVE_NAME} (expected ${expected}, got ${actual}). Refusing to install."
    ok "Checksum verified."
}

extract_archive() {
    local archive_dir="$1"
    local archive_path="${archive_dir}/${ARCHIVE_NAME}"
    local dest="$2"

    mkdir -p "$dest"

    info "Extracting to ${dest}..."
    case "$ARCHIVE_NAME" in
        *.tar.gz) tar -xzf "$archive_path" -C "$dest" ;;
        *.zip)    unzip -oq "$archive_path" -d "$dest" ;;
    esac
}

# ─── Linux install ───────────────────────────────────────────────────────────
install_linux() {
    local dest="$1" version="$2"

    # Extract into a staging dir and swap it in, so files dropped from a newer
    # release don't linger next to the new ones.
    local staging="${TMP_DIR}/bundle"
    extract_archive "$TMP_DIR" "$staging"
    [[ -x "${staging}/${APP_NAME}" || -f "${staging}/${APP_NAME}" ]] || err "Archive does not contain the ${APP_NAME} binary."
    chmod +x "${staging}/${APP_NAME}"

    info "Installing to ${dest}..."
    mkdir -p "$(dirname "$dest")"
    # Never delete user data with the old bundle: path_provider used to fall
    # back to ~/.local/share/dbug (this install dir) for app data.
    if compgen -G "${dest}/*.db*" > /dev/null; then
        local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zm.co.cloud.dbug" f
        mkdir -p "$data_dir"
        for f in "${dest}"/*.db*; do
            if [[ -e "${data_dir}/$(basename "$f")" ]]; then
                cp -a "$f" "${data_dir}/$(basename "$f").from-install-dir"
            else
                cp -a "$f" "${data_dir}/"
            fi
        done
        warn "Preserved database files from ${dest} in ${data_dir}"
    fi
    rm -rf "$dest"
    mv "$staging" "$dest"

    # Create symlink in ~/.local/bin
    mkdir -p "$BIN_DIR"
    ln -sfn "${dest}/${APP_NAME}" "${BIN_DIR}/${APP_NAME}"

    # Install desktop entry if present in bundle
    local desktop_src="${dest}/data/zm.co.cloud.dbug.desktop"
    if [[ -f "$desktop_src" ]]; then
        local desktop_dir="${HOME}/.local/share/applications"
        mkdir -p "$desktop_dir"
        # Absolute Exec path: the app menu must not depend on ~/.local/bin
        # being on the desktop session's PATH.
        sed -e "s|^Exec=.*|Exec=${dest}/${APP_NAME}|" "$desktop_src" > "${desktop_dir}/zm.co.cloud.dbug.desktop"
        ok "Desktop entry installed."
    fi

    # Install icons if present in bundle
    local icons_src="${dest}/data/icons"
    if [[ -d "$icons_src" ]]; then
        local icons_dest="${HOME}/.local/share/icons"
        mkdir -p "$icons_dest"
        cp -r "${icons_src}/"* "${icons_dest}/" 2>/dev/null || true
        ok "Icons installed."
    fi

    # Check if ~/.local/bin is in PATH
    case ":${PATH}:" in
        *":${BIN_DIR}:"*) ;;
        *)
            warn "${BIN_DIR} is not in your PATH."
            warn "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
            warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
            ;;
    esac

    # Save version
    echo "$version" > "$VERSION_FILE"
}

# ─── macOS install ───────────────────────────────────────────────────────────
install_macos() {
    local dest="$1" version="$2"

    # Extract and verify before touching the existing install, so a failure
    # never leaves the user without an app.
    local staging="${TMP_DIR}/bundle"
    extract_archive "$TMP_DIR" "$staging"
    local app
    app=$(find "$staging" -maxdepth 2 -name "${APP_NAME}.app" -type d | head -1)
    [[ -n "$app" ]] || err "Archive does not contain ${APP_NAME}.app."

    info "Installing to ${dest}..."
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    mv "$app" "$dest"
    ok "Installed to ${dest}"

    # Save version
    mkdir -p "$(dirname "$VERSION_FILE")"
    echo "$version" > "$VERSION_FILE"

    echo ""
    warn "On first launch, macOS may block the app."
    warn "Right-click the app in Finder > Open > Open to bypass Gatekeeper."
}

# ─── Uninstall ───────────────────────────────────────────────────────────────
uninstall() {
    info "Uninstalling ${APP_NAME}..."

    case "$PLATFORM" in
        linux)
            rm -rf "$HOME/.local/share/${APP_NAME}"
            rm -f "$HOME/.local/bin/${APP_NAME}"
            info "Your collections and history were kept in ${XDG_DATA_HOME:-$HOME/.local/share}/zm.co.cloud.dbug (delete it to remove all dbug data)."
            rm -f "$HOME/.local/share/applications/zm.co.cloud.dbug.desktop"
            find "$HOME/.local/share/icons/hicolor" -name "dbug*" -delete 2>/dev/null || true
            ok "Removed ${APP_NAME} from ~/.local/share/${APP_NAME}"
            ok "Removed symlink from ~/.local/bin/${APP_NAME}"
            ok "Removed desktop entry and icons."
            ;;
        macos)
            if [[ -d "$INSTALL_DIR" ]]; then
                rm -rf "$INSTALL_DIR"
                ok "Removed ${INSTALL_DIR}"
            fi
            rm -f "$VERSION_FILE"
            ;;
    esac

    ok "Uninstall complete."
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
    detect_platform
    check_deps
    get_install_dir

    local current_version
    current_version=$(get_current_version)

    # ── Uninstall ──
    if [[ "$ACTION" == "uninstall" ]]; then
        uninstall
        exit 0
    fi

    # ── Get target version ──
    local target_version="$VERSION"
    if [[ -z "$target_version" ]]; then
        target_version=$(get_latest_version) || err "Could not determine latest version."
    fi

    # ── Check only ──
    if [[ "$ACTION" == "check" ]]; then
        if [[ -z "$current_version" ]]; then
            info "${APP_NAME} is not installed."
        else
            case "$(compare_versions "$current_version" "$target_version")" in
                0)  ok "${APP_NAME} is up-to-date (v${current_version})." ;;
                -1) warn "Update available: v${current_version} -> v${target_version}" ;;
                1)  ok "${APP_NAME} v${current_version} is newer than v${target_version}." ;;
            esac
        fi
        exit 0
    fi

    # ── Skip if up-to-date ──
    if [[ "$FORCE" != true && -n "$current_version" && "$current_version" == "$target_version" ]]; then
        ok "${APP_NAME} v${current_version} is already installed. Use --force to reinstall."
        exit 0
    fi

    # ── Install ──
    if [[ -n "$current_version" ]]; then
        if [[ "$(compare_versions "$current_version" "$target_version")" == 1 ]]; then
            info "Downgrading ${APP_NAME} v${current_version} -> v${target_version}..."
        else
            info "Updating ${APP_NAME} v${current_version} -> v${target_version}..."
        fi
    else
        info "Installing ${APP_NAME} v${target_version}..."
    fi

    download_release "$target_version"

    case "$PLATFORM" in
        linux)  install_linux "$INSTALL_DIR" "$target_version" ;;
        macos)  install_macos "$INSTALL_DIR" "$target_version" ;;
    esac

    echo ""
    ok "${APP_NAME} v${target_version} installed successfully!"
    echo ""
    case "$PLATFORM" in
        linux)
            info "Run with:  ${BIN_DIR}/${APP_NAME}"
            info "Or search  'dbug' in your application menu."
            ;;
        macos)
            info "Open ${INSTALL_DIR} from Finder or Spotlight."
            ;;
    esac
}

main "$@"
