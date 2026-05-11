{ pkgs, lib, inputs, ... }:

{
  home.username = lib.mkForce "testy";
  programs.zen-browser.profiles.default.extensions.packages = lib.mkForce (
    with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
    [
      ublock-origin
      auto-tab-discard
      duckduckgo-privacy-essentials
      web-archives
      temporary-containers
      numatrix
      multi-account-containers
      video-downloadhelper
    ]
  );
}
