# Claude Usage Bar

A small macOS menu bar app for watching Claude account usage through `cswap`.

The app refreshes once per minute and reads:

```sh
cswap status --json
cswap list --json
```

It shows the active account's 5h usage in the menu bar. The popup lists all managed accounts with their 5h usage plus any scoped usage windows reported by `cswap`, such as weekly Fable usage.

A self-contained `cswap` build is bundled inside the app (`Contents/Resources/cswap/`), so nothing else needs to be installed. The app prefers the bundled copy and falls back to a `cswap` found in `~/.local/bin`, `/opt/homebrew/bin`, or `/usr/local/bin`.

Build and run:

```sh
make run
```

The built app is at:

```text
build/Claude Usage.app
```

Requirements:

- macOS 13 or newer on Apple Silicon (the bundled `cswap` is an arm64 build).
- `cswap` accounts configured (`cswap add`), either through the bundled binary or a separate install.

Updating the bundled cswap:

```sh
make vendor-cswap
```

This rebuilds `Vendor/cswap.zip` with PyInstaller. Set `CSWAP_VERSION` to pin a different `claude-swap` release; it needs a Python 3.12+ with a shared libpython (python.org or Homebrew builds).

Releases:

- Every push to `main` builds `build/Claude Usage.app`.
- The workflow uploads `Claude-Usage.zip` and a `Claude-Usage.zip.sha256` checksum to a new GitHub release.
- If Apple Developer ID secrets are configured, the workflow signs the app before packaging. Otherwise it uses ad-hoc signing.

Optional release signing secrets:

- `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64`: Base64-encoded `.p12` Developer ID Application certificate.
- `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD`: Password for the `.p12` file.
- `DEVELOPER_ID_APPLICATION_IDENTITY`: Signing identity name, for example `Developer ID Application: Name (TEAMID)`.
- `RELEASE_KEYCHAIN_PASSWORD`: Temporary CI keychain password.
