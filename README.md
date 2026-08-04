# dbug

A local API testing tool like Postman, built with Flutter.

## Features

- **Request Builder** -- Send HTTP requests (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS) with headers, query parameters, body (JSON, form data, raw), and authentication (Bearer, Basic, API Key).
- **Collections** -- Organize requests into collections, import/export as JSON files.
- **History** -- Automatic logging of all sent requests with response details.
- **OpenAPI Specs** -- Import OpenAPI/Swagger specs from files or URLs, browse endpoints, and generate requests from them.
- **Environments** -- Define environment variables and switch between environments. Use `{{variable}}` syntax in URLs, headers, and body.
- **Mock Server** -- Built-in mock server (port 3001) for defining custom endpoints with fixed or variable-based responses.
- **Settings** -- Light/dark theme toggle, environment management.

## Installation

### Quick Install (Linux & macOS)

**One-line install from GitHub:**

```bash
curl -fsSL https://raw.githubusercontent.com/arthurkay/dbug/main/install.sh | bash
```

This downloads and executes the install script directly — no clone needed. You can pass options through `bash -s`:

```bash
# Install a specific version
curl -fsSL https://raw.githubusercontent.com/arthurkay/dbug/main/install.sh | bash -s -- --version 0.0.1

# Check for updates without installing
curl -fsSL https://raw.githubusercontent.com/arthurkay/dbug/main/install.sh | bash -s -- --check

# Force reinstall
curl -fsSL https://raw.githubusercontent.com/arthurkay/dbug/main/install.sh | bash -s -- --force

# Uninstall
curl -fsSL https://raw.githubusercontent.com/arthurkay/dbug/main/install.sh | bash -s -- --uninstall
```

**Or clone and run locally:**

```bash
git clone https://github.com/arthurkay/dbug.git
cd dbug
./install.sh
```

**What the script does:**
- Detects your platform (Linux x64 / macOS ARM64) and downloads the correct binary
- Installs to `~/.local/share/dbug/` (Linux) or `/Applications/dbug.app` (macOS)
- Creates a symlink at `~/.local/bin/dbug` (Linux)
- Installs the desktop entry and icons for app menu integration (Linux)
- Tracks installed version in `~/.local/share/dbug/.version` for upgrade detection

**Script Options:**

| Command | Description |
|---------|-------------|
| `./install.sh` | Install or update to the latest version |
| `./install.sh --version 0.0.1` | Install a specific version |
| `./install.sh --check` | Check if an update is available |
| `./install.sh --force` | Reinstall even if already up-to-date |
| `./install.sh --uninstall` | Remove dbug from the system |
| `./install.sh --help` | Show all options |

**Upgrade behavior:** Running the script again when already up-to-date will skip the download. When a new version is released, run `./install.sh` again — it will detect the new version and replace the existing installation automatically.

### Download Pre-built Binaries

Go to the [Releases](https://github.com/arthurkay/dbug/releases) page and download the archive for your platform:

| Platform | Archive | Notes |
|----------|---------|-------|
| **Linux x64** | `dbug-linux-x64.tar.gz` | Extract and run the `dbug` binary |
| **macOS (Universal)** | `dbug-macos.zip` | Unzip and drag `dbug.app` to `/Applications` |
| **Windows x64** | `dbug-windows-x64.zip` | Extract and run `dbug.exe` |

### Linux

```bash
# Download and extract
tar -xzf dbug-linux-x64.tar.gz -C ~/.local/share/dbug

# Run
~/.local/share/dbug/dbug
```

To add a desktop entry, copy the `.desktop` file from the release archive and the icons to the appropriate XDG directories:

```bash
cp zm.co.cloud.dbug.desktop ~/.local/share/applications/
cp -r icons/* ~/.local/share/icons/hicolor/
```

### macOS

1. Unzip `dbug-macos.zip`
2. Drag `dbug.app` to your Applications folder
3. On first launch, right-click > Open to bypass Gatekeeper

### Windows

1. Extract `dbug-windows-x64.zip`
2. Run `dbug.exe`

### Build from Source

Requires [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+).

```bash
# Clone the repository
git clone https://github.com/arthurkay/dbug.git
cd dbug

# Install dependencies
flutter pub get

# Run in debug mode
flutter run -d linux    # or -d macos, -d windows

# Build release
flutter build linux --release    # or macos, windows
```

The release build output is in `build/<platform>/...`:
- Linux: `build/linux/x64/release/bundle/`
- macOS: `build/macos/Build/Products/Release/`
- Windows: `build/windows/x64/runner/Release/`

### Uninstallation

```bash
# Using the install script (recommended)
./install.sh --uninstall
```

Or remove manually:

**Linux:**
```bash
rm -rf ~/.local/share/dbug
rm -f ~/.local/bin/dbug
rm -f ~/.local/share/applications/zm.co.cloud.dbug.desktop
find ~/.local/share/icons/hicolor -name "dbug*" -delete
```

**macOS:**
```bash
rm -rf /Applications/dbug.app
rm -rf ~/.local/share/dbug
```

## Usage

### Sending Requests

1. Select an HTTP method from the dropdown (GET, POST, etc.).
2. Enter the request URL. Use `{{variable}}` syntax to reference environment variables.
3. Optionally add query parameters, headers, and a request body.
4. Click **Send** (or press Enter) to execute the request.
5. The response panel shows status code, headers, body, size, and timing.

### Collections

- Create collections to group related requests.
- Import/export collections as JSON files.
- Click a collection item to load it into the Request Builder.
- Each collection item stores the full request configuration.

### Environments

1. Go to **Environments** in the sidebar.
2. Create an environment with a name and key-value variable pairs.
3. Select the active environment from the dropdown at the bottom of the sidebar.
4. Reference variables in requests using `{{variable_name}}`.

### OpenAPI Specs

1. Go to **OpenAPI** in the sidebar.
2. Import a spec by file, URL, or pasting JSON/YAML content.
3. Browse endpoints grouped by tags.
4. Click an endpoint to load it into the Request Builder with pre-filled parameters.

### Mock Server

1. Go to **Mock Server** in the sidebar.
2. Add mock endpoints with a method, path, status code, and response body.
3. Start the server (runs on `http://localhost:3001`).
4. Send requests to `http://localhost:3001/<path>` to get mock responses.

## Development

### Project Structure

```
lib/
  app/              # App widget, theme, routing
  core/             # Database, HTTP client, models, providers, repositories
  features/
    collections/    # Collection CRUD
    environments/   # Environment variable management
    history/        # Request history
    mock_server/    # Built-in mock server
    openapi/        # OpenAPI spec import and browsing
    request_builder/# HTTP request builder
    response_viewer/# Response display
    scripts/        # (Planned) Scripting support
    settings/       # App settings
  shared/           # Reusable widgets and utilities
```

### Tech Stack

- **Flutter** -- Cross-platform UI framework
- **shadcn_flutter** -- UI component library
- **Riverpod** -- State management
- **GoRouter** -- Declarative routing
- **sqflite** -- Local SQLite database
- **Dio** -- HTTP client
- **Freezed** -- Immutable data classes
- **Shelf** -- Mock HTTP server

### License

MIT
