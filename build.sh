#!/bin/bash
#
# Songs Viewer — build script.
#
#   ./build.sh [platform] [flavor] [mode]
#
# With no arguments it asks interactively.
#
#   platform : macos | ios | android-aab | android-apk | windows | linux | web | all
#   flavor   : personal | store | both
#   mode     : debug | release
#
# Two products from one codebase (plans/store-release-plan.md §10):
#
#   personal — full feature set, PocketBase sync, band-specific behaviour.
#              For own use. NEVER submit this to an app store.
#   store    — the general, sellable build. Local-first start.
#
# Within the store flavour the feature set depends on *how it is distributed*,
# not on the flavour name:
#
#   Android / iOS  — published to Google Play and the App Store, so web import
#                    is compiled out (blocker B1). Uses config/store_mobile.json.
#   macOS/Win/Linux/web — distributed directly, no store policy applies, so web
#                    import stays enabled. Uses config/store_desktop.json.
#
# IMPORTANT: `--flavor` only exists on Android, iOS and macOS. On Windows, Linux
# and web Flutter has no flavor concept at all, so both flavors would overwrite
# each other in the same output directory. This script separates them by copying
# the result into dist/<flavor>/<platform>/ afterwards.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

HOST="$(uname -s)"

# ---------------------------------------------------------------- argument parsing

normalize_platform() {
    case "$1" in
        1|macos)                echo "macos" ;;
        2|ios)                  echo "ios" ;;
        3|android-aab|aab)      echo "android-aab" ;;
        4|android-apk|apk)      echo "android-apk" ;;
        5|windows|win)          echo "windows" ;;
        6|linux)                echo "linux" ;;
        7|web)                  echo "web" ;;
        8|all)                  echo "all" ;;
        *)                      echo "" ;;
    esac
}

normalize_flavor() {
    case "$1" in
        1|personal)  echo "personal" ;;
        2|store)     echo "store" ;;
        3|both)      echo "both" ;;
        *)           echo "" ;;
    esac
}

normalize_mode() {
    case "$1" in
        1|debug)    echo "debug" ;;
        2|release)  echo "release" ;;
        *)          echo "" ;;
    esac
}

PLATFORM="$(normalize_platform "${1:-}")"
FLAVOR="$(normalize_flavor "${2:-}")"
MODE="$(normalize_mode "${3:-}")"

if [ -z "$PLATFORM" ]; then
    echo "========================================"
    echo "  Songs Viewer — Build"
    echo "========================================"
    echo ""
    echo "Select platform:"
    echo "  1) macOS"
    echo "  2) iOS"
    echo "  3) Android AAB  (Play upload)"
    echo "  4) Android APK"
    echo "  5) Windows"
    echo "  6) Linux"
    echo "  7) Web"
    echo "  8) All buildable on this host"
    echo ""
    read -r -p "Enter choice [1-8]: " choice
    PLATFORM="$(normalize_platform "$choice")"
fi

if [ -z "$PLATFORM" ]; then
    echo "Invalid platform. Exiting."
    exit 1
fi

if [ -z "$FLAVOR" ]; then
    echo ""
    echo "Select flavor:"
    echo "  1) personal  — full features, web import ON. Never for stores."
    echo "  2) store     — sellable build, web import compiled out."
    echo "  3) both"
    echo ""
    read -r -p "Enter choice [1-3]: " choice
    FLAVOR="$(normalize_flavor "$choice")"
fi

if [ -z "$FLAVOR" ]; then
    echo "Invalid flavor. Exiting."
    exit 1
fi

if [ -z "$MODE" ]; then
    if [ "$PLATFORM" = "android-aab" ]; then
        MODE="release"
    else
        echo ""
        echo "Select build mode:"
        echo "  1) Debug"
        echo "  2) Release"
        echo ""
        read -r -p "Enter choice [1-2]: " choice
        MODE="$(normalize_mode "$choice")"
    fi
fi

if [ -z "$MODE" ]; then
    echo "Invalid build mode. Exiting."
    exit 1
fi

if [ "$PLATFORM" = "android-aab" ] && [ "$MODE" != "release" ]; then
    echo "Android AAB is release-only. Exiting."
    exit 1
fi

# ---------------------------------------------------------------- helpers

