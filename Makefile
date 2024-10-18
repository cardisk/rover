.PHONY: build

sources = src/*

build: src
	mkdir -p build
	c3c compile -o build/rover $(sources)
