{ pkgs, fetchFromGitHub, fetchNpmDeps, lib, ... }:
let
  kandoSrc = fetchFromGitHub {
    owner = "kando-menu";
    repo = "kando";
    rev = "v3.0.0";
    hash = "sha256-UBah/yWcGGyrZpSmahYO4mdYuaP3WQ2PnoZ1gfgWSZk=";
  };

in
  pkgs.kando.overrideAttrs (old: {
    src = kandoSrc;
    npmDeps = fetchNpmDeps {
      src = kandoSrc;
      # hash = lib.fakeHash;
      hash = "sha256-OUtUYSOjxBi8RPswGUTQKpt86ovW3k+qffcCxW2N9xw=";
    };
  })
