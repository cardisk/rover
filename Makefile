.PHONY: build

sources = src/*

build: src
	mkdir -p build
	cc -c extern/winbox.c -o build/winbox.o
	ar -rcs build/libwinbox.a build/winbox.o
	c3c compile -L build -l winbox -l ncurses -o build/rover $(sources)

run: build 
	@build/rover
