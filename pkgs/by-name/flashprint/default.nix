{ stdenv, lib, fetchurl, dpkg
, alsaLib, atk, cairo, cups, curl, dbus, expat, fontconfig, freetype, glib, glibc
, qtbase, qttools, wrapQtAppsHook, libnotify, libpulseaudio, libsecret, libv4l, nspr, nss, pango, systemd, wrapGAppsHook, xorg
, at-spi2-atk, libGLU }:

let

  rpath = lib.makeLibraryPath [
    alsaLib
    atk
    at-spi2-atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    glib
    glibc
    libsecret

    qtbase
    qttools

    libnotify
    libpulseaudio
    nspr
    nss
    pango
    stdenv.cc.cc
    systemd
    libv4l

    libGLU

    xorg.libxkbfile
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXScrnSaver
    xorg.libxcb
  ] + ":${stdenv.cc.cc.lib}/lib64";

  mirror = "https://en.fss.flashforge.com/10000/software";

in stdenv.mkDerivation rec {

  name = "FlashPrint5";
  fname = "073e21bbe6ba5c7defb17dbb69708fd8";
  #version = "5.2.0"; #Not currently used in code but good refrence

  src =
  if stdenv.hostPlatform.system == "x86_64-linux" then
    fetchurl {
      url = "${mirror}/${fname}.deb";
      sha256 = "0s9js5q1shfn5x4m0c1v16pvanr8c86w92lb0p39asyi7vbqlbdf";
    }
  else
    throw "FlashPrint for linux is not supported on ${stdenv.hostPlatform.system}";

  nativeBuildInputs = [
    wrapQtAppsHook
    wrapGAppsHook
    glib # For setup hook populating GSETTINGS_SCHEMA_PATH
    libGLU
  ];

  buildInputs = [ dpkg libGLU ];

  unpackPhase = "true";
  installPhase = ''
    mkdir -p $out
    mkdir -p $out/bin
    dpkg -x $src $out
    ln -s "$out/usr/share/${name}/FlashPrint" "$out/bin/FlashPrint"
    # Otherwise it looks "suspicious"
    chmod -R g-w $out
  '';

  postFixup = ''
    for file in $(find $out -type f \( -perm /0111 -o -name \*.so\* -or -name \*.node\* \) ); do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$file" || true
      patchelf --set-rpath ${rpath}:$out/share/${name} $file || true
    done
    # Fix the desktop link
    substituteInPlace $out/usr/share/applications/${name}.desktop \
      --replace /usr/bin/ $out/bin/
  '';


  meta = with lib; {
    homepage = "https://www.flashforge.com";
    description = "Flashprint 3D Print Slicer";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfree;
  };
}
