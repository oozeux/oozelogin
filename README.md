# OozeLogin

Greeter para greetd hecho con Quickshell, con ventana de configuración propia y conexión opcional con OozeShell. Funciona en NixOS y en Arch Linux desde el mismo repositorio.

## Instalación en NixOS

OozeLogin es un flake independiente. Exporta un módulo de NixOS, un paquete, un overlay y apps para probarlo sin instalarlo.

### Como módulo

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    oozelogin = {
      url = "github:oozeux/oozelogin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, oozelogin, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      modules = [
        oozelogin.nixosModules.default
        { services.oozelogin.enable = true; }
      ];
    };
  };
}
```

Tu usuario debe estar en el grupo `users` (o cambia `services.oozelogin.group`). Después `sudo nixos-rebuild switch`.

### Probar sin instalar (cualquier distro con Nix)

```sh
nix run github:oozeux/oozelogin#preview
nix run github:oozeux/oozelogin#settings
```

Fuera del módulo, la configuración y la caché viven en `~/.local/state/oozelogin` y `~/.cache/oozelogin`.

### Sin flakes

`imports = [ /ruta/a/oozelogin/nix/module.nix ];`

### Desarrollo

`nix develop` entrega Quickshell y Python. `nix build` construye el paquete y `nix flake check` lo verifica.

## Instalación en Arch Linux

Hay dos caminos. Los detalles de opciones, archivos y solución de problemas están en [docs/ARCH.md](docs/ARCH.md).

### Con el instalador

```sh
git clone https://github.com/oozeux/oozelogin
cd oozelogin
sudo ./install.sh --compositor hyprland --layouts us,latam --sync
```

### Como paquete (pacman)

```sh
cd oozelogin/packaging/arch
makepkg -si
```

Sin `--enable` (instalador) el gestor de sesión actual no cambia. Prueba antes con `oozelogin-preview`.

## Estructura

| Ruta | Contenido |
|---|---|
| `qml/`, `tools/` | Interfaz y herramienta `oozelogin-sync`. Compartidos por todas las plataformas |
| `flake.nix`, `nix/` | NixOS: `packages`, `apps`, `overlays`, `nixosModules`, `devShells`, `checks`. `nix/package.nix` admite `override` y `nix/module.nix` define `services.oozelogin` |
| `install.sh`, `uninstall.sh`, `Makefile` | Arch: instalador y reglas de instalación con `DESTDIR` |
| `packaging/arch/` | Arch: scripts de arranque (`lib/`), lanzadores (`bin/`), configuración (`config/`) y `PKGBUILD` |

Para probar el instalador sin tocar el sistema: `DESTDIR=/tmp/stage ./install.sh --no-deps`.

## Estilos de pantalla

Hay cuatro estilos: `single` (por defecto), `split`, `ambient` y `classic`. Se eligen en Ajustes > Interfaz o con `layoutStyle` en `services.oozelogin.settings` (NixOS) o `/etc/oozelogin/settings.json` (Arch). Detalles y guía para crear más en [docs/LAYOUTS.md](docs/LAYOUTS.md).

## Comandos

| Comando | Qué hace |
|---|---|
| `oozelogin-settings` | Ventana de configuración (apariencia, paneles, acceso, clima, OozeShell) |
| `oozelogin-preview` | Abre el greeter en una ventana de prueba (contraseña de prueba: `ooze`) |
| `oozelogin-sync` | Copia colores, fondo y avatar de OozeShell al greeter |

El botón **Probar** de la ventana de ajustes lanza la misma vista previa.

## Conexión con OozeShell

`oozelogin-sync` lee `~/.cache/oozeshell/colors.json` (matugen), el fondo actual de awww y `~/.config/oozeshell/profile.toml` o `profile.json`, y lo copia a `/var/lib/oozelogin`. Se ejecuta solo cada vez que cambian esos archivos con `services.oozelogin.sync.enable = true` (NixOS) o `--sync` en el instalador (Arch). En la página **OozeShell** de los ajustes activas el uso de esos colores y ese fondo.

Para abrir los ajustes desde OozeShell puedes lanzar `oozelogin-settings` desde un atajo o un botón.

## Notas

- Si Hyprland muestra un aviso por no iniciarse con `start-hyprland`, define tu propio comando: `services.oozelogin.compositorCommand` en NixOS o `COMPOSITOR_COMMAND` en `/etc/oozelogin/oozelogin.conf` en Arch.
- En máquinas virtuales o equipos lentos desactiva el cristal desenfocado en Apariencia.
- Reiniciar y apagar funcionan gracias a una regla polkit para el usuario `greeter`.
