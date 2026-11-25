# OozeLogin

Greeter para greetd hecho con Quickshell, con ventana de configuración propia y conexión opcional con OozeShell. Funciona en NixOS y en Arch Linux.

## Instalación en NixOS

OozeLogin es un flake independiente. 

Para instalarlo sigue lo siguiente:

Crea un modulo llamado oozelogin.nix y enlazalo en tu configuration.nix puedes ver el ejemplo desde [configuration.nix](https://github.com/oozeux/nix-home/blob/main/configuration.nix)

### Como módulo

#### oozelogin.nix

```nix

{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.oozelogin.nixosModules.default ];
  
  services.oozelogin = {
    enable = true;
    compositor = "hyprland";
    compositorPackage = config.programs.hyprland.package;
    keyboardLayouts = [ "us" "latam" ];
    sync.enable = true;
    settings = {
      showStats = false;
      showWeather = false;
    };
  };
}

```
Si usas otro compositor simplemente reemplaza el de hyprland por el que prefieras, el resto de la configuracion sigue igual, para poder cambiar el compositor debes activarlo en tu configuration.nix.

Si activas mas de un compositor ademas del agregado en la configuracion se puede cambiar desde la pantalla de inicio, esta configuracion quedaría simplemente como el compositor principal sin afectar el uso de uno o más compositores.

```nix

imports = [ inputs.oozelogin.nixosModules.default ];
  
  services.oozelogin = {
    enable = true;
    compositor = "niri";
    compositorPackage = config.programs.niri.package;
    # ...
```

#### Nix flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    oozelogin = {
      url = "github:oozeux/oozelogin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
      ];
    };
  };
}

```

Tu usuario debe estar en el grupo `users` (o cambia `services.oozelogin.group`). Después `sudo nixos-rebuild switch`.

#### Nota:
 El compositor que uses debe estar habilitado en algún módulo de tu configuración (por ejemplo programs.hyprland.enable = true; o programs.niri.enable = true;), ya que oozelogin.nix referencia config.programs.(compositor).package. No importa en qué archivo .nix lo habilites, solo que exista. Para ver un ejemplo de configuración completa revisa: [nix-home](https://github.com/oozeux/nix-home).

### Probar sin instalar (cualquier distro con Nix)

```sh
nix run github:oozeux/oozelogin#preview
nix run github:oozeux/oozelogin#settings
```

Fuera del módulo, la configuración y la caché viven en `~/.local/state/oozelogin` y `~/.cache/oozelogin`.


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
