# Thin aliases over build.sh, which is the single source of truth for builds.
#
#   ./build.sh [platform] [flavor] [mode]
#   platform : macos | ios | android-aab | android-apk | windows | linux | web | all
#   flavor   : personal | store | both
#   mode     : debug | release
#
# See plans/store-release-plan.md §10.

.PHONY: help build \
        personal-android store-android \
        personal-macos store-macos \
        store-ios store-all \
        verify analyze test clean

help:
	@echo "Interactive:"
	@echo "  ./build.sh                 pick platform / flavour / mode from a menu"
	@echo ""
	@echo "Common shortcuts:"
	@echo "  make store-android         AAB for Play + verification scan"
	@echo "  make personal-android      APK, personal flavour"
	@echo "  make store-macos           macOS release, store flavour"
	@echo "  make personal-macos        macOS release, personal flavour"
	@echo "  make store-ios             iOS archive for the App Store"
	@echo "  make store-all             every store build this host can produce"
	@echo ""
	@echo "Checks:"
	@echo "  make verify                scan the store artifact for third-party sources"
	@echo "  make analyze / make test"
	@echo ""
	@echo "Running from VS Code: use the launch configurations in .vscode/launch.json"

build:
	@./build.sh

personal-android:
	@./build.sh android-apk personal release

store-android:
	@./build.sh android-aab store release

personal-macos:
	@./build.sh macos personal release

store-macos:
	@./build.sh macos store release

store-ios:
	@./build.sh ios store release

store-all:
	@./build.sh all store release

verify:
	@tool/verify_store_build.sh

analyze:
	flutter analyze

test:
	flutter test test/unit_tests

clean:
	flutter clean
