{ pkgs, lib, rustPlatform, fetchFromGitHub, pkg-config }:

rustPlatform.buildRustPackage rec {
  pname = "roland";
  version = "unstable-main";

  src = fetchFromGitHub {
    owner = "oknozor";
    repo = "roland";
    rev = "main";
    sha256 = "sha256-wQCxgd2UavxWHKY4C3dZG/pRrLxSTDRajVgsO2E9GQM=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  doCheck = false; # The checks require config

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ pkgs.systemd pkgs.libinput ];

  meta = {
    description = "Touch gesture recognizer";
    homepage = "https://github.com/oknozor/roland";
    license = lib.licenses.mit;
  };
}
