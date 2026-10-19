{ config, pkgs, ... }:
let
  state  = "${config.home.homeDirectory}/.local/state/theme";
  python = pkgs.python3.withPackages (ps: [ ps.pillow ]);

  upd-theme-variant = pkgs.writeShellApplication {
    name = "upd-theme-variant";
    runtimeInputs = [ pkgs.coreutils pkgs.procps ];
    text = ''
      n="''${1:?variant 1|2}"
      mkdir -p ${state}/current
      for f in ${state}/v"$n"/*; do
        cat "$f" > "${state}/current/$(basename "$f")"
      done
      echo "$n" > ${state}/variant
    '';
  };

  upd-theme = pkgs.writeShellApplication {
    name = "upd-theme";
    runtimeInputs = [ pkgs.coreutils upd-theme-variant ];
    text = ''
      mkdir -p ${state}
      ${python}/bin/python ${./programs/theme-gen.py} ${state} ${./templates}
      upd-theme-variant "$(cat ${state}/variant 2>/dev/null || echo 1)"
    '';
  };
in {
  home.packages = [ upd-theme upd-theme-variant ];
}
