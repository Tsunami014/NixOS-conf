{ stdenv, pkgs, lib, fetchurl, unzip, autoPatchelfHook }:

let
  pname = "godsvg";
  version = "v1.0-alpha15";

  libs = with pkgs; [
    wayland
    libxkbcommon
    mesa
    libGL
  ];
in stdenv.mkDerivation rec {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/MewPurPur/GodSVG/releases/download/${version}/GodSVG_${version}.Linux.x86_64.zip";
    sha256 = "sha256-DtEeWSLD/rwrXNUQqW/7xFw9VHo76B7mN7uubcEWbqo=";
  };

  nativeBuildInputs = [
    unzip
    pkgs.makeWrapper
    autoPatchelfHook
  ];

  unpackPhase = "unzip -q $src -d .";
  installPhase = ''
    mkdir -p $out/bin
    install -m755 GodSVG_${version}.x86_64 $out/bin/godsvg
    wrapProgram $out/bin/godsvg \
      --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath libs}
  '';

  meta = {
    description = "GodSVG — structured SVG editor built with Godot (wrapped prebuilt release)";
    homepage = "https://github.com/MewPurPur/GodSVG";
    changelog = "https://github.com/MewPurPur/GodSVG/releases";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ Tsunami014 ];
    platforms = lib.platforms.linux;
    mainProgram = "godsvg";
  };
}
