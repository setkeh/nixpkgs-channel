{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    systems.url = "github:nix-systems/default";
    scikit-learn-1-2.url = "github:NixOS/nixpkgs/e08e100b0c6a6651c3235d1520c53280142d9d5f";
  };

  outputs =
    inputs@{ flake-parts, systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;

      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
        ./modules/overlay.nix
        ./modules/formatter.nix
        ./modules/pkgs-by-name.nix
        ./modules/pkgs-all.nix
      ];
    };
}