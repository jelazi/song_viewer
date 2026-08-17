# Build entrypoints for the two flavours.
#
# personal — full feature set (web import, automatic PocketBase sync).
#            For own use and desktop distribution. Never submit to the stores.
# store    — the sellable build. Web import is compiled out; local-first start.
#
# See plans/store-release-plan.md §10.

.PHONY: help \
        personal-run store-run \
        personal-android store-android \
        personal-ios store-ios \
        verify analyze test clean

PERSONAL_ARGS := --flavor personal -t lib/main_personal.dart --dart-define-from-file=config/personal.json
STORE_ARGS    := --flavor store    -t lib/main_store.dart    --dart-define-from-file=config/store.json

# Obfuscation strips Dart symbol names from the AOT snapshot. Good release
# practice in itself, and it also removes the identifier residue that the
# feature flags cannot reach (method names kept for stack traces).
# Keep the symbol maps — without them a crash report is unreadable.
OBFUSCATE := --obfuscate --split-debug-info=build/symbols/store

help:
	@echo "Run:"
	@echo "  make personal-run       run the personal build on a connected device"
	@echo "  make store-run          run the store build"
	@echo ""
	@echo "Release:"
	@echo "  make personal-android   APK, personal flavour"
	@echo "  make store-android      AAB for Play + verification scan"
	@echo "  make store-ios          iOS archive for the App Store"
	@echo ""
	@echo "Checks:"
	@echo "  make verify             scan the store artifact for third-party sources"
	@echo "  make analyze            flutter analyze"
	@echo "  make test               unit tests"

personal-run:
	flutter run $(PERSONAL_ARGS)

store-run:
	flutter run $(STORE_ARGS)

personal-android:
	flutter build apk --release $(PERSONAL_ARGS)

# The verification scan is part of the target on purpose: a store artifact that
# was never scanned should not exist.
store-android:
	flutter build appbundle --release $(STORE_ARGS) $(OBFUSCATE)
	@$(MAKE) verify

personal-ios:
	flutter build ios --release $(PERSONAL_ARGS)

store-ios:
	flutter build ipa --release $(STORE_ARGS) $(OBFUSCATE)
	@tool/verify_store_build.sh $$(find build/ios/archive -name '*.xcarchive' | head -n1)/Products/Applications/*.app

verify:
	@tool/verify_store_build.sh

analyze:
	flutter analyze

test:
	flutter test test/unit_tests

clean:
	flutter clean
