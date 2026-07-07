APP_NAME := Claude Usage
BINARY := ClaudeUsageBar
CONFIGURATION := release
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE := .build/$(CONFIGURATION)/$(BINARY)

.PHONY: build app run clean

build:
	swift build -c $(CONFIGURATION)

app: build
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	cp "$(EXECUTABLE)" "$(APP_DIR)/Contents/MacOS/$(BINARY)"
	cp Resources/Info.plist "$(APP_DIR)/Contents/Info.plist"

run: app
	open "$(APP_DIR)"

clean:
	rm -rf .build "$(BUILD_DIR)"
