# dbug

A local API testing tool like Postman, built with Flutter.

## Features

- **Request Builder** -- Send HTTP requests (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS) with headers, query parameters, body (JSON, form data, raw), and authentication (Bearer, Basic, API Key). In-flight requests can be cancelled.
- **Collections** -- Organize requests into collections with shared global headers and auth. Import and export Postman v2.1 collections; rename, duplicate, move and delete requests.
- **History** -- Automatic logging of sent requests with response details, capped in size and count (configurable in Settings).
- **OpenAPI Specs** -- Import OpenAPI 3.x and Swagger 2.0 specs from files, URLs or pasted text, browse endpoints, and generate prefilled requests from them.
- **Environments** -- Define environment variables and switch between environments. Use `{{variable}}` syntax in URLs, headers, and body.
- **Mock Server** -- Built-in mock server (port 3001) with editable endpoints, path parameters (`/users/:id`), response delays and CORS support.
- **Settings** -- Theme and syntax theme, request timeout, self-signed TLS certificates, history limits.

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

Requires [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44+ (CI builds with 3.44.6).

On Linux, building also needs `libsecret-1-dev` (for the system keychain): `sudo apt install libsecret-1-dev`.

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
4. Click **Send** to execute the request (click **Cancel** to abort it).
5. The response panel shows status code, headers, body, size, and timing.

### Collections

- Create collections to group related requests.
- Import and export collections in Postman v2.1 format. Nested Postman folders become collections named `Parent / Child`. Collection global headers are not included in exports.
- Click a request to load it into the Request Builder. Use its menu to rename, duplicate, move or delete it.
- Each request stores its full configuration, including its own auth. Request auth overrides the collection's global auth.

### Environments

1. Go to **Environments** in the sidebar.
2. Create an environment with a name and key-value variable pairs.
3. Select the active environment from the dropdown at the bottom of the sidebar.
4. Reference variables in requests using `{{variable_name}}`. Names may contain letters, digits, `_`, `.` and `-`.

### OpenAPI Specs

1. Go to **OpenAPI** in the sidebar.
2. Import an OpenAPI 3.x or Swagger 2.0 spec by file, URL, or pasting JSON/YAML content.
3. Importing creates a collection with one request per endpoint (query/header parameters and a JSON body skeleton prefilled) and an environment holding `baseUrl` and the path parameters.
4. Browse endpoints grouped by tags, and click one to load it into the Request Builder.

### Mock Server

1. Go to **Mock Server** in the sidebar.
2. Add mock endpoints with a method, path, status code, headers, response body and optional delay. Paths may contain parameters (`/users/:id` or `/users/{id}`), and `{{params.id}}` in the body is replaced with the captured value.
3. Start the server (runs on `http://localhost:3001`).
4. Send requests to `http://localhost:3001/<path>` to get mock responses. CORS headers are added to every response, so browser apps can call it directly.

## Development

### Project Structure

```
lib/
  app/              # App widget, theme, routing
  core/             # Database, HTTP client, models, providers, repositories, request composition
  features/
    collections/    # Collection CRUD, Postman import/export
    environments/   # Environment variable management
    history/        # Request history
    mock_server/    # Built-in mock server
    openapi/        # OpenAPI/Swagger parsing, import and browsing
    request_builder/# HTTP request builder
    settings/       # App settings
  shared/           # Reusable widgets (response view, editors) and utilities
```

### Tech Stack

- **Flutter** -- Cross-platform UI framework
- **Yaru** -- Material theme base
- **Riverpod** -- State management
- **GoRouter** -- Declarative routing
- **sqflite** -- Local SQLite database
- **Dio** -- HTTP client
- **Freezed** -- Immutable data classes
- **Shelf** -- Mock HTTP server

### Data location

dbug stores its SQLite database (`dbug.db`) in the platform's application-support directory (for example `~/.local/share/zm.co.cloud.dbug/` on Linux). Older versions kept it in `~/Documents`; it is moved automatically on first launch. Credential-bearing fields (auth, request and collection headers, environment variables, and history headers and resolved URLs) are encrypted with AES-256-GCM. The key is kept in the system keychain (Secret Service/GNOME Keyring on Linux, Keychain on macOS, Credential Manager on Windows). If no keychain is available, it falls back to a private key file (`.data-key`, mode 0600) next to the database, and Settings shows which one is in use. Request bodies, query parameters and response bodies are not encrypted.

### Checks

```bash
flutter analyze
flutter test
```

CI runs both on every push and pull request, and a release is only built when they pass and the tag matches the `version:` in `pubspec.yaml`.

### License

MIT
