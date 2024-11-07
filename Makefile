.PHONY: build

sources = src/*

build: src
	mkdir -p build
	c3c compile -l ncurses -o build/rover $(sources)

run: build 
	@build/rover
