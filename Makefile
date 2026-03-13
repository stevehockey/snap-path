# ─────────────────────────────────────────────────────────────────────────────
# SnapPath — macOS menu-bar screenshot utility
# Requires: Swift toolchain (Xcode or swift.org), macOS 13+
# ─────────────────────────────────────────────────────────────────────────────

APP_NAME      := SnapPath
BUILD_DIR     := .build
RELEASE_BIN   := $(BUILD_DIR)/release/$(APP_NAME)
DEBUG_BIN     := $(BUILD_DIR)/debug/$(APP_NAME)
APP_BUNDLE    := $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR   := /Applications
PLIST_SRC     := Resources/Info.plist

.DEFAULT_GOAL := build

# ─── Build ────────────────────────────────────────────────────────────────────

.PHONY: build
build:                              ## Debug build (fast iteration)
	swift build

.PHONY: release
release:                            ## Optimised release build
	swift build -c release

# ─── App Bundle ───────────────────────────────────────────────────────────────

.PHONY: app
app: release                        ## Build release .app bundle → .build/SnapPath.app
	@echo "Creating $(APP_BUNDLE)..."
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(RELEASE_BIN)"  "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	@cp "$(PLIST_SRC)"    "$(APP_BUNDLE)/Contents/Info.plist"
	@echo ""
	@echo "  Bundle : $(APP_BUNDLE)"
	@echo "  Run    : make open"
	@echo "  Install: make install"
	@echo ""

# ─── Run / Open ───────────────────────────────────────────────────────────────

.PHONY: run
run: build                          ## Build (debug) and run the binary directly
	"$(DEBUG_BIN)"

.PHONY: open
open: app                           ## Build app bundle and open it with macOS
	open "$(APP_BUNDLE)"

# ─── Install / Uninstall ──────────────────────────────────────────────────────

.PHONY: install
install: app                        ## Install app bundle to /Applications
	@echo "Installing to $(INSTALL_DIR)/$(APP_NAME).app ..."
	@cp -r "$(APP_BUNDLE)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed."

.PHONY: uninstall
uninstall:                          ## Remove app from /Applications
	@echo "Removing $(INSTALL_DIR)/$(APP_NAME).app ..."
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Uninstalled."

# ─── Test ─────────────────────────────────────────────────────────────────────

.PHONY: test
test:                               ## Run the full test suite
	swift test

# ─── Clean ────────────────────────────────────────────────────────────────────

.PHONY: clean
clean:                              ## Remove all build artefacts
	swift package clean
	@rm -rf "$(APP_BUNDLE)"

# ─── Help ─────────────────────────────────────────────────────────────────────

.PHONY: help
help:                               ## Print this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n\nTargets:\n"} \
	     /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
