let
  nixpkgs = import <nixpkgs> {};
in

{ stdenv ? nixpkgs.stdenv, fetchurl ? nixpkgs.fetchurl, makeWrapper ? nixpkgs.makeWrapper, jdk ? nixpkgs.jdk}:

nixpkgs.stdenv.mkDerivation rec {
  name = "MapTool";

  #version = "1.10.4";
  #shasum = "17gkfar8fr8jqsp93vqps7hssag0gjwbj5b0l24spp9zq86dkh03";
  version = "1.10.3";
  shasum = "1yyrjmyqfwqr2zz7ry76ab9kpbbmymagp8cy26zcgaidip2x6las";
  #version = "1.8.5";
  #shasum = "1z99anpbzdzx3wm93v1rkiphhcs5hsr4jv5dnqsmgps79jjblqm4";


  src = fetchurl {
    url = "https://github.com/RPTools/maptool/releases/download/${version}/MapTool-${version}.jar";
    sha256 = "${shasum}";
  };

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
  mkdir -pv $out/share/java $out/bin
  cp ${src} $out/share/java/MapTool-${version}.jar
  makeWrapper ${jdk}/bin/java $out/bin/maptool \
    --add-flags "-jar $out/share/java/MapTool-${version}.jar" \
    --set _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on' \
    --set _JAVA_AWT_WM_NONREPARENTING 1
  '';
}
