GROUP ?= users
ARCH := packaging/arch
QML := $(DESTDIR)/usr/share/oozelogin/qml
LIB := $(DESTDIR)/usr/lib/oozelogin

.PHONY: install install-config

install:
	install -d $(DESTDIR)/usr/share/oozelogin $(LIB)
	rm -rf $(QML)
	cp -r qml $(QML)
	find $(QML) -type d -exec chmod 755 {} +
	find $(QML) -type f -exec chmod 644 {} +
	install -Dm644 $(ARCH)/lib/env $(LIB)/env
	install -Dm755 $(ARCH)/lib/oozelogin-run $(LIB)/oozelogin-run
	install -Dm755 $(ARCH)/lib/oozelogin-session $(LIB)/oozelogin-session
	for bin in greeter preview settings; do \
		install -Dm755 $(ARCH)/bin/oozelogin-$$bin $(DESTDIR)/usr/bin/oozelogin-$$bin; \
	done
	install -Dm755 tools/oozelogin-sync $(DESTDIR)/usr/bin/oozelogin-sync
	install -Dm644 $(ARCH)/config/50-oozelogin.rules $(DESTDIR)/usr/share/polkit-1/rules.d/50-oozelogin.rules
	install -Dm644 $(ARCH)/config/systemd/oozelogin-sync.service $(DESTDIR)/usr/lib/systemd/user/oozelogin-sync.service
	install -Dm644 $(ARCH)/config/systemd/oozelogin-sync.path $(DESTDIR)/usr/lib/systemd/user/oozelogin-sync.path
	install -Dm644 $(ARCH)/config/oozelogin.sysusers $(DESTDIR)/usr/lib/sysusers.d/oozelogin.conf
	install -d $(DESTDIR)/usr/lib/tmpfiles.d
	sed "s/@GROUP@/$(GROUP)/g" $(ARCH)/config/oozelogin.tmpfiles.conf > $(DESTDIR)/usr/lib/tmpfiles.d/oozelogin.conf
	chmod 644 $(DESTDIR)/usr/lib/tmpfiles.d/oozelogin.conf
	install -Dm644 $(ARCH)/config/greetd.toml $(DESTDIR)/usr/share/oozelogin/greetd.toml
	install -Dm644 docs/LAYOUTS.md $(DESTDIR)/usr/share/doc/oozelogin/LAYOUTS.md

install-config:
	install -Dm644 $(ARCH)/config/oozelogin.conf $(DESTDIR)/etc/oozelogin/oozelogin.conf
	install -Dm644 $(ARCH)/config/settings.json $(DESTDIR)/etc/oozelogin/settings.json
