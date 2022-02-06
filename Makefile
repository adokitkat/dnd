PREFIX = $(HOME)/.local
MANPREFIX = $(PREFIX)/share/man
NAME = dnd

.PHONY: all build install uninstall

all: build

build: src/dnd.nim
	nimble build

install: $(NAME)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f $(NAME) $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/$(NAME)

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(NAME)