{
  description = "Helium Browser packaged for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          helium = pkgs.callPackage ./package.nix { };
        in
        {
          default = helium;
          helium-browser = helium;
          helium = helium;
        });

      apps = forAllSystems (system: {
        default = self.apps.${system}.helium;
        helium = {
          type = "app";
          program = lib.getExe self.packages.${system}.default;
        };
      });

      formatter = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixfmt-rfc-style);
    };
}
