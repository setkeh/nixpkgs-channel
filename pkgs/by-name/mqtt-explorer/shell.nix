let
  pkgs = import <nixpkgs> {};
in
pkgs.stdenv.mkDerivation {
  name = "mqtt-explorer-shell";
  buildInputs = [ (pkgs.callPackage ./mqtt-explorer.nix {}) ];
  shellHook = "mqtt-explorer";
}
