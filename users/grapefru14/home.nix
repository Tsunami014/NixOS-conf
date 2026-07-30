{ config, pkgs, master-pkgs, lib, inputs, ... }: {
  home.username = "grapefru14";
  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = "25.11";

  nixpkgs.config.allowUnfree = true;

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
  };

  # Allow bluetooth headphones buttons to control media
  services.mpris-proxy.enable = true;

  imports = [
    ./config.nix

    ./pkgs/yazi/yaz.nix
    ./pkgs/browser.nix
    ./pkgs/wlogout.nix
  ];

  # Package stuff
  home.packages = with pkgs; [
    alacritty
    htop
    gh
    lazygit
    cliphist
    wl-clipboard
    fuzzel
    jq
    imagemagick
    exiftool
    sqlite

    # File viewers
    sioyek
    swayimg

    # Background apps
    wakatime-cli

    inputs.hexecute.packages.${system}.default
    # Various apps
    pavucontrol
    gnome-calculator
    krita
    ollama
    arduino-ide
    wl-color-picker
    # Apps I needed to make myself for one reason or another
    (pkgs.callPackage ./pkgs/godsvg.nix {})
    (pkgs.callPackage ./pkgs/wlanthy.nix {})
    (pkgs.callPackage ./pkgs/roland.nix {})
    # Apps I'm version-conscious for
    ldtk
    master-pkgs.aseprite
    master-pkgs.saleae-logic-2
    master-pkgs.pureref

    # Quickshell & quickshell projects
    inputs.qml-niri.packages.${system}.quickshell
    inputs.qml-niri.packages.${system}.default
    acpi
    brightnessctl
    inputs.hyprlock.packages.${system}.default
    wvkbd
    wtype

    # Extra executable stuff
    (pkgs.callPackage ./pkgs/profile.nix {})
    (pkgs.callPackage ./pkgs/Documents.nix { inherit (pkgs) python3Packages; })
    (pkgs.writeScriptBin "navihex" ''
      #!${pkgs.python313.withPackages (ps: with ps; [ tkinter ])}/bin/python3
      ${builtins.readFile ./programs/navihex.py}
    '')
    (pkgs.writeShellApplication {
      name = "fixbar";
      text = ''
pkill quickshell || true
quickshell -c bar &
bg
disown
'';
    })
    swww
    (pkgs.writeShellApplication {
      name = "wallppr";
      text = builtins.readFile ./programs/wallppr.sh;
    })
    (pkgs.writeShellApplication {
      name = "linkfile";
      text = ''
mkdir -p /tmp/Link
chmod 0775 /tmp/Link 2&>/dev/null || true
nvim /tmp/Link/"$USER".md -c 'cd /tmp/Link|exe "Neotree"|wincmd w'
'';
    })
    # A wrapper for wlanthy (above) with instructions
    (pkgs.writeShellApplication {
      name = "jap";
      text = ''
echo "F5 for hiragana, F6 for katakana
Space or up/down to choose, enter to commit, backspace to undo
F12 to toggle on/off, though not recommended for long"
wlanthy
'';
    })
    # Lazily loaded programs
    (pkgs.writeScriptBin "py" ''
      ${pkgs.python313.withPackages (ps: with ps; [ pyperclip numpy requests ])}/bin/python3
    '')
    (pkgs.writeScriptBin "zed" ''nix-shell -p zed-editor --run "zeditor $@"'')
    (pkgs.writeScriptBin "obs" ''nix-shell -p obs-studio --run "obs $@"'')
    (pkgs.writeScriptBin "baobab" ''nix-shell -p baobab --run "baobab $@"'')
  ];

  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      tree-sitter
      unzip
      nodejs
      fd
      ripgrep
      texlivePackages.texfot # Better outputs
      (texlive.combine {
        inherit (texlive) scheme-full;
      })
      pandoc
      (python313.withPackages (ps: with ps; [ debugpy ]))

      # For lsps and stuff
      clang-tools
      gdb
      pyright
      ruff
    ];
  };


  # To find mime type of file: `= file --mime-type -b <filename>`
  # To list global package desktop files: `ls /run/current-system/sw/share/applications`
  # To list local package desktop files: `ls /etc/profiles/per-user/$(id -n -u)/share/applications`
  # To list home manager desktop files: `ls ~/.nix-profile/share/applications`
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "sioyek.desktop";
      "image/png"  = "swayimg.desktop";
      "image/jpeg" = "swayimg.desktop";
      "image/jpg"  = "swayimg.desktop";
      "image/gif"  = "swayimg.desktop";
      "image/webp" = "swayimg.desktop";
      "image/bmp"  = "swayimg.desktop";
      "image/tiff" = "swayimg.desktop";
    };
  };

  services.kdeconnect.enable = true;

  services.cliphist = {
    enable = true;
    systemdTargets = [ "config.wayland.systemd.target" ];
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
alias copy=wl-copy
alias paste=wl-paste
alias downloads="mkdir /tmp/Download 2>/dev/null;cd /tmp/Download"
alias mktmpplace='cd "$(mktemp -d)";bash'
'';
    profileExtra = ''
[[ -f ~/.bashrc ]] && . ~/.bashrc
# Only exec Niri if no display is running and you're on TTY1
if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    exec niri
fi'';
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
