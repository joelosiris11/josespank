APP_NAME = SpankApp
APP_BUNDLE = $(APP_NAME).app
BUILD_DIR = .build/release

.PHONY: build app dmg clean

build:
	swift build -c release

app: build
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources
	@cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	@rm -rf $(APP_BUNDLE)/Contents/Resources/$(APP_NAME)_$(APP_NAME).bundle
	@cp -r $(BUILD_DIR)/$(APP_NAME)_$(APP_NAME).bundle $(APP_BUNDLE)/Contents/Resources/
	@cp scripts/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@echo "✓ $(APP_BUNDLE) listo"

dmg: app
	@rm -f SpankApp.dmg
	@hdiutil create -volname "Spank" -srcfolder $(APP_BUNDLE) -ov -format UDZO SpankApp.dmg
	@echo "✓ SpankApp.dmg listo"

clean:
	@rm -rf .build $(APP_BUNDLE) SpankApp.dmg
