.PHONY: build run bundle clean

build:
	swift build

run:
	swift run MDown

bundle:
	./bundle.sh

install: bundle
	pkill -x MDown 2>/dev/null || true
	sleep 1
	rm -rf /Applications/MDown.app
	cp -r build/MDown.app /Applications/MDown.app
	open /Applications/MDown.app

clean:
	swift package clean
	rm -rf build
