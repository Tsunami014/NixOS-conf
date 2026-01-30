{ stdenv, pkgs, lib, fetchurl, unzip, autoPatchelfHook }:

let
  libs = with pkgs; [
    wayland
    libxkbcommon

    mesa
    libGL
    vulkan-loader
    libdrm

    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libXext
  ];
in stdenv.mkDerivation rec {
  pname = "godsvg";
  version = "v1.0-alpha13";

  src = fetchurl {
    url = "https://github.com/MewPurPur/GodSVG/releases/download/${version}/GodSVG.Linux.zip";
    sha256 = "sha256-fgzuirSIKF9h7wEj0TLypXdf+pr50VkyqGR0BXyvM+s=";
  };

  nativeBuildInputs = [
    unzip
    pkgs.makeWrapper
    autoPatchelfHook
  ];

  unpackPhase = "unzip -q $src -d .";
  installPhase = ''
    mkdir -p $out/bin
    install -m755 GodSVG.x86_64 $out/bin/godsvg
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
