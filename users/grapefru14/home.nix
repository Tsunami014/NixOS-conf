{ config, pkgs, inputs, ... }: {
  home.username = "grapefru14";
  home.homeDirectory = "/home/grapefru14";
  home.stateVersion = "25.11";

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
  };

  # Allow bluetooth headphones buttons to control media
  services.mpris-proxy.enable = true;

  # Package stuff
  nixpkgs.config.allowUnfree = true;
  imports = [
    ./specialPkgs/browser.nix
  ];

  home.packages = with pkgs; [
    alacritty
    htop
    gh
    lazygit
    cliphist
    wl-clipboard
    fuzzel
    jq

    sioyek

    inputs.hexecute.packages.${system}.default
    # Various apps
    pavucontrol
    gnome-calculator
    (pkgs.callPackage ./extraPkgs/godsvg.nix {})
    ldtk
    krita
    pureref
    (pkgs.callPackage ./extraPkgs/logic2.nix {})

    # Quickshell & quickshell projects
    inputs.qml-niri.packages.${system}.quickshell
    inputs.qml-niri.packages.${system}.default
    acpi
    brightnessctl
    inputs.hyprlock.packages.${system}.default

    # For neovim
    tree-sitter
    unzip
    nodejs
    fd

    # Extra executable stuff
    (pkgs.writeShellApplication {
      name = "navihex";
      text = builtins.readFile ./navihex.sh;
    })
    swww
    (pkgs.writeShellApplication {
      name = "wallppr";
      text = builtins.readFile ./wallppr.sh;
    })
    (pkgs.writeShellApplication {
      name = "tmpplace";
      text = ''yazi "$(mktemp -d)"'';
    })
  ];

  # To find mime type of file: `= file --mime-type -b <filename>`
  # To list global package desktop files: `ls /run/current-system/sw/share/applications`
  # To list local package desktop files: `ls /etc/profiles/per-user/$(id -n -u)/share/applications`
  # To list home manager desktop files: `ls ~/.nix-profile/share/applications`
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "sioyek.desktop";
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
alias downloads="mkdir /tmp/Download 2>/dev/null;cd /tmp/Download"
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

  # Config stuff

  home.file."Pictures/backgrounds" = {
    source = ./backgrounds;
    recursive = true;
  };

  home.file.".local/share/fonts" = {
    source = ./fonts;
    recursive = true;
  };

  home.file."AppIms" = {
    source = ./apps;
    recursive = true;
  };

  home.activation.makeFolders = config.lib.dag.entryAfter [ "writeBoundary" ]
    ''cd "$HOME"; mkdir -p Downloads Documents Pictures Videos'';

  home.activation.cloneNvim = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    PATH=${pkgs.git}/bin:$PATH
    if [ ! -d "$HOME/.config/nvim" ]; then
      echo "Cloning Neovim config repo..."
      mkdir -p "$HOME/.config"
      git clone https://github.com/Tsunami014/nvimConfig "$HOME/.config/nvim"
      echo '{"projects": ["/etc/nixos/users/grapefru14", "/etc/nixos"]}' > "$HOME/.config/nvim/projects.json"
    else
      echo "Updating Neovim config..."
      git -C "$HOME/.config/nvim" pull || true
    fi
  '';
  home.activation.cloneBar = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    PATH=${pkgs.git}/bin:$PATH
    if [ ! -d "$HOME/.config/quickshell/bar" ]; then
      echo "Cloning Bar config repo..."
      mkdir -p "$HOME/.config/quickshell/bar"
      git clone https://github.com/Tsunami014/bar "$HOME/.config/quickshell/bar/"
    else
      echo "Updating Bar config..."
      git -C "$HOME/.config/quickshell/bar" pull || true
    fi
  '';


  # Link the config to the correct places
  home.activation.makeLinks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
  if ! [ -d "$HOME" ]; then
    echo "Home directory does not exist!"
  fi
  mainFold="/etc/nixos/users/$USER/config"
  chmod +rw -R "$mainFold"
  dots="$HOME/.dots"
  mkdir -p "$dots" "$HOME/.config" "$HOME/.local/share"
  while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    read -r mutable prefix name <<< "$line"

    src="$mainFold/$name"
    if [ ! -d "$src" ]; then
      mkdir "$src"
    fi
    if [ "$mutable" = "perm" ]; then
      orig="${./config}/$name"
      prt="Permanent "
    elif [ "$mutable" = "mut" ]; then
      orig="$src"
      prt="Mutable "
    else
      echo "Skipping unknown mutability for '$line': $mutable"
      continue
    fi

    prt+="$name "

    if [ "$prefix" = "conf" ]; then
      link="$HOME/.config"
      prt+="in ~/.config"
    elif [ "$prefix" = "shr" ]; then
      link="$HOME/.local/share"
      prt+="in ~/.local/share"
    else
      echo "Skipping unknown prefix for '$line': $prefix"
      continue
    fi

    printf "%s\e[1m%s\e[0m%s\n" "Linking config for " "$prt" "..."
    if [ -d "$link/$name" ] && [ ! -L "$link/$name" ]; then
      echo "Using existing config..."
      ${pkgs.rsync}/bin/rsync -a --delete "$link/" "$mainFold/$name/"
    fi
    rm -rf "$link/$name"
    ln -sfT "$orig" "$link/$name"
  done < "${./config/list.txt}"
  '';
}
