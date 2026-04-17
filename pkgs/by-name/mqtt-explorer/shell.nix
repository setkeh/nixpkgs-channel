{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "mqtt-explorer-shell";
  buildInputs = [ (pkgs.callPackage ./package.nix {}) ];
  shellHook = "mqtt-explorer";
}
