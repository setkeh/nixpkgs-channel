{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  webkitgtk_4_1,
  gtk3,
  glib-networking,
  libsoup_3,
  ...
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "brows3";
  version = "0.2.46";

  # Upstream builds with Tauri and publishes a .deb that links against the
  # system webkitgtk/gtk (unlike the AppImage, which bundles its own), so we
  # repackage it against the nixpkgs ones instead of building the whole
  # Rust + pnpm/Next.js toolchain from source.
  src = fetchurl {
    url = "https://github.com/rgcsekaraa/brows3/releases/download/app-v${finalAttrs.version}/Brows3_${finalAttrs.version}_amd64.deb";
    hash = "sha256-vm9aWHfokUvAHfcE6DIIKjdCXR02SV6f5QVPED8jNCA=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  # autoPatchelfHook resolves the binary's DT_NEEDED against these.
  # glib-networking isn't linked, but webkit needs its GIO TLS module for any
  # https:// load in the webview; wrapGAppsHook3 puts it on GIO_EXTRA_MODULES.
  buildInputs = [
    stdenv.cc.cc.lib
    webkitgtk_4_1
    gtk3
    libsoup_3
    glib-networking
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 usr/bin/brows3 $out/bin/brows3
    install -Dm644 usr/share/applications/Brows3.desktop $out/share/applications/brows3.desktop

    # Tauri also emits a non-standard 'hicolor/256x256@2' dir; 512x512 already
    # covers that size, so only install the ones the icon theme spec knows.
    for size in 32x32 128x128 512x512; do
      install -Dm644 usr/share/icons/hicolor/$size/apps/brows3.png \
        $out/share/icons/hicolor/$size/apps/brows3.png
    done

    runHook postInstall
  '';

  meta = {
    description = "Fast S3 browser and desktop client for Amazon S3 and S3-compatible storage";
    longDescription = ''
      Brows3 is an S3 browser for AWS S3 and S3-compatible object storage
      (MinIO, Cloudflare R2, Wasabi, DigitalOcean Spaces, custom endpoints).

      Credentials are stored via the freedesktop Secret Service, so a provider
      such as gnome-keyring or KWallet must be running. The built-in updater
      cannot replace a /nix/store install; update by bumping this package.
    '';
    homepage = "https://www.brows3.app/";
    changelog = "https://github.com/rgcsekaraa/brows3/releases/tag/app-v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "brows3";
    maintainers = with lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
