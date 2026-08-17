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
#   personal — full feature set, including web import. For own use and desktop
#              distribution. NEVER submit this to an app store.
#   store    — the sellable build. Web import is compiled out; local-first start.
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

# Which platforms Flutter accepts `--flavor` for. Verified with
# `flutter build <platform> --help` on Flutter 3.44.
supports_flavor() {
    case "$1" in
        macos|ios|android-aab|android-apk) return 0 ;;
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
config_for()     { echo "config/$1.json"; }

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
    config="$(config_for "$flavor")"
    obfuscate="$(obfuscation_args_for "$flavor" "$mode")"

    flavor_arg=""
    if supports_flavor "$platform"; then
        flavor_arg="--flavor $flavor"
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

    if ! supports_flavor "$platform"; then
        echo "NOTE: Flutter has no --flavor for $platform; the entrypoint and"
        echo "      --dart-define-from-file do the separation, and the output is"
        echo "      copied to dist/$flavor/$platform/ so the flavours do not"
        echo "      overwrite each other."
    fi

    # shellcheck disable=SC2086
    case "$platform" in
        macos)
            flutter build macos --"$mode" $flavor_arg -t "$entry" --dart-define-from-file="$config" $obfuscate
            ;;
        ios)
            if [ "$mode" = "release" ]; then
                flutter build ipa $flavor_arg -t "$entry" --dart-define-from-file="$config" $obfuscate
            else
                flutter build ios --debug $flavor_arg -t "$entry" --dart-define-from-file="$config"
            fi
            ;;
        android-aab)
            flutter build appbundle --release $flavor_arg -t "$entry" --dart-define-from-file="$config" $obfuscate
            ;;
        android-apk)
            flutter build apk --"$mode" $flavor_arg -t "$entry" --dart-define-from-file="$config" $obfuscate
            ;;
        windows)
            flutter build windows --"$mode" -t "$entry" --dart-define-from-file="$config" $obfuscate
            ;;
        linux)
            flutter build linux --"$mode" -t "$entry" --dart-define-from-file="$config" $obfuscate
            ;;
        web)
            flutter build web -t "$entry" --dart-define-from-file="$config"
            ;;
    esac

    collect_output "$platform" "$flavor" "$mode"
    verify_if_store "$platform" "$flavor"
}

# For platforms without native flavour separation, copy the build out of the
# shared output directory so the next flavour does not overwrite it.
collect_output() {
    local platform="$1" flavor="$2" mode="$3"
    local src dest
    dest="dist/$flavor/$platform"

    # Windows output uses a capitalised mode directory (Debug/Release).
    # Written out longhand because macOS ships bash 3.2, which has no ${var^}.
    local mode_capitalized
    case "$mode" in
        debug)   mode_capitalized="Debug" ;;
        release) mode_capitalized="Release" ;;
        *)       mode_capitalized="$mode" ;;
    esac

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

verify_if_store() {
    local platform="$1" flavor="$2"
    [ "$flavor" = "store" ] || return 0
    [ -x tool/verify_store_build.sh ] || return 0

    local artifact=""
    case "$platform" in
        android-aab) artifact="$(find build/app/outputs/bundle -name '*.aab' 2>/dev/null | head -n1)" ;;
        android-apk) artifact="$(find build/app/outputs/flutter-apk -name '*store*.apk' 2>/dev/null | head -n1)" ;;
        macos)       artifact="$(find "build/macos/Build/Products" -maxdepth 2 -name '*.app' 2>/dev/null | head -n1)" ;;
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
