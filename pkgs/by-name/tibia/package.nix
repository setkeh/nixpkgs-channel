{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, writeShellScript
, html2text
, qt6
, libGL
, libGLU
, xorg
, pcre
, pcre2
, zlib
, libxkbcommon
, fontconfig
, freetype
, dbus
, vulkan-loader
}:

let
  tibiaUrl = "https://static.tibia.com/download/tibia.x64.tar.gz";

  # static.tibia.com sits behind a WAF that rejects bare curl. 
  # We work around this with,
  # Accept-Encoding + a self-referer.
  curlOpts = [
    "--compressed"
    "--referer"
    tibiaUrl
    "--user-agent"
    "curl/8.9.1"
  ];

  # The Tibia client self-updates by writing into its own install directory.
  # The /nix/store is read-only, so seed a writable copy under
  # $XDG_DATA_HOME on first run and re-seed whenever the store path changes.
  #
  # Tibia binary is a bit dumb and looks for './Tibia.dat', so it must be
  # started with cwd set to its own directory.
  launcher = writeShellScript "tibia-launcher" ''
    set -eu
    prefix="''${XDG_DATA_HOME:-$HOME/.local/share}/tibia"
    stamp="$prefix/.nix-revision"
    if [ ! -e "$stamp" ] || [ "$(cat "$stamp")" != "$TIBIA_PKG" ]; then
      mkdir -p "$prefix"
      cp -rL --no-preserve=mode,ownership "$TIBIA_PKG"/. "$prefix"/
      chmod -R u+w "$prefix"
      printf '%s' "$TIBIA_PKG" > "$stamp"
    fi
    cd "$prefix"
    exec ./Tibia "$@"
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "tibia";
  version = "14.0.0";

  src = fetchurl {
    url = tibiaUrl;
    hash = "sha256-BKh8gB04VfTaGwfiAd/x95rMhSjFfJhBMcOiqIy2Dqc=";
    curlOptsList = curlOpts;
  };

  # Package LICENSE by running the agreement page through html2text.
  agreement = fetchurl {
    url = "https://www.tibia.com/support/agreement.php";
    hash = "sha256-8rkVXJeredGwqbG2b8RVZ06eZTF3i5pATqcisAxIBK4=";
    curlOptsList = curlOpts;
  };

  # The tarball has a single top-level 'Tibia/' directory, which stdenv would
  # cd into automatically -- stated explicitly so a repack with extra
  # top-level entries fails loudly instead of silently changing layout.
  sourceRoot = "Tibia";

  # These binaries come stripped already and stripping again after patchelf
  # just breaks them.
  dontStrip = true;
  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    html2text
    qt6.wrapQtAppsHook
  ];

  # autoPatchelfHook reads DT_NEEDED off the binaries and resolves against
  # these, so there is no hand-maintained --set-rpath list to fall out of date
  # (and no chance of naming the wrong dynamic linker -- it takes the
  # interpreter from stdenv, which is correct per-platform).
  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    libGL
    libGLU
    xorg.libX11
    xorg.libXext
    xorg.libICE
    xorg.libSM
    pcre
    pcre2
    qt6.qtbase
    qt6.qtwayland
    libxkbcommon
    fontconfig
    freetype
    dbus
  ];

  # dlopen'd at runtime rather than listed in DT_NEEDED, so autoPatchelfHook
  # cannot discover it on its own.
  # optdepends=('vulkan-driver: for Vulkan rendering').
  runtimeDependencies = [ vulkan-loader ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/tibia
    cp -r . $out/share/tibia/

    html2text ${finalAttrs.agreement} > LICENSE
    install -Dm644 LICENSE $out/share/licenses/tibia/LICENSE

    makeWrapper ${launcher} $out/bin/tibia \
      --set TIBIA_PKG $out/share/tibia

    runHook postInstall
  '';

  meta = {
    description = "Top-down MMORPG set in a fantasy world";
    homepage = "https://www.tibia.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "tibia";
    maintainers = with lib.maintainers; [ ];
  };
})