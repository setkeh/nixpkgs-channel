let
  pkgs = import <nixpkgs> {};
in
pkgs.stdenv.mkDerivation {
  name = "flashprint-shell";
  buildInputs = [ (pkgs.libsForQt5.callPackage ./default.nix {}) ];
  shellHook = "FlashPrint";
}
