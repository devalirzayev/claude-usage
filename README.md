# Claude Usage Bar

A small macOS menu bar app for watching Claude account usage through `cswap`.

The app refreshes once per minute and reads:

```sh
cswap status --json
cswap list --json
```

It shows the active account's 5h usage in the menu bar and lists all managed accounts in the popup.

Build and run:

```sh
make run
```

The built app is at:

```text
build/Claude Usage.app
```

Requirements:

- macOS 13 or newer.
- `cswap` installed and configured with managed accounts.

Releases:

- Every push to `main` builds `build/Claude Usage.app`.
- The workflow uploads `Claude-Usage.zip` and a `Claude-Usage.zip.sha256` checksum to a new GitHub release.
- If Apple Developer ID secrets are configured, the workflow signs the app before packaging. Otherwise it uses ad-hoc signing.

Optional release signing secrets:

- `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64`: Base64-encoded `.p12` Developer ID Application certificate.
- `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD`: Password for the `.p12` file.
- `DEVELOPER_ID_APPLICATION_IDENTITY`: Signing identity name, for example `Developer ID Application: Name (TEAMID)`.
- `RELEASE_KEYCHAIN_PASSWORD`: Temporary CI keychain password.
