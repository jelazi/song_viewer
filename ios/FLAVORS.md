# iOS flavour setup (one-off, manual)

Android flavours are fully configured in `android/app/build.gradle`. iOS needs a
one-off pass in Xcode, because build configurations and schemes live inside
`Runner.xcodeproj/project.pbxproj` and editing that by hand is a good way to
corrupt the project.

The `.xcconfig` files are already written — only the wiring is left.

## 1. Create the build configurations

Open `ios/Runner.xcworkspace` in Xcode → select the **Runner** project (not the
target) → **Info** tab → **Configurations**.

Duplicate the existing `Debug`, `Release` and `Profile` configurations so you end
up with:

| Configuration | Based on | Set the Runner target's config file to |
|---|---|---|
| `Debug-personal` | Debug | `Flutter/Personal.xcconfig` |
| `Release-personal` | Release | `Flutter/Personal.xcconfig` |
| `Profile-personal` | Profile | `Flutter/Personal.xcconfig` |
| `Debug-store` | Debug | `Flutter/Store.xcconfig` |
| `Release-store` | Release | `Flutter/Store.xcconfig` |
| `Profile-store` | Profile | `Flutter/Store.xcconfig` |

> The names matter. Flutter looks for `<BuildMode>-<flavor>`, so `--flavor store`
> in release mode resolves to `Release-store`. A mismatch produces
> "The Xcode project does not define custom schemes".

Each `Personal.xcconfig` / `Store.xcconfig` must keep including the generated
Flutter config, so add at the top of each:

```
#include "Generated.xcconfig"
```

…and keep the Pods include that the original Debug/Release xcconfig had.

## 2. Create the schemes

**Product → Scheme → Manage Schemes…** → duplicate `Runner` twice:

- `personal` — set Run/Test/Profile/Analyze to the `*-personal` configurations,
  Archive to `Release-personal`
- `store` — set them to the `*-store` configurations, Archive to `Release-store`

Tick **Shared** for both, so they are committed to git under
`ios/Runner.xcodeproj/xcshareddata/xcschemes/`.

## 3. Signing

Under the Runner target → **Signing & Capabilities**, each configuration needs a
provisioning profile matching its bundle identifier:

- `com.lzizka.songviewer.personal` — development profile is enough
- `com.lzizka.songviewer` — needs an App Store distribution profile

Register both identifiers in the Apple Developer portal first.

## 4. Verify

```bash
flutter build ios --flavor store -t lib/main_store.dart \
    --dart-define-from-file=config/store_mobile.json --no-codesign
```

(iOS is published through the App Store, so it uses `store_mobile.json` with web
import compiled out. `./build.sh ios store release` picks this automatically.)

Then run `tool/verify_store_build.sh` to confirm the artifact carries none of
the third-party source URLs.