# Whether to pass `--flavor` for this platform.
#
# Flutter only accepts it on Android, iOS and macOS (verified with
# `flutter build <platform> --help` on Flutter 3.44) — Windows, Linux and web
# have no flavor concept at all.
#
# On iOS and macOS it additionally requires a matching shared Xcode scheme;
# passing it without one fails with "The Xcode project does not define custom
# schemes". So those are probed rather than assumed, which means the build keeps
# working before the manual Xcode setup (ios/FLAVORS.md, macos/FLAVORS.md) and
# starts using the flavour automatically once the schemes exist.
# Platforms where Flutter has no flavor concept at all, so both flavours land in
# the same output directory and have to be separated afterwards.
has_no_flavor_concept() {
    case "$1" in
        windows|linux|web) return 0 ;;
        *) return 1 ;;
    esac
}

supports_flavor() {
    local platform="$1" flavor="$2"
    case "$platform" in
        android-aab|android-apk) return 0 ;;
        ios)   [ -f "ios/Runner.xcodeproj/xcshareddata/xcschemes/$flavor.xcscheme" ] ;;
        macos) [ -f "macos/Runner.xcodeproj/xcshareddata/xcschemes/$flavor.xcscheme" ] ;;
        *) return 1 ;;
    esac
}

host_can_build() {
    case "$1" in
        macos|ios)  [ "$HOST" = "Darwin" ] ;;
        windows)    [[ "$HOST" == MINGW* || "$HOST" == MSYS* || "$HOST" == CYGWIN* ]] ;;
        linux)      [ "$HOST" = "Linux" ] ;;
        *)          return 0 ;;   # android and web build anywhere
    esac
}

entrypoint_for() { echo "lib/main_$1.dart"; }

# Platforms whose artifacts actually get uploaded to Google Play / the App Store.
# Only these are subject to the web-import restriction (blocker B1). Desktop
# builds are distributed directly, so store policy does not apply to them.
is_published_to_store() {
    case "$1" in
        android-aab|android-apk|ios) return 0 ;;
        *) return 1 ;;
    esac
}

# Which dart-define config a build uses:
#
#   personal              -> config/personal.json        everything on
#   store + mobile        -> config/store_mobile.json    web import OFF
#   store + desktop/web   -> config/store_desktop.json   web import ON
config_for() {
    local flavor="$1" platform="$2"
    if [ "$flavor" = "personal" ]; then
        echo "config/personal.json"
    elif is_published_to_store "$platform"; then
        echo "config/store_mobile.json"
    else
        echo "config/store_desktop.json"
    fi
}

# Obfuscation strips Dart symbol names from the AOT snapshot. Standard release
# practice, and it keeps flavour internals out of the shipped binary. The symbol
# maps must be kept, otherwise crash reports are unreadable.
obfuscation_args_for() {
    local flavor="$1" mode="$2"
    if [ "$flavor" = "store" ] && [ "$mode" = "release" ]; then
        echo "--obfuscate --split-debug-info=build/symbols/store"
    fi
}

# ---------------------------------------------------------------- the build itself

