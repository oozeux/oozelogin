# OozeLogin en Arch Linux

La versión de Arch no depende de Nix: usa archivos normales del sistema. Resumen general en el [README](../README.md).

## Instalación

```
git clone https://github.com/oozeux/oozelogin
cd oozelogin
sudo ./install.sh --compositor hyprland --layouts us,latam --sync
```

Opciones del instalador:

| Opción | Efecto |
|---|---|
| `--compositor hyprland\|niri` | Compositor que aloja el greeter. Debe ser uno que tengas instalado o que el instalador pueda instalar. |
| `--layouts us,latam` | Teclados disponibles en el login. |
| `--group nombre` | Grupo que puede editar `/var/lib/oozelogin` (por defecto `users`). Tu usuario se añade a él. |
| `--enable` | Ejecuta `systemctl enable --force greetd.service`. Sustituye a tu gestor de sesión actual. |
| `--sync` | Activa la sincronización automática de colores, fondo y avatar de OozeShell. |
| `--no-deps` | No instala paquetes con pacman. |
| `--no-greetd-config` | No toca `/etc/greetd/config.toml`. |

Sin `--enable` no cambia tu gestor de sesión actual. Prueba antes con `oozelogin-preview`; cuando te convenza, activa greetd con `--enable` o con `sudo systemctl enable --force greetd.service`.

## Dependencias

El instalador usa pacman para: `greetd`, `greetd-tuigreet`, `polkit`, `python`, `make`, `curl`, `procps-ng`, `qt6-wayland`, `ttf-nerd-fonts-symbols` y el compositor elegido. Para `quickshell` intenta primero los repositorios y después `paru` o `yay` (AUR). Si no encuentra ninguno, se detiene y te pide instalarlo.

## Comandos

| Comando | Qué hace |
|---|---|
| `oozelogin-settings` | Ventana de configuración |
| `oozelogin-preview` | Abre el greeter en una ventana de prueba (contraseña de prueba: `ooze`) |
| `oozelogin-sync` | Copia colores, fondo y avatar de OozeShell al greeter |

## Configuración

`/etc/oozelogin/oozelogin.conf` controla el arranque:

| Variable | Significado |
|---|---|
| `COMPOSITOR` | `hyprland` o `niri` |
| `KEYBOARD_LAYOUTS` | Lista separada por comas |
| `KEYBOARD_OPTIONS` | Opciones XKB, por ejemplo `grp:alt_shift_toggle` |
| `HYPRLAND_CONFIG_FORMAT` | `auto`, `lua` o `hyprlang`. Con `auto` se usa lua desde Hyprland 0.55. |
| `COMPOSITOR_COMMAND` | Comando completo propio. La config generada queda en `$OOZELOGIN_COMPOSITOR_CONFIG` |
| `FALLBACK_ENABLE` | `1` cae a tuigreet si el greeter falla |
| `FALLBACK_COMMAND` | Comando del greeter de respaldo |
| `FALLBACK_TIMEOUT` | Segundos de espera antes de dar el greeter por fallido |

`/etc/oozelogin/settings.json` guarda valores por defecto de la interfaz, por ejemplo `{ "layoutStyle": "split", "showStats": false }`. Lo guardado desde `oozelogin-settings` tiene prioridad.

## Qué instala y dónde

| Ruta | Contenido |
|---|---|
| `/usr/share/oozelogin/qml` | Interfaz QML |
| `/usr/lib/oozelogin/oozelogin-session` | Comando que ejecuta greetd. Genera la config del compositor, vigila el arranque y cae al respaldo si falla |
| `/usr/lib/oozelogin/oozelogin-run` | Se ejecuta dentro del compositor: lanza el greeter y cierra el compositor al terminar |
| `/usr/lib/oozelogin/env` | Variables compartidas por todos los scripts |
| `/usr/bin/oozelogin-*` | Comandos de usuario |
| `/etc/oozelogin/` | Configuración |
| `/etc/greetd/config.toml` | Sesión de greetd (la anterior se guarda como `config.toml.bak-oozelogin`) |
| `/usr/share/polkit-1/rules.d/50-oozelogin.rules` | Permite al usuario `greeter` apagar, reiniciar y suspender |
| `/usr/lib/tmpfiles.d/oozelogin.conf` | Crea `/var/lib/oozelogin` y `/var/cache/oozelogin` |
| `/usr/lib/sysusers.d/oozelogin.conf` | Declara el usuario `greeter` (grupo `video`) |
| `/usr/share/oozelogin/greetd.toml` | Sesión de greetd de referencia |
| `/usr/lib/systemd/user/oozelogin-sync.*` | Sincronización con OozeShell |

## Conexión con OozeShell

`oozelogin-sync` lee `~/.cache/oozeshell/colors.json`, el fondo actual de awww y `~/.config/oozeshell/profile.toml`, y lo copia a `/var/lib/oozelogin`. Con `--sync` se activa para todos los usuarios al iniciar sesión. Para activarlo en tu sesión actual: `systemctl --user enable --now oozelogin-sync.path`. En la página OozeShell de los ajustes activas el uso de esos colores y ese fondo.

## Solución de problemas

- Log del greeter: `/var/cache/oozelogin/greeter.log` (el anterior en `greeter.log.old`).
- Si ves tuigreet en lugar del greeter, el watchdog se activó: revisa el log.
- Si Hyprland avisa por no iniciarse con `start-hyprland`, define `COMPOSITOR_COMMAND` en `/etc/oozelogin/oozelogin.conf`.
- En máquinas virtuales desactiva el cristal desenfocado en Ajustes > Apariencia.
- Si `quickshell` no se ve con ese nombre en tu sistema, comprueba `command -v quickshell`.

## Desinstalar

```
sudo ./uninstall.sh          # conserva configuración y datos
sudo ./uninstall.sh --purge  # borra también /etc/oozelogin y /var/lib/oozelogin
```

Restaura tu `/etc/greetd/config.toml` anterior si existía la copia de seguridad.

## Instalar como paquete

```
cd packaging/arch
makepkg -si
```

El `PKGBUILD` empaqueta el árbol local con `make install install-config`. Las dependencias salen del propio paquete (`quickshell` desde repositorios o AUR). El paquete no modifica `/etc/greetd/config.toml`: copia `/usr/share/oozelogin/greetd.toml` y activa greetd a mano. Para publicarlo en AUR, cambia `package()` por una fuente `git+URL` y construye desde ese checkout.

## Probar el instalador sin tocar el sistema

```
DESTDIR=/tmp/stage ./install.sh --no-deps
```

Con `DESTDIR` solo copia archivos al directorio indicado y no ejecuta pacman, useradd ni systemctl.
