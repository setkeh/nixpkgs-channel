{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  ...
}@args:

let
  pname = "suiup";
  version = "0.0.13";

  src = fetchurl {
    url = "https://github.com/MystenLabs/suiup/releases/download/v${version}/suiup-Linux-musl-x86_64.tar.gz";
    # Leave empty initially. Run `nix run nixpkgs#nix-prefetch-url -- <URL>` to generate the proper SRI hash.
    hash = "0z7y6a0jgf7g0rk79zf0yhzdr02jndw7k4a8lkrw4h4bq16h5cgp"; 
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  # autoPatchelfHook runs during the fixupPhase to patch the interpreter and RPATHs
  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    # Provide the dynamic libraries the binary expects to link against here.
    # Common examples include: stdenv.cc.cc.lib, zlib
  ];

  # Tarballs from GitHub releases often extract loosely rather than into a single top-level directory.
  # Setting sourceRoot to "." ensures the build phase doesn't fail looking for a directory.
  sourceRoot = ".";

  # We skip the buildPhase since this is a pre-compiled binary
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Create the bin directory and install the binary
    install -Dm755 suiup $out/bin/suiup

    runHook postInstall
  '';

  meta = {
    description = "Suiup is a tool for managing Sui development environments";
    homepage = "https://sui.io/";
    license = lib.licenses.mit;
    mainProgram = "suiup";
    maintainers = with lib.maintainers; [ crertel ];
    platforms = [ "x86_64-linux" ];
  };
}