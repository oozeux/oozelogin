#!/bin/bash
set -euo pipefail

DESTDIR="${DESTDIR:-}"
PURGE=0

for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=1 ;;
    -h|--help)
      echo "Uso: sudo ./uninstall.sh [--purge]"
      echo "  --purge   Borra también /etc/oozelogin y /var/lib/oozelogin"
      exit 0 ;;
    *) echo "Opción desconocida: $arg" >&2; exit 1 ;;
  esac
done

say() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }

if [ -z "$DESTDIR" ] && [ "$(id -u)" -ne 0 ]; then
  exec sudo -E "$0" "$@"
fi

if [ -z "$DESTDIR" ]; then
  systemctl --global disable oozelogin-sync.path 2>/dev/null || true
  if [ -f /etc/greetd/config.toml.bak-oozelogin ]; then
    say "Restaurando /etc/greetd/config.toml"
    mv -f /etc/greetd/config.toml.bak-oozelogin /etc/greetd/config.toml
  fi
fi

say "Eliminando archivos"
rm -rf "$DESTDIR/usr/share/oozelogin" "$DESTDIR/usr/lib/oozelogin" "$DESTDIR/usr/share/doc/oozelogin"
rm -f "$DESTDIR/usr/bin/oozelogin-greeter" "$DESTDIR/usr/bin/oozelogin-preview" \
      "$DESTDIR/usr/bin/oozelogin-settings" "$DESTDIR/usr/bin/oozelogin-sync"
rm -f "$DESTDIR/etc/polkit-1/rules.d/50-oozelogin.rules" \
      "$DESTDIR/usr/share/polkit-1/rules.d/50-oozelogin.rules" \
      "$DESTDIR/usr/lib/tmpfiles.d/oozelogin.conf" \
      "$DESTDIR/usr/lib/sysusers.d/oozelogin.conf" \
      "$DESTDIR/usr/lib/systemd/user/oozelogin-sync.service" \
      "$DESTDIR/usr/lib/systemd/user/oozelogin-sync.path"

if [ "$PURGE" -eq 1 ]; then
  say "Borrando configuración y datos"
  rm -rf "$DESTDIR/etc/oozelogin" "$DESTDIR/var/lib/oozelogin" "$DESTDIR/var/cache/oozelogin"
fi

say "Listo"
echo "Si greetd estaba activado y quieres otro gestor de sesión, desactívalo con: sudo systemctl disable greetd.service"
