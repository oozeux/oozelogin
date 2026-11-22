{
  description = "OozeLogin, a Quickshell greeter for greetd";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        oozelogin = pkgs.callPackage ./nix/package.nix { };
        default = oozelogin;
      });

      apps = forAllSystems (pkgs:
        let
          package = self.packages.${pkgs.system}.default;
          app = name: {
            type = "app";
            program = "${package}/bin/${name}";
          };
        in
        {
          default = app "oozelogin-settings";
          settings = app "oozelogin-settings";
          preview = app "oozelogin-preview";
          sync = app "oozelogin-sync";
        });

      overlays.default = final: _prev: {
        oozelogin = final.callPackage ./nix/package.nix { };
      };

      nixosModules = {
        oozelogin = import ./nix/module.nix;
        default = self.nixosModules.oozelogin;
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.quickshell pkgs.python3 ];
        };
      });

      checks = forAllSystems (pkgs: {
        package = self.packages.${pkgs.system}.default;
      });
    };
}
