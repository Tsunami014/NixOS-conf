{ full }:
{ config, pkgs, lib, ... }: {
  programs.neovim = {
    enable = true;
    sideloadInitLua = true;
    withRuby = false;
    withPython3 = true;
    extraPackages = with pkgs; [
      tree-sitter
      unzip
      nodejs
      fd
      ripgrep
    ] ++ lib.optionals full [
      # For compiling/running things
      texlivePackages.texfot # Better outputs
      pandoc
      (python313.withPackages (ps: with ps; [ debugpy ]))

      # For lsps and stuff
      clang-tools
      gdb
      pyright
      ruff
    ];
  };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
alias copy=wl-copy
alias paste=wl-paste
alias downloads='mkdir /tmp/"Download-$USER" 2>/dev/null;cd /tmp/"Download-$USER"'
alias mktmpplace='cd "$(mktemp -d)";bash'
'';
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "Tsunami014";
        email = "tsunami014@duck.com";
      };
      init.defaultBranch = "main";
    };
  };
  # So setting global git config sets onto this writable empty file, not the unwritable git config defined above
  home.activation.makeGitConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    touch "$HOME/.gitconfig"
  '';
}
