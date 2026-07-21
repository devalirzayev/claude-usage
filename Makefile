APP_NAME := Claude Usage
BINARY := ClaudeUsageBar
CONFIGURATION := release
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE := .build/$(CONFIGURATION)/$(BINARY)

.PHONY: build test app run clean vendor-cswap

build:
	swift build -c $(CONFIGURATION)

test:
	swift test

app: build
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	cp "$(EXECUTABLE)" "$(APP_DIR)/Contents/MacOS/$(BINARY)"
	cp Resources/Info.plist "$(APP_DIR)/Contents/Info.plist"
	ditto -x -k Vendor/cswap.zip "$(APP_DIR)/Contents/Resources"

run: app
	open "$(APP_DIR)"

vendor-cswap:
	scripts/vendor-cswap.sh

clean:
	rm -rf .build "$(BUILD_DIR)"
