{ stdenv, fetchFromGitHub, pkgs, lib }:

stdenv.mkDerivation {
  pname = "wlanthy";
  version = "git-2024-01-01";

  src = fetchFromGitHub {
    owner = "st3r4g";
    repo = "wlanthy";
    rev = "89f2a6a4d0caa9cb7a4d4f3bd37e202aeda457b6";
    sha256 = "sha256-C2Fe3E52wk2Wyj5Y5ASgBQJMxgfl41j/GRbnjHvoNhY=";
  };

  nativeBuildInputs = with pkgs; [
    meson
    ninja
    pkg-config
    cmake
  ];

  buildInputs = with pkgs; [
    wayland
    wayland-protocols
    anthy
    libxkbcommon
    wayland-scanner
  ];

  meta = {
    description = "Wayland-native Japanese input method using Anthy";
    homepage = "https://github.com/st3r4g/wlanthy";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