build_one() {
    local platform="$1" flavor="$2" mode="$3"

    local entry config flavor_arg obfuscate
    entry="$(entrypoint_for "$flavor")"
    config="$(config_for "$flavor" "$platform")"
    obfuscate="$(obfuscation_args_for "$flavor" "$mode")"

    # Untracked server settings that seed a fresh install (personal only).
    local server_config=""
    if [ "$flavor" = "personal" ] && [ -f config/server.local.json ]; then
        server_config="--dart-define-from-file=config/server.local.json"
    fi

    flavor_arg=""
    if supports_flavor "$platform" "$flavor"; then
        flavor_arg="--flavor $flavor"
    elif [ "$platform" = "ios" ] || [ "$platform" = "macos" ]; then
        echo "NOTE: no '$flavor' Xcode scheme yet, building without --flavor."
        echo "      The entrypoint and dart-defines still select the right feature"
        echo "      set; only the bundle id / app name stay shared."
        echo "      See $platform/FLAVORS.md to set the schemes up."
    fi

    echo ""
    echo "========================================"
    echo "  $platform · $flavor · $mode"
    echo "========================================"

    if ! host_can_build "$platform"; then
        echo "SKIP: $platform cannot be built on this host ($HOST)."
        case "$platform" in
            windows) echo "      Run this script on a Windows machine (Git Bash)." ;;
            linux)   echo "      Run this script on the Linux machine." ;;
            macos|ios) echo "      Requires macOS with Xcode." ;;
        esac
        return 0
    fi

    if has_no_flavor_concept "$platform"; then
        echo "NOTE: Flutter has no --flavor for $platform; the entrypoint and"
        echo "      --dart-define-from-file do the separation, and the output is"
        echo "      copied to dist/$flavor/$platform/ so the flavours do not"
        echo "      overwrite each other."
    fi

    # Gradle was seen packaging a libapp.so from an older build although Flutter
    # had just recompiled it (merge task stayed "up to date"), so drop its output.
    case "$platform" in
        android-aab|android-apk)
            local variant
            case "$platform:$mode" in
                android-aab:*|*:release) variant="${flavor}Release" ;;
                *:profile) variant="${flavor}Profile" ;;
                *) variant="${flavor}Debug" ;;
            esac
            rm -rf build/app/intermediates/merged_jni_libs/"$variant" \
                   build/app/intermediates/merged_native_libs/"$variant" \
                   build/app/intermediates/stripped_native_libs/"$variant"
            ;;
    esac

    # shellcheck disable=SC2086
    case "$platform" in
        macos)
            flutter build macos --"$mode" $flavor_arg -t "$entry" --dart-define-from-file="$config" $server_config $obfuscate
            ;;
        ios)
            if [ "$mode" = "release" ]; then
                flutter build ipa $flavor_arg -t "$entry" --dart-define-from-file="$config" $server_config $obfuscate
            else
                flutter build ios --debug $flavor_arg -t "$entry" --dart-define-from-file="$config" $server_config
            fi
            ;;
        android-aab)
            flutter build appbundle --release $flavor_arg -t "$entry" --dart-define-from-file="$config" $server_config $obfuscate
            ;;
        android-apk)
            flutter build apk --"$mode" $flavor_arg -t "$entry" --dart-define-from-file="$config" $server_config $obfuscate
            ;;
        windows)
            flutter build windows --"$mode" -t "$entry" --dart-define-from-file="$config" $server_config $obfuscate
            ;;
        linux)
            flutter build linux --"$mode" -t "$entry" --dart-define-from-file="$config" $server_config $obfuscate
            ;;
        web)
            flutter build web -t "$entry" --dart-define-from-file="$config" $server_config
            ;;
    esac

    collect_output "$platform" "$flavor" "$mode"
    rename_personal_macos_app "$platform" "$flavor" "$mode"
    verify_if_store "$platform" "$flavor"
    open_macos_finder_windows "$platform" "$flavor" "$mode"
}

# Xcode and the Windows runner use a capitalised mode directory (Debug/Release).
# Written out longhand because macOS ships bash 3.2, which has no ${var^}.
mode_dir_name() {
    case "$1" in
        debug)   echo "Debug" ;;
        release) echo "Release" ;;
        *)       echo "$1" ;;
    esac
}

# For platforms without native flavour separation, copy the build out of the
# shared output directory so the next flavour does not overwrite it.
collect_output() {
    local platform="$1" flavor="$2" mode="$3"
    local src dest
    dest="dist/$flavor/$platform"

    local mode_capitalized
    mode_capitalized="$(mode_dir_name "$mode")"

    case "$platform" in
        windows) src="build/windows/x64/runner/$mode_capitalized" ;;
        linux)   src="build/linux/x64/$mode/bundle" ;;
        web)     src="build/web" ;;
        *)       return 0 ;;   # flavour-aware platforms keep their own paths
    esac

    if [ -d "$src" ]; then
        rm -rf "$dest"
        mkdir -p "$(dirname "$dest")"
        cp -R "$src" "$dest"
        echo "Output: $dest"
    else
        echo "WARNING: expected output at $src but it is missing."
    fi
}

# The macOS bundle is named after the Flutter project (default_project.app). The
# personal build is only ever used locally, so rename it to the product name and
# it shows up as "Songs Viewer" in Finder and the Dock. Only the bundle
# directory is renamed — the executable and Info.plist inside are untouched.
MACOS_PERSONAL_APP_NAME="Songs Viewer.app"

