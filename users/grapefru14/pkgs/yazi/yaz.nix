{ pkgs, master-pkgs, lib, ... }:
let
  omniconvert-src = pkgs.fetchFromGitHub {
    owner = "skylightlim";
    repo = "omniconvert.yazi";
    rev = "98f255545283c6057235da329147a0dc6880e794";
    hash = "sha256-s6r3vXl1sDkIgLwTatD5l/fHFoL19oeR0NGKMUGpv7k=";
  };
  omni-trash-src = pkgs.fetchFromGitHub {
    owner = "goon";
    repo = "omni-trash.yazi";
    rev = "3c2a9923673e0552a093afc4122473df1d427a93";
    hash = "sha256-heqqEWzJCoNt3CIJAEaWfqUX4J9BfVEw3OsU7Xjc17M=";
  };

  # Tools for omniconvert
  omniconvertDeps = with pkgs; [
    imagemagick
    ffmpeg
    ghostscript
    tesseract  # OCR
  ];

  omniconvert-bin = pkgs.runCommand "omniconvert" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    install -Dm755 ${omniconvert-src}/omniconvert $out/bin/omniconvert
    patchShebangs $out/bin
    wrapProgram $out/bin/omniconvert --prefix PATH : ${lib.makeBinPath omniconvertDeps}
  '';
in {
  programs.yazi = {
    enable = true;
    package = master-pkgs.yazi;
    shellWrapperName = "y";

    extraPackages = [
      omniconvert-bin
      pkgs.trash-cli
    ];

    plugins = {
      inherit (master-pkgs.yaziPlugins) full-border toggle-pane piper;
      omniconvert = omniconvert-src;
      omni-trash  = omni-trash-src;
      # Uses ./folder/main.lua
      bookmarks = ./bookmarks.yazi;
    };

    settings = {
      # mgr.show_hidden = true;
      plugin.prepend_previewers = [
        {
          mime = "image/*";
          run = ''piper -- chafa --format=symbols --colors=full --animate=off --polite=on --size "$w"x"$h" "$1"'';
        }
      ];
    };
    keymap = lib.importTOML ./keymap.toml;
    theme = lib.importTOML ./theme.toml;
    initLua = builtins.readFile ./init.lua;
  };
}
