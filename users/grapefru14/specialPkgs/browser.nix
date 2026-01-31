{ config, pkgs, inputs, ... }: {
  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

  programs.zen-browser.enable = true;
  programs.zen-browser.profiles.default = {
    id = 0;
    name = "default";
    isDefault = true;

    extensions.packages =
     with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          ublock-origin
          auto-tab-discard
        ];
    mods = [
        "906c6915-5677-48ff-9bfc-096a02a72379" # Floating status bar
        "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
        "a6335949-4465-4b71-926c-4a52d34bc9c0" # Better find bar
        "cb5efa80-f1e1-43ce-8c0b-fece8462d225" # Container halo
        "cb15abdb-0514-4e09-8ce5-722cf1f4a20f" # Hide Extension Name
      ];

    settings = {
        "zen.workspaces.continue-where-left-off" = true;
        "zen.welcome-screen.seen" = true;
        "zen.urlbar.behavior" = "floating-on-type";
        "zen.view.experimental-no-window-controls" = true;
        "zen.view.compact.enable-at-startup" = true;
        "layout.css.prefers-color-scheme.content-override" = 0;
        "zen.view.window.scheme" = 0;
        "browser.download.folderList" = 2;
        "browser.download.dir" = "/tmp/Download";
        "browser.download.useDownloadDir" = true;
    };
  };

  xdg.mimeApps =
    let
      associations = builtins.listToAttrs (map
        (name: {
          inherit name;
          value = "zen-twilight.desktop";
        }) [
        "application/x-extension-shtml"
        "application/x-extension-xhtml"
        "application/x-extension-html"
        "application/x-extension-xht"
        "application/x-extension-htm"
        "x-scheme-handler/unknown"
        "x-scheme-handler/mailto"
        "x-scheme-handler/chrome"
        "x-scheme-handler/about"
        "x-scheme-handler/https"
        "x-scheme-handler/http"
        "application/xhtml+xml"
        "application/json"
        "text/html"
      ]);
    in {
      enable = true;
      associations.added = associations;
      defaultApplications = associations;
    };
}
