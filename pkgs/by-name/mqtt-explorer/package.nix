{ stdenv, lib, fetchurl, appimageTools, electron_8, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "MQTT-Explorer";
  version = "0.4.0-beta1";
  src = appimageTools.extract {
    name = pname;
    src = fetchurl {
      url = "https://github.com/thomasnordquist/${pname}/releases/download/0.0.0-${version}/${pname}-${version}.AppImage";
      sha256 = "0x9ava13hn1nkk2kllh5ldi4b3hgmgwahk08sq48yljilgda4ppn";
    };
  };
  buildInputs = [ makeWrapper ];
  installPhase = ''
    install -m 444 -D resources/app.asar $out/libexec/app.asar
    install -m 444 -D mqtt-explorer.png $out/share/icons/mqtt-explorer.png
    install -m 444 -D mqtt-explorer.desktop $out/share/applications/mqtt-explorer.desktop
    makeWrapper ${electron_8}/bin/electron $out/bin/mqtt-explorer --add-flags $out/libexec/app.asar
  '';
  meta = with lib; {
    description = "A comprehensive and easy-to-use MQTT Client";
    homepage = "https://mqtt-explorer.com/";
    license = # TODO: make licenses.cc-by-nd-40
      { free = false; fullName = "Creative Commons Attribution-No Derivative Works v4.00"; shortName = "cc-by-nd-40"; spdxId = "CC-BY-ND-4.0"; url = "https://spdx.org/licenses/CC-BY-ND-4.0.html"; };
    maintainers = [ maintainers.yorickvp ];
    inherit (electron_8.meta) platforms;
  };
}
