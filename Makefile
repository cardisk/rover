.PHONY: build

sources = src/*
test_sources = test/*

build: src
	mkdir -p build
	c3c compile -l ncurses -o build/rover $(sources)

run: build 
	@build/rover

dev:
	mkdir -p build
	c3c compile-run -l ncurses -o build/dev $(test_sources) src/layout.c3 

test:
	mkdir -p build
	c3c compile-test -o build/tester $(sources) $(test_sources)
