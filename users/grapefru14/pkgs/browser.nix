{ config, pkgs, inputs, lib, ... }: {
  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

  # https://github.com/0xc000022070/zen-browser-flake/tree/efdd1e683da9412f515b9bd42c37861978c2fd3a
  programs.zen-browser.enable = true;
  programs.zen-browser.policies = {
    AutofillAddressEnabled = true;
    AutofillCreditCardEnabled = false;
    DisableAppUpdate = true;
    DisableFeedbackCommands = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableTelemetry = true;
    DontCheckDefaultBrowser = true;
    NoDefaultBookmarks = true;
    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      Fingerprinting = true;
    };
  };
  programs.zen-browser.profiles.default = {
    id = 0;
    name = "default";
    isDefault = true;

    extensions.packages =
     with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
        duckduckgo-privacy-essentials
        multi-account-containers
        temporary-containers
        auto-tab-discard
        ublock-origin
        web-archives
        numatrix
        # Yes, this is the ONLY way.
        (video-downloadhelper.overrideAttrs (_: {
          meta = video-downloadhelper.meta // {
            license = pkgs.lib.licenses.free;
          };
        }))
      ];
    mods = [
        "906c6915-5677-48ff-9bfc-096a02a72379" # Floating status bar
        "c01d3e22-1cee-45c1-a25e-53c0f180eea8" # Ghost tabs
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
        # Devtools
        "devtools.accessibility.enabled" = false;
        "devtools.dom.enabled" = true;
        "devtools.inspector.showUserAgentStyles" = true;
        "devtools.toolbox.host" = "right"; # Put devtools on right
        # The window layout
        "zen.urlbar.behavior" = "floating-on-type";
        "zen.view.experimental-no-window-controls" = true;

        "zen.view.use-single-toolbar" = false;
        "zen.view.compact.enable-at-startup" = true;

        "sidebar.position_start" = false; # Put the sidebar on the right
        "browser.uiCustomization.state" = builtins.replaceStrings ["\n"] [""] ''

{"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["_testpilot-containers-browser-action","ublock0_raymondhill_net-browser-action","_c2c003ee-bd69-42a2-b0e9-6f34222cb046_-browser-action","clearcache_michel_de_almeida-browser-action","jid1-zadieub7xozojw_jetpack-browser-action","griffpatch_griffpatch_co_uk-browser-action","_d07ccf11-c0cd-4938-a265-2a4d6ad01189_-browser-action","_45f2dc53-96cd-4c41-91f6-f4a73a8fb2b0_-browser-action","simple-translate_sienori-browser-action","jid1-ggfz35hbowtefa_jetpack-browser-action","_c45c406e-ab73-11d8-be73-000a95be3b12_-browser-action","jid0-dsq67mf5kjjhiiju2dfb6kk8dfw_jetpack-browser-action","_9efa0613-820d-4f74-8876-11ac0c17244e_-browser-action","_b457d19f-fbad-4782-9cc0-6b62bd27beb4_-browser-action","side-view_mozilla_org-browser-action","_2b38cb05-9cff-44a7-b9f1-7cc575afab8a_-browser-action","_c57c5b60-bb54-4e19-9d45-1240bba3c95f_-browser-action"],"nav-bar":["_c607c8df-14a7-4f28-894f-29e8722976af_-browser-action","customizableui-special-spring16","back-button","forward-button","vertical-spacer","stop-reload-button","urlbar-container","numatrix_arek_codes-browser-action","unified-extensions-button","customizableui-special-spring2","umatrix_raymondhill_net-browser-action","sidebar-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs"],"vertical-tabs":[],"PersonalToolbar":["personal-bookmarks"],"zen-sidebar-top-buttons":["zen-toggle-compact-mode","tab-array_menhera_org-browser-action","downloads-button"],"zen-sidebar-foot-buttons":["zen-workspaces-button","zen-create-new-button"]},"seen":["developer-button","screenshot-button","_c2c003ee-bd69-42a2-b0e9-6f34222cb046_-browser-action","clearcache_michel_de_almeida-browser-action","ublock0_raymondhill_net-browser-action","jid1-zadieub7xozojw_jetpack-browser-action","griffpatch_griffpatch_co_uk-browser-action","_d07ccf11-c0cd-4938-a265-2a4d6ad01189_-browser-action","_45f2dc53-96cd-4c41-91f6-f4a73a8fb2b0_-browser-action","simple-translate_sienori-browser-action","_testpilot-containers-browser-action","jid1-ggfz35hbowtefa_jetpack-browser-action","_c45c406e-ab73-11d8-be73-000a95be3b12_-browser-action","jid0-dsq67mf5kjjhiiju2dfb6kk8dfw_jetpack-browser-action","umatrix_raymondhill_net-browser-action","numatrix_arek_codes-browser-action","_9efa0613-820d-4f74-8876-11ac0c17244e_-browser-action","_b457d19f-fbad-4782-9cc0-6b62bd27beb4_-browser-action","side-view_mozilla_org-browser-action","_2b38cb05-9cff-44a7-b9f1-7cc575afab8a_-browser-action","_c57c5b60-bb54-4e19-9d45-1240bba3c95f_-browser-action","tab-array_menhera_org-browser-action","_c607c8df-14a7-4f28-894f-29e8722976af_-browser-action"],"dirtyAreaCache":["nav-bar","vertical-tabs","zen-sidebar-foot-buttons","unified-extensions-area","toolbar-menubar","TabsToolbar","PersonalToolbar","zen-sidebar-top-buttons","widget-overflow-fixed-list"],"currentVersion":23,"newElementCount":28}

'';
    };

    search = {
      force = true;
      default = "google";
    };

    keyboardShortcuts = [
      {
        id = "new_temporary_container_tab";
        key = "t";
        modifiers = {
          alt = true;
        };
      }
    ];
    keyboardShortcutsVersion = 14;
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
