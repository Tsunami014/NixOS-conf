{ pkgs, lib, inputs, ... }: {
  programs.yazi = {
    enable = true;

    plugins = {
      inherit (pkgs.yaziPlugins) full-border bookmarks toggle-pane;
      "copy-quote" = ./copy-quote.yazi;
    };

    settings = lib.importTOML ./settings.toml;
    keymap = lib.importTOML ./keymap.toml;
    theme = lib.importTOML ./theme.toml;
    initLua = builtins.readFile ./init.lua;
  };
}
