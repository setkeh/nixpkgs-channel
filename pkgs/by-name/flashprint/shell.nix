{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "flashprint-shell";
  buildInputs = [ (pkgs.libsForQt5.callPackage ./package.nix {}) ];
  shellHook = "FlashPrint";
}
