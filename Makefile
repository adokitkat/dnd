PREFIX = $(HOME)/.local
MANPREFIX = $(PREFIX)/share/man
VERSION = $(shell grep -ohP -m 1 "(\d+\.\d+\.\d+)" dnd.nimble)

define DESKTOP_ENTRY
[Desktop Entry]
Name=dnd
Exec=$(PREFIX)/bin/dnd
Icon=$(PREFIX)/share/icons/dnd.xpm
Terminal=false
Type=Application
endef
export DESKTOP_ENTRY

.PHONY: all build run install uninstall desktop-entry tarball

all: build

build: src/dnd.nim
	nimble build

run: dnd
	./dnd $(ARGS)

install: dnd
	mkdir -p $(PREFIX)/bin
	cp -f dnd $(PREFIX)/bin
	chmod 755 $(PREFIX)/bin/dnd
	mkdir -p $(HOME)/.config/dnd
	cp -f dnd.cfg $(HOME)/.config/dnd/dnd.cfg
	cp -f resources/dnd.xpm $(PREFIX)/share/icons/dnd.xpm
	echo "$$DESKTOP_ENTRY" > dnd.desktop
	cp -f dnd.desktop $(PREFIX)/share/applications/dnd.desktop
	rm -f dnd.desktop

uninstall:
	rm -f $(PREFIX)/bin/dnd $(HOME)/.config/dnd.cfg $(PREFIX)/share/applications/dnd.desktop $(PREFIX)/share/icons/dnd.xpm 

desktop-entry:
	echo "$$DESKTOP_ENTRY" > dnd.desktop

tarball: dnd.nimble dnd src/dnd.nim dnd.cfg README.md resources/dnd.xpm resources/dnd.png
	tar -czvf dnd_$(VERSION)_x64.tar.gz dnd src/dnd.nim dnd.nimble dnd.cfg README.md Makefile resources/dnd.xpm resources/dnd.png
