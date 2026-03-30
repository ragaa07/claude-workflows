# Rule 4: Build/Test Command Detection

Before the first implementation phase, detect build system from marker files:

| Marker | System | Marker | System |
|--------|--------|--------|--------|
| `build.gradle(.kts)` | Gradle | `go.mod` | go |
| `package.json` | npm | `pyproject.toml`/`setup.py` | python |
| `Cargo.toml` | cargo | `Package.swift` | swift |
| `CMakeLists.txt` | cmake | | |

Store detected commands for use wherever `<build-command>` or `<test-command>` appear.

**Verification**: After detecting a build system, verify the command works by running it. If it fails, ask the user for the correct command. Never assume a build command — always detect from marker files or ask.
