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
        # Various good things
        "zen.workspaces.continue-where-left-off" = true;
        "zen.welcome-screen.seen" = true;
        # Dark theme
        "layout.css.prefers-color-scheme.content-override" = 0;
        "zen.view.window.scheme" = 0;
        # Download to /tmp/Download
        "browser.download.folderList" = 2;
        "browser.download.dir" = "/tmp/Download";
        "browser.download.useDownloadDir" = true;
        # The window layout
        "zen.urlbar.behavior" = "floating-on-type";
        "zen.view.experimental-no-window-controls" = true;

        "zen.view.use-single-toolbar" = false;
        "zen.view.compact.enable-at-startup" = true;

        "browser.uiCustomization.state" = builtins.replaceStrings ["\n"] [""] ''

{"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["_testpilot-containers-browser-action","ublock0_raymondhill_net-browser-action","_c2c003ee-bd69-42a2-b0e9-6f34222cb046_-browser-action","clearcache_michel_de_almeida-browser-action","jid1-zadieub7xozojw_jetpack-browser-action","griffpatch_griffpatch_co_uk-browser-action","_d07ccf11-c0cd-4938-a265-2a4d6ad01189_-browser-action","_45f2dc53-96cd-4c41-91f6-f4a73a8fb2b0_-browser-action","simple-translate_sienori-browser-action","jid1-ggfz35hbowtefa_jetpack-browser-action","_c45c406e-ab73-11d8-be73-000a95be3b12_-browser-action","jid0-dsq67mf5kjjhiiju2dfb6kk8dfw_jetpack-browser-action"],"nav-bar":["customizableui-special-spring16","back-button","forward-button","vertical-spacer","urlbar-container","stop-reload-button","unified-extensions-button","customizableui-special-spring2"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs"],"vertical-tabs":[],"PersonalToolbar":["import-button","personal-bookmarks"],"zen-sidebar-top-buttons":["zen-toggle-compact-mode","customizableui-special-spring12"],"zen-sidebar-foot-buttons":["downloads-button","zen-workspaces-button","zen-create-new-button"]},"seen":["developer-button","screenshot-button","_c2c003ee-bd69-42a2-b0e9-6f34222cb046_-browser-action","clearcache_michel_de_almeida-browser-action","ublock0_raymondhill_net-browser-action","jid1-zadieub7xozojw_jetpack-browser-action","griffpatch_griffpatch_co_uk-browser-action","_d07ccf11-c0cd-4938-a265-2a4d6ad01189_-browser-action","_45f2dc53-96cd-4c41-91f6-f4a73a8fb2b0_-browser-action","simple-translate_sienori-browser-action","_testpilot-containers-browser-action","jid1-ggfz35hbowtefa_jetpack-browser-action","_c45c406e-ab73-11d8-be73-000a95be3b12_-browser-action","jid0-dsq67mf5kjjhiiju2dfb6kk8dfw_jetpack-browser-action"],"dirtyAreaCache":["nav-bar","vertical-tabs","zen-sidebar-foot-buttons","unified-extensions-area","toolbar-menubar","TabsToolbar","PersonalToolbar","zen-sidebar-top-buttons","widget-overflow-fixed-list"],"currentVersion":23,"newElementCount":16}

'';
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
