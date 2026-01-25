{ stdenv, pkgs, lib, fetchurl, autoPatchelfHook, unzip }:

stdenv.mkDerivation rec {
  pname = "godsvg";
  version = "v1.0-alpha13";

  src = fetchurl {
    url = "https://github.com/MewPurPur/GodSVG/releases/download/${version}/GodSVG.Linux.zip";
    sha256 = "sha256-fgzuirSIKF9h7wEj0TLypXdf+pr50VkyqGR0BXyvM+s=";
  };

  nativeBuildInputs = [ autoPatchelfHook unzip ];
  buildInputs = with pkgs; [
    xorg.libX11
    xorg.libX11.dev
    xorg.libxcb
    
    libGLU
    libX11
    libXcursor
    libXext
    libXfixes
    libXi
    libXinerama
    libXrandr
    libXrender
    libglvnd
    libpulseaudio

    wayland
    libxkbcommon

    mesa
  ];

  unpackPhase = ''
    mkdir -p $TMPDIR/src
    unzip -q $src -d $TMPDIR/src
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp "$TMPDIR/src/GodSVG.x86_64" $out/bin/godsvg
    chmod +x $out/bin/godsvg
    runHook postInstall
  '';

  meta = {
    description = "GodSVG — structured SVG editor built with Godot (wrapped prebuilt release)";
    homepage = "https://github.com/MewPurPur/GodSVG";
    changelog = "https://github.com/MewPurPur/GodSVG/releases";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [
      Tsunami014
    ];
    platforms = lib.platforms.linux;
    mainProgram = "godsvg";
  };
}
