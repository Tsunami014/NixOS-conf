{ pkgs, lib, inputs, ... }:
{
  home.username = lib.mkForce "secret";
  home.packages = lib.mkAfter (with pkgs; [
    protonvpn-gui
  ]);
  programs.bash.profileExtra = lib.mkAfter ''
    # Also execute niri if on TTY2, then logout when exit
    if [[ -z $DISPLAY && $XDG_VTNR -eq 2 ]]; then
      exec niri
      logout
    fi
  '';
}
