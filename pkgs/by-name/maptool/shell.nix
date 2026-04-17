{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "MapTool-shell";
  buildInputs = [ (pkgs.callPackage ./package.nix {}) ];
  shellHook = "maptool";
}
