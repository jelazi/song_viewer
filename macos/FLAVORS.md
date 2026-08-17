# macOS flavour setup (one-off, manual)

Flutter supports `--flavor` on macOS, but — as on iOS — the build configurations
and schemes live inside `Runner.xcodeproj/project.pbxproj`, which is not safe to
edit by hand. The `.xcconfig` files are already written; only the wiring is left.

**Everything already works without this setup.** The entrypoint plus
`--dart-define-from-file` fully separates the two flavours, including which code
is compiled in. This step only adds separate bundle identifiers and app names, so
both builds can coexist on one Mac and be signed independently.

## 1. Build configurations

Open `macos/Runner.xcworkspace` → select the **Runner** project → **Info** tab →
**Configurations**. Duplicate `Debug`, `Release` and `Profile` into:

| Configuration | Config file for the Runner target |
|---|---|
| `Debug-personal` | `Runner/Configs/Personal.xcconfig` |
| `Release-personal` | `Runner/Configs/Personal.xcconfig` |
| `Profile-personal` | `Runner/Configs/Personal.xcconfig` |
| `Debug-store` | `Runner/Configs/Store.xcconfig` |
| `Release-store` | `Runner/Configs/Store.xcconfig` |
| `Profile-store` | `Runner/Configs/Store.xcconfig` |

> The names matter: Flutter resolves `<BuildMode>-<flavor>`, so `--flavor store`
> in release mode looks for `Release-store`.

Each new xcconfig must keep including what the original did, so add at the top of
`Personal.xcconfig` and `Store.xcconfig`:

```
#include "../../Flutter/Flutter-Release.xcconfig"   // or Flutter-Debug for debug configs
#include "Warnings.xcconfig"
```

## 2. Clear the hardcoded bundle identifier

**This step is easy to miss.** `PRODUCT_BUNDLE_IDENTIFIER` is currently set
directly in `project.pbxproj` (`com.lzizka.songsviewer.macos`), and a value in the
project file **overrides** the one from an xcconfig. Until it is cleared, both
flavours will keep producing the same bundle identifier and the xcconfig values
will appear to be ignored.

In Xcode → Runner target → **Build Settings** → search `Product Bundle
Identifier` → select the value and delete it for each of the six new
configurations, so it falls through to the xcconfig.

## 3. Schemes

**Product → Scheme → Manage Schemes…** → duplicate `Runner` into `personal` and
`store`, pointing each at its own configurations (Archive → `Release-<flavor>`).
Tick **Shared** so they land in `macos/Runner.xcodeproj/xcshareddata/xcschemes/`.

## 4. Then

Add `"--flavor", "personal"` / `"--flavor", "store"` to the macOS entries in
`.vscode/launch.json`, and `./build.sh macos store release` will pick up the
right configuration automatically.
