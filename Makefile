APP_NAME    := net-thru
APP         := build/$(APP_NAME).app
INSTALL_DIR := /Applications
# Quits a running copy and waits until it's gone, so `open` doesn't race the old process.
QUIT        := pkill -x $(APP_NAME); while pgrep -x $(APP_NAME) >/dev/null; do sleep 0.1; done

# The demo renderer reuses the app's drawing code, minus its entry point and app delegate.
DEMO_SOURCES := $(filter-out %/main.swift %/AppDelegate.swift,$(wildcard Sources/NetThru/*.swift))

.PHONY: app run install uninstall icon demo clean

# Builds the release binary and wraps it in an ad-hoc signed .app bundle.
app:
	swift build -c release
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp "$$(swift build -c release --show-bin-path)/$(APP_NAME)" $(APP)/Contents/MacOS/
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

icon:
	swift scripts/make-icon.swift Resources/AppIcon.icns

# Re-renders the README animation (docs/demo-light.gif, docs/demo-dark.gif).
demo:
	mkdir -p .build
	swiftc -O $(DEMO_SOURCES) scripts/demo/main.swift -o .build/make-demo
	.build/make-demo docs -AppleLocale en_US

clean:
	rm -rf .build build
