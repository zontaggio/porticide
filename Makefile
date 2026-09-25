.PHONY: build test run app install screenshots icon logos clean

build:
	swift build

test:
	swift test

run:
	swift run Porticide

app:
	scripts/bundle-app.sh

install: app
	rm -rf /Applications/Porticide.app
	cp -R build/Porticide.app /Applications/
	@echo "Installed to /Applications/Porticide.app"

# Regenerate README images from demo data (debug builds only).
screenshots:
	swift build
	.build/debug/Porticide --render-screenshots docs/assets

icon:
	swift scripts/generate-app-icon.swift

logos:
	swift scripts/update-logos.swift

clean:
	swift package clean
	rm -rf build
