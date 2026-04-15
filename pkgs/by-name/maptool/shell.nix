let
  pkgs = import <nixpkgs> {};
in
pkgs.stdenv.mkDerivation {
  name = "MapTool-shell";
  buildInputs = [ (pkgs.callPackage ./MapTool.nix {}) ];
  shellHook = "maptool";
}
