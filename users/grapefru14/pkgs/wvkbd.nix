{ config, pkgs, ... }:
let
  wl-uinput-proxy = pkgs.rustPlatform.buildRustPackage rec {
    pname = "wl-uinput-proxy";
    version = "0.0.4";
    src = pkgs.fetchFromGitHub {
      owner = "pgaskin";
      repo = "wl-uinput-proxy";
      rev = "v${version}";
      hash = "sha256-coJrAYecrRE25Ao+/NFTwuE6yRLlYCbloJ5WJJq/GJk=";
    };
    cargoHash = "sha256-Gtxz99gotvz9LI0mt3L7VUF4W/l6LPs6bvtta4Fs8CY=";
  };

in

pkgs.wvkbd.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  postFixup = (old.postFixup or "") + ''
    mv $out/bin/wvkbd-mobintl $out/bin/.wvkbd-mobintl-unwrapped
    makeWrapper ${wl-uinput-proxy}/bin/wl-uinput-proxy $out/bin/wvkbd-mobintl \
      --add-flags "$out/bin/.wvkbd-mobintl-unwrapped"
  '';
})
