{ pkgs, lib, inputs, ... }:
{
  home.username = lib.mkForce "secret";
  home.packages = lib.mkAfter (with pkgs; [
    protonvpn-gui
    mullvad-vpn
    tor-browser
  ]);
  programs.bash.profileExtra = lib.mkAfter ''
    # Also execute niri if on TTY2, then logout when exit
    if [[ -z $DISPLAY && $XDG_VTNR -eq 2 ]]; then
      exec niri
      logout
    fi
  '';

  programs.zen-browser.profiles.default = {
    settings = lib.mkAfter {
      "browser.newtabpage.enabled" = false;
      "privacy.clearOnShutdown_v2.cache" = true;
      "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
      "privacy.clearOnShutdown.cache" = true;
      "privacy.clearOnShutdown.cookies" = true;
      "privacy.sanitize.sanitizeOnShutdown" = true;
    };
    extensions.packages = lib.mkAfter (
      with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
        firemonkey
      ]);
  };
}
