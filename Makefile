.PHONY: build test run app install clean

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

clean:
	swift package clean
	rm -rf build
