{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, writeShellScript
, buildFHSEnv
, makeDesktopItem
, imagemagick
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
, openssl
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
      cp -rL "$TIBIA_PKG"/. "$prefix"/
      chmod -R u+rwX "$prefix"
      printf '%s' "$TIBIA_PKG" > "$stamp"
    fi
    cd "$prefix"
    exec ./Tibia "$@"
  '';

  desktopItem = makeDesktopItem {
    name = "tibia";
    exec = "tibia";
    icon = "tibia";
    desktopName = "Tibia";
    genericName = "MMORPG";
    comment = "Top-down MMORPG set in a fantasy world";
    categories = [ "Game" "RolePlaying" ];
    keywords = [ "mmo" "mmorpg" "rpg" "cipsoft" ];
    # If the window doesn't group with this launcher in your dock, check the
    # real value with `xprop WM_CLASS` on the running client -- the visible
    # window comes from the downloaded 'client' binary, not from 'Tibia'.
    startupWMClass = "Tibia";
  };

  unwrapped = stdenv.mkDerivation (finalAttrs: {
  pname = "tibia-unwrapped";
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
  dontWrapQtApps = true;

  # These binaries come stripped already and stripping again after patchelf
  # just breaks them.
  dontStrip = true;
  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    html2text
    imagemagick
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
  #runtimeDependencies = [ openssl vulkan-loader ];
  appendRunpaths = [
    "${lib.getLib openssl}/lib"
    "${lib.getLib vulkan-loader}/lib"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/tibia
    cp -r . $out/share/tibia/

    html2text ${finalAttrs.agreement} > LICENSE
    install -Dm644 LICENSE $out/share/licenses/tibia/LICENSE

    mkdir -p icons
      magick tibia.ico icons/frame.png
      largest=$(ls -S icons/*.png | head -n1)
      for size in 16 24 32 48 64 128 256; do
        mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
        magick "$largest" -resize "''${size}x''${size}" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/tibia.png"
      done

    makeWrapper ${launcher} $out/bin/tibia \
      --set TIBIA_PKG $out/share/tibia

    runHook postInstall
  '';
  meta.mainProgram = "tibia";
  });

  fhsTargetPkgs = pkgs: (with pkgs; [
    # Core runtime
    stdenv.cc.cc.lib
    zlib
    zstd
    brotli
    openssl
    dbus
    glib
    expat
    libxml2
    icu
    nss
    nspr

    # Graphics
    libGL
    libGLU
    vulkan-loader
    libdrm
    pciutils # libpci, probed by some GL stacks

    # Image codecs used by Qt's imageformats plugins
    libpng
    libjpeg
    libwebp
    libtiff

    # Text shaping / fonts
    fontconfig
    freetype
    harfbuzz
    graphite2
    # MS fonts, the nixpkgs equivalent of the AUR's ttf-ms-fonts dependency.
    # Unfree: needs nixpkgs.config.allowUnfree or an allowUnfreePredicate.
    corefonts
    dejavu_fonts

    # X11 / xcb -- the downloaded client brings its own Qt, which needs the
    # whole xcb platform stack present under /usr/lib.
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXi
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXtst
    xorg.libxcb
    xorg.libICE
    xorg.libSM
    xorg.xcbutil
    xorg.xcbutilwm
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilcursor
    libxkbcommon

    # Wayland (the client will use xcb via XWayland if these are absent)
    wayland

    # Audio
    alsa-lib
    libpulseaudio
  ]) ++ [ unwrapped ];
in

buildFHSEnv {
  name = "tibia";

  targetPkgs = fhsTargetPkgs;

  runScript = "${unwrapped}/bin/tibia";

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/*.desktop $out/share/applications/
    cp -r ${unwrapped}/share/icons $out/share/
  '';

  passthru = {
    inherit unwrapped;

    # `nix run .#tibia.fhsShell` drops you into an interactive shell inside the
    # exact same sandbox. Use it to enumerate what the runtime-downloaded
    # client is missing, all at once:
    #
    #   ldd "$HOME/.local/share/CipSoft GmbH/Tibia/packages/Tibia/bin/client" \
    #     | grep 'not found'
    #
    # then map each soname to a package with `nix-locate --top-level <soname>`
    # and add it to fhsTargetPkgs above. Beats one rebuild per missing library.
    fhsShell = buildFHSEnv {
      name = "tibia-fhs-shell";
      targetPkgs = fhsTargetPkgs;
      runScript = "bash";
    };
  };

  meta = {
    description = "Top-down MMORPG set in a fantasy world";
    homepage = "https://www.tibia.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "tibia";
    maintainers = with lib.maintainers; [ ];
  };
}