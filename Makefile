PREFIX = $(HOME)/.local
MANPREFIX = $(PREFIX)/share/man

.PHONY: all build install run uninstall

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
	nimble prepareInstall
	cp -f dnd.desktop $(PREFIX)/share/applications/dnd.desktop
	rm -f dnd.desktop

uninstall:
	rm -f $(PREFIX)/bin/dnd $(HOME)/.config/dnd.cfg $(PREFIX)/share/applications/dnd.desktop $(PREFIX)/share/icons/dnd.xpm 