{ lib, stdenv, fetchzip, steam-run, nss, nspr }:

stdenv.mkDerivation {
  name = "grayjay";

  src = fetchzip {
    url = "https://updater.grayjay.app/Apps/Grayjay.Desktop/Grayjay.Desktop-linux-x64.zip";
    hash = "sha256-C9Vscjgjfq//z4bOS/rjPAIyFJvFz6WzKp0mycFFbc8=";
  };

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out/share/grayjay $out/bin
    cp -r ./* $out/share/grayjay/
    chmod +x $out/share/grayjay/Grayjay

    cat > $out/bin/grayjay <<EOF
    #!${stdenv.shell}
    src=$out/share/grayjay
    dst="\$HOME/.local/share/grayjay"

    if [ "\$(cat "\$dst/.store-path" 2>/dev/null)" != "\$src" ]; then
      mkdir -p "\$dst"
      cp -rf --no-preserve=ownership "\$src"/. "\$dst"/
      chmod -R u+w "\$dst"
      echo "\$src" > "\$dst/.store-path"
    fi

    cd "\$dst"
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ nss nspr ]}:\$dst/cef:\$dst\''${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
    exec ${steam-run}/bin/steam-run ./Grayjay "\$@"
    EOF
    chmod +x $out/bin/grayjay
  '';

  meta = {
    description = "Grayjay Desktop";
    homepage = "https://grayjay.app/desktop/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "grayjay";
  };
}
