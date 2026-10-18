{ config, pkgs, ... }:
let
  state  = "${config.home.homeDirectory}/.local/state/theme";
  python = pkgs.python3.withPackages (ps: [ ps.pillow ]);

  theme-set-variant = pkgs.writeShellApplication {
    name = "theme-set-variant";
    runtimeInputs = [ pkgs.coreutils pkgs.procps ];
    text = ''
      n="''${1:?variant 1|2}"
      mkdir -p ${state}/current
      for f in ${state}/v"$n"/*; do
        cat "$f" > "${state}/current/$(basename "$f")"
      done
      echo "$n" > ${state}/variant
      pkill -USR1 kitty || true
    '';
  };

  theme-apply = pkgs.writeShellApplication {
    name = "theme-apply";
    runtimeInputs = [ pkgs.coreutils theme-set-variant ];
    text = ''
      mkdir -p ${state}
      ${python}/bin/python ${./programs/theme-gen.py} ${state} ${./templates}
      theme-set-variant "$(cat ${state}/variant 2>/dev/null || echo 1)"
    '';
  };
in {
  home.packages = [ theme-apply theme-set-variant ];
}
