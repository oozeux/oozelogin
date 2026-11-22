#!/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESTDIR="${DESTDIR:-}"

COMPOSITOR=hyprland
LAYOUTS=us
GROUP=users
DEPS=1
ENABLE=0
SYNC=0
GREETD_CONFIG=1

usage() {
  cat <<USAGE
Uso: sudo ./install.sh [opciones]

  --compositor hyprland|niri   Compositor que aloja el greeter (por defecto hyprland)
  --layouts us,latam           Distribuciones de teclado de la pantalla de login
  --group nombre               Grupo con permiso para editar la configuración (por defecto users)
  --enable                     Activa greetd.service al arrancar
  --sync                       Activa la sincronización automática con OozeShell
  --no-deps                    No instala dependencias con pacman
  --no-greetd-config           No modifica /etc/greetd/config.toml
  -h, --help                   Muestra esta ayuda
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --compositor) COMPOSITOR="${2:?}"; shift 2 ;;
    --layouts) LAYOUTS="${2:?}"; shift 2 ;;
    --group) GROUP="${2:?}"; shift 2 ;;
    --enable) ENABLE=1; shift ;;
    --sync) SYNC=1; shift ;;
    --no-deps) DEPS=0; shift ;;
    --no-greetd-config) GREETD_CONFIG=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opción desconocida: $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "$COMPOSITOR" in
  hyprland|niri) ;;
  *) echo "Compositor no soportado: $COMPOSITOR" >&2; exit 1 ;;
esac

say() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

if [ -z "$DESTDIR" ]; then
  [ "$(id -u)" -eq 0 ] || exec sudo -E "$0" "$@"
  command -v pacman >/dev/null 2>&1 || die "Este instalador es para Arch Linux (no se encontró pacman)"
fi

INVOKER="${SUDO_USER:-}"

install_quickshell() {
  command -v quickshell >/dev/null 2>&1 && return 0
  if pacman -Si quickshell >/dev/null 2>&1; then
    pacman -S --needed --noconfirm quickshell
    return 0
  fi
  if [ -n "$INVOKER" ]; then
    for helper in paru yay; do
      if command -v "$helper" >/dev/null 2>&1; then
        sudo -u "$INVOKER" "$helper" -S --needed --noconfirm quickshell
        return 0
      fi
    done
  fi
  die "Instala quickshell (repositorios o AUR) y vuelve a ejecutar el instalador"
}

install_deps() {
  say "Instalando dependencias"
  pacman -S --needed --noconfirm greetd greetd-tuigreet polkit python curl procps-ng qt6-wayland ttf-nerd-fonts-symbols make
  pacman -S --needed --noconfirm "$COMPOSITOR"
  install_quickshell
}

install_files() {
  say "Copiando archivos"
  command -v make >/dev/null 2>&1 || die "Falta make (sudo pacman -S make)"
  make -C "$HERE" DESTDIR="$DESTDIR" GROUP="$GROUP" install
}

install_config() {
  local conf="$DESTDIR/etc/oozelogin/oozelogin.conf"
  if [ -e "$conf" ]; then
    say "Conservando $conf existente"
    sed -i "s|^COMPOSITOR=.*|COMPOSITOR=$COMPOSITOR|; s|^KEYBOARD_LAYOUTS=.*|KEYBOARD_LAYOUTS=$LAYOUTS|" "$conf"
  else
    install -Dm644 "$HERE/packaging/arch/config/oozelogin.conf" "$conf"
    sed -i "s|^COMPOSITOR=.*|COMPOSITOR=$COMPOSITOR|; s|^KEYBOARD_LAYOUTS=.*|KEYBOARD_LAYOUTS=$LAYOUTS|" "$conf"
  fi
  if [ ! -e "$DESTDIR/etc/oozelogin/settings.json" ]; then
    install -Dm644 "$HERE/packaging/arch/config/settings.json" "$DESTDIR/etc/oozelogin/settings.json"
  fi
}

setup_system() {
  say "Preparando usuario, grupo y carpetas"
  getent group "$GROUP" >/dev/null || groupadd "$GROUP"
  if ! getent passwd greeter >/dev/null; then
    useradd -r -M -d /var/cache/oozelogin/home -s /usr/bin/nologin greeter
  fi
  usermod -aG video greeter
  if [ -n "$INVOKER" ] && ! id -nG "$INVOKER" | tr ' ' '\n' | grep -qx "$GROUP"; then
    usermod -aG "$GROUP" "$INVOKER"
    say "Usuario $INVOKER añadido al grupo $GROUP (cierra sesión para que se aplique)"
  fi
  systemd-tmpfiles --create /usr/lib/tmpfiles.d/oozelogin.conf

  if [ "$GREETD_CONFIG" -eq 1 ]; then
    say "Configurando greetd"
    install -d /etc/greetd
    if [ -f /etc/greetd/config.toml ] && [ ! -f /etc/greetd/config.toml.bak-oozelogin ]; then
      cp /etc/greetd/config.toml /etc/greetd/config.toml.bak-oozelogin
    fi
    install -Dm644 "$HERE/packaging/arch/config/greetd.toml" /etc/greetd/config.toml
  fi

  if [ "$ENABLE" -eq 1 ]; then
    say "Activando greetd.service"
    systemctl enable --force greetd.service
  fi

  if [ "$SYNC" -eq 1 ]; then
    say "Activando sincronización con OozeShell"
    systemctl --global enable oozelogin-sync.path
  fi
}

[ "$DEPS" -eq 1 ] && [ -z "$DESTDIR" ] && install_deps
install_files
install_config
[ -z "$DESTDIR" ] && setup_system

say "Listo"
cat <<DONE

Prueba la pantalla sin cerrar sesión:   oozelogin-preview
Abre los ajustes:                       oozelogin-settings
Configuración del sistema:              /etc/oozelogin/oozelogin.conf
Si no activaste greetd:                 sudo systemctl enable --force greetd.service
Log del greeter:                        /var/cache/oozelogin/greeter.log
DONE
