APP_NAME    := net-thru
APP         := build/$(APP_NAME).app
VERSION     := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
ZIP         := build/$(APP_NAME)-$(VERSION).zip
# Universal binary, so the same download works on Apple Silicon and Intel Macs.
SWIFT_BUILD := swift build -c release --arch arm64 --arch x86_64
INSTALL_DIR := /Applications
# Quits a running copy and waits until it's gone, so `open` doesn't race the old process.
QUIT        := pkill -x $(APP_NAME); while pgrep -x $(APP_NAME) >/dev/null; do sleep 0.1; done

# The demo renderer reuses the app's drawing code, minus its entry point and app delegate.
DEMO_SOURCES := $(filter-out %/main.swift %/AppDelegate.swift,$(wildcard Sources/NetThru/*.swift))

.PHONY: app run install uninstall release icon demo clean

# Builds the release binary and wraps it in an ad-hoc signed .app bundle.
app:
	$(SWIFT_BUILD)
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp "$$($(SWIFT_BUILD) --show-bin-path)/$(APP_NAME)" $(APP)/Contents/MacOS/
	cp Resources/Info.plist $(APP)/Contents/
	cp Resources/AppIcon.icns $(APP)/Contents/Resources/
	codesign --force --sign - $(APP)

# Runs the freshly built bundle from build/ (quits a running copy first).
run: app
	@$(QUIT)
	open $(APP)

install: app
	@$(QUIT)
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	cp -R $(APP) $(INSTALL_DIR)/
	open $(INSTALL_DIR)/$(APP_NAME).app

uninstall:
	@$(QUIT)
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app

# Zips the app for a GitHub release; prints the checksum the Homebrew cask needs.
release: app
	rm -f $(ZIP)
	ditto -c -k --keepParent $(APP) $(ZIP)
	shasum -a 256 $(ZIP)

icon:
	swift scripts/make-icon.swift Resources/AppIcon.icns

# Re-renders the README animation (docs/demo-light.gif, docs/demo-dark.gif).
demo:
	mkdir -p .build
	swiftc -O $(DEMO_SOURCES) scripts/demo/main.swift -o .build/make-demo
	.build/make-demo docs -AppleLocale en_US

clean:
	rm -rf .build build
