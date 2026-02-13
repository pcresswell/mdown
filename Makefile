.PHONY: build run bundle clean

build:
	swift build

run:
	swift run MDown

bundle: build
	./bundle.sh

clean:
	swift package clean
	rm -rf build
