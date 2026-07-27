{
  description = "Helium Browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in rec {
          default = helium-browser;
          helium-browser = pkgs.callPackage ./package.nix {};
          helium = helium-browser;
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/helium";
        };
      });

      formatter = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
          pkgs.nixfmt-rfc-style
      );
    };
}
