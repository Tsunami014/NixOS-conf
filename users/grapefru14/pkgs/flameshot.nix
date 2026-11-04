{ flameshot, grim, writeShellScriptBin }:

let
  grimLogical = writeShellScriptBin "grim" ''
    exec ${grim}/bin/grim -s 1 "$@"
  '';
in
flameshot.override {
  enableWlrSupport = true;
  grim = grimLogical;
}
