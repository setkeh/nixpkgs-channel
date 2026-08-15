{ lib, stdenv, fetchurl, glibc, libX11, runtimeShell, libGLU, libGL }:

stdenv.mkDerivation rec {
  name = "tibia";

  src = fetchurl {
    url = "https://static.tibia.com/download/tibia.x64.tar.gz";
    sha256 = "11mkh2dynmbpay51yfaxm5dmcys3rnpk579s9ypfkhblsrchbkhx";
    curlOptsList = [
      "--user-agent" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
    ];
  };

  shell = stdenv.shell;

  # These binaries come stripped already and trying to strip after the
  # files are in $out/res and after patchelf just breaks them.
  # Strangely it works if the files are in $out but then nix doesn't
  # put them in our PATH. We set all the files to $out/res because
  # we'll be using a wrapper to start the program which will go into
  # $out/bin.
  dontStrip = true;

  installPhase = ''
    mkdir -pv $out/res
    cp -r * $out/res
    patchelf --set-interpreter ${glibc.out}/lib/ld-linux.so.2 \
             --set-rpath ${lib.makeLibraryPath [ stdenv.cc.cc libX11 libGLU libGL ]} \
             "$out/res/Tibia"
    # We've patchelf'd the files. The main ‘Tibia’ binary is a bit
    # dumb so it looks for ‘./Tibia.dat’. This requires us to be in
    # the same directory as the file itself but that's very tedious,
    # especially with nix which changes store hashes. Here we generate
    # a simple wrapper that we put in $out/bin which will do the
    # directory changing for us.
    mkdir -pv $out/bin
    # The wrapper script itself. We use $LD_LIBRARY_PATH for libGL.
    cat << EOF > "$out/bin/Tibia"
    #!${runtimeShell}
    cd $out/res
    ${glibc.out}/lib/ld-linux.so.2 --library-path \$LD_LIBRARY_PATH ./Tibia "\$@"
    EOF
    chmod +x $out/bin/Tibia
  '';

  meta = {
    description = "Top-down MMORPG set in a fantasy world";
    homepage = "http://tibia.com";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
    maintainers = with lib.maintainers; [ ];
  };
}
