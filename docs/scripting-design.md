# Scripting Feature — Design Notes (Deferred)

Status: **Planned, not implemented**

## Goal

Allow users to write pre-request and post-request JavaScript scripts for:
- Setting/modifying variables before a request
- Asserting response status codes, headers, body content
- Extracting values from responses into environment variables

## Options Evaluated

### 1. Subprocess (Node.js via `Process.run`) — RECOMMENDED
- Shell out to `node -e "script"` via `dart:io`
- Full ES2023+ JS support, zero FFI complexity
- Requires Node.js installed (most devs have it)
- Postman uses this approach internally (Electron embeds Node)
- Fallback: graceful error message if `node` not found on PATH

### 2. `flutter_js` (QuickJS via FFI) — Self-contained
- Embeds a lightweight JS engine, no external deps
- Risk: FFI native compilation can break on some platforms
- Package maintenance is sporadic
- Currently in pubspec.yaml but unused

### 3. Dart-based assertion DSL — Simplest
- Mini assertion language parsed in Dart:
  ```
  @assert.status 200
  @assert.body.contains "user_id"
  @assert.header.content-type "application/json"
  @var.token = $response.body.id
  ```
- No external runtime, easy to implement/maintain
- Not JavaScript — less familiar to API testers

### 4. `dart_eval` package — Dart scripts
- Run Dart code as scripts instead of JS
- Native to ecosystem but unfamiliar syntax for most users

## Decision

**Pending.** Leaning toward Option 1 (Node.js subprocess) for development speed
and full JS compatibility, with Option 3 (Dart DSL) as a zero-dep fallback.

## Implementation Outline (when approved)

### `lib/core/scripting/script_engine.dart`
- `ScriptEngine.runPreRequest(script, variables) → Map<String, String>`
- `ScriptEngine.runPostRequest(script, response, variables) → List<AssertionResult>`
- `ScriptEngine.isAvailable() → bool` (checks for Node.js on PATH)

### `lib/core/scripting/assertion_result.dart`
- `AssertionResult { String label; bool passed; String? detail; }`

### `lib/core/scripting/dbug_api.js`
- Injected into the JS context as `dbug` global:
  - `dbug.getVar(name)` → read env variable
  - `dbug.setVar(name, value)` → write env variable
  - `dbug.response.status` → status code
  - `dbug.response.body` → parsed JSON body
  - `dbug.response.headers` → response headers
  - `dbug.assert.status(code)` → assert status
  - `dbug.assert.bodyContains(text)` → assert body substring
  - `dbug.assert.header(name, value)` → assert header value

### UI Changes
- Scripts tab: editor + results panel (pass/fail list + output log)
- Pre-request script runs before send, post-request after response
- Script errors shown inline, don't block the request

### pubspec.yaml
- Remove `flutter_js` if going with Node.js subprocess approach
- Or keep it as Option 2 fallback
