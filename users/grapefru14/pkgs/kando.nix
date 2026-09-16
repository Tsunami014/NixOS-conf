{ pkgs, fetchFromGitHub, fetchNpmDeps, ... }:
let
  kandoSrc = fetchFromGitHub {
    owner = "kando-menu";
    repo = "kando";
    rev = "v2.3.1";
    hash = "sha256-vmdDcXpSm2O9MkOGfM3+VUrRSvUot1GB0TkxjNSN4r8=";
  };

in
  pkgs.kando.overrideAttrs (old: {
    src = kandoSrc;
    npmDeps = fetchNpmDeps {
      src = kandoSrc;
      hash = "sha256-2J74igNLl5CwXm9WtHzxqTVt7+S113qcioxJja6uUOE=";
    };
  })