# Directory Xcode wrote the bundle into. With a flavour scheme it appends the
# flavour to the configuration name (Release-personal); without one it is plain
# Release. Prints the first one that actually holds a bundle.
macos_products_dir() {
    local mode="$1" flavor="$2" base dir
    base="build/macos/Build/Products/$(mode_dir_name "$mode")"

    for dir in "$base-$flavor" "$base"; do
        if [ -n "$(find "$dir" -maxdepth 1 -name '*.app' -print -quit 2>/dev/null)" ]; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

rename_personal_macos_app() {
    local platform="$1" flavor="$2" mode="$3"
    [ "$platform" = "macos" ] && [ "$flavor" = "personal" ] || return 0

    local dir src dest
    if ! dir="$(macos_products_dir "$mode" "$flavor")"; then
        echo "WARNING: no macOS bundle found for $mode — not renamed."
        return 0
    fi

    src="$dir/default_project.app"
    if [ ! -d "$src" ]; then
        echo "WARNING: $src not found — not renamed."
        return 0
    fi

    dest="$dir/$MACOS_PERSONAL_APP_NAME"
    rm -rf "$dest"
    mv "$src" "$dest"
    echo "Output: $dest"
}

# Installing on macOS means dragging the bundle into /Applications, so open both
# Finder windows the moment the build is done: the build output and the
# applications folder.
open_macos_finder_windows() {
    local platform="$1" flavor="$2" mode="$3" dir
    [ "$platform" = "macos" ] && [ "$HOST" = "Darwin" ] || return 0

    if ! dir="$(macos_products_dir "$mode" "$flavor")"; then
        echo "NOTE: no macOS bundle found for $mode — not opening Finder."
        return 0
    fi

    open "$dir"
    open /Applications
    echo "Finder: $dir  +  /Applications"
}

verify_if_store() {
    local platform="$1" flavor="$2"
    [ "$flavor" = "store" ] || return 0
    [ -x tool/verify_store_build.sh ] || return 0

    # Desktop store builds keep web import on purpose — they are distributed
    # directly, not through an app store — so scanning them would always fail
    # and the gate would quickly get ignored. Only gate what actually ships.
    if ! is_published_to_store "$platform"; then
        echo ""
        echo "NOTE: $platform is not published through an app store, so web import"
        echo "      stays enabled and the B1 scan does not apply."
        return 0
    fi

    local artifact=""
    case "$platform" in
        android-aab) artifact="$(find build/app/outputs/bundle -name '*.aab' 2>/dev/null | head -n1)" ;;
        android-apk) artifact="$(find build/app/outputs/flutter-apk -name '*store*.apk' 2>/dev/null | head -n1)" ;;
        # Skip the renamed personal bundle — a store build must never be
        # verified against the personal one left behind in the same directory.
        macos)       artifact="$(find "build/macos/Build/Products" -maxdepth 2 -name '*.app' ! -name "$MACOS_PERSONAL_APP_NAME" 2>/dev/null | head -n1)" ;;
        ios)         artifact="$(find build/ios/ipa -name '*.ipa' 2>/dev/null | head -n1)" ;;
        windows|linux|web) artifact="dist/store/$platform" ;;
    esac

    if [ -n "$artifact" ] && [ -e "$artifact" ]; then
        echo ""
        echo "--- verifying store artifact ---"
        # A failed scan must fail the build: a store artifact that still carries
        # the third-party source hosts is blocker B1.
        tool/verify_store_build.sh "$artifact"
    else
        echo "WARNING: store artifact not found for $platform — SKIPPED verification."
        echo "         Do not upload an unverified store build."
    fi
}

# ---------------------------------------------------------------- dispatch

flavors_to_build=()
case "$FLAVOR" in
    both) flavors_to_build=(personal store) ;;
    *)    flavors_to_build=("$FLAVOR") ;;
esac

platforms_to_build=()
if [ "$PLATFORM" = "all" ]; then
    for p in macos ios android-aab android-apk windows linux web; do
        host_can_build "$p" && platforms_to_build+=("$p")
    done
    echo "Buildable on this host ($HOST): ${platforms_to_build[*]}"
else
    platforms_to_build=("$PLATFORM")
fi

for p in "${platforms_to_build[@]}"; do
    for f in "${flavors_to_build[@]}"; do
        build_one "$p" "$f" "$MODE"
    done
done

echo ""
echo "========================================"
echo "  Done."
echo "========================================"
