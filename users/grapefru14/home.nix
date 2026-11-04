{ config, pkgs, master-pkgs, unstable-pkgs, lib, inputs, ... }: {
  home.username = "grapefru14";
  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = "25.11";

  nixpkgs.config.allowUnfree = true;

  # Allow bluetooth headphones buttons to control media
  services.mpris-proxy.enable = true;

  imports = [
    ./config.nix
    ./theme.nix
    (import ./base.nix { full = true; })

    ./pkgs/yazi/yaz.nix
    ./pkgs/browser.nix
    ./pkgs/wlogout.nix
    ./pkgs/opencode.nix
  ];

  # Package stuff
  home.packages = with pkgs; [
    alacritty
    gh
    imagemagick
    exiftool
    sqlite
    chafa
    ripdrag
    zip

    # Background apps
    wakatime-cli

    # Games
    prismlauncher # Minecraft
    (olympus.override { celesteWrapper = "steam-run"; })

    inputs.hexecute.packages.${system}.default
    # Various apps
    obs-cmd # Actual OBS can be lazily loaded
    gnome-calculator
    krita
    arduino-ide
    pdfarranger
    wl-color-picker
    opencode
    # Apps I needed to make myself for one reason or another
    (pkgs.callPackage ./pkgs/kando.nix {})
    (pkgs.callPackage ./pkgs/godsvg.nix {})
    (pkgs.callPackage ./pkgs/wlanthy.nix {})
    (pkgs.callPackage ./pkgs/roland.nix {})
    (pkgs.callPackage ./pkgs/wvkbd.nix {})
    (pkgs.callPackage ./pkgs/grayjay.nix {})
    (pkgs.callPackage ./pkgs/flameshot.nix {})
    (pkgs.callPackage ./pkgs/slick.nix {
      slick = inputs.slick.packages.${pkgs.stdenv.hostPlatform.system}.slick;
    })
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
    wtype

    # Extra executable stuff
    (pkgs.callPackage ./pkgs/profile.nix {})
    (pkgs.callPackage ./pkgs/Documents.nix { inherit (pkgs) python3Packages; })
    (pkgs.writeScriptBin "navihex" ''
      #!${pkgs.python313.withPackages (ps: with ps; [ tkinter ])}/bin/python3
      ${builtins.readFile ./programs/navihex.py}
    '')
    (pkgs.writeScriptBin "weather-daemon" ''
      #!${pkgs.python313}/bin/python3
      ${builtins.readFile ./programs/weather.py}
    '')
    (pkgs.writeShellApplication {
      name = "printer-settings";
      text = "zen --private-window http://localhost:631";
    })
    (pkgs.writeShellApplication {
      name = "obs-scene-pick";
      text = ''
CFG=~/.config/obs-studio
PASS=$(jq -r .server_password "$CFG/plugin_config/obs-websocket/config.json")

scene=$(jq -r '.scene_order[].name' "$CFG"/basic/scenes/*.json \
  | fuzzel --dmenu -p 'Scene: ')
[ -n "$scene" ] && obs-cmd -w "obsws://localhost:4455/$PASS" scene switch "$scene"
'';
    })
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
      name = "namefiles";
      text = ''# shellcheck disable=SC2016
echo \
'i=0; for f in *.png; do [ -f "$f" ] || continue; printf -v n "file%02d.%s" "$i" "''${f##*.}"; mv -- "$f" "$n"; ((i++)); done'
'';
    })
    (pkgs.writeShellApplication {
      name = "wallppr";
      text = builtins.readFile ./programs/wallppr.sh;
    })
    (pkgs.writeShellApplication {
      name = "anims";
      text = builtins.readFile ./programs/anims.sh;
    })
    # Wrappers
    (pkgs.writeShellApplication {
      name = "jap";
      text = ''
echo "F5 for hiragana, F6 for katakana
Space or up/down to choose, enter to commit, backspace to undo
F12 to toggle on/off, though not recommended for long"
wlanthy
'';
    })
    (pkgs.writeShellApplication {
      name = "lock";
      text = ''
pidof -q hyprlock && exit 0
hyprlock
wallppr rand
anims rand
'';
    })
    # Lazily loaded programs
    (pkgs.writeScriptBin "py" ''
      ${pkgs.python313.withPackages (ps: with ps; [ pyperclip numpy requests ])}/bin/python3 "$@"
    '')
    (pkgs.writeScriptBin "zed" ''nix-shell --log-format bar-with-logs -p zed-editor --run "zeditor $@"'')
    (pkgs.writeScriptBin "baobab" ''nix-shell --log-format bar-with-logs -p baobab --run "baobab $@"'')
    (pkgs.writeScriptBin "protonvpn" ''nix-shell -p protonvpn-gui --run "protonvpn-app $@"'')
  ];

  home.sessionVariables = {
    QS_ICON_THEME = "Papirus"; # Use the correct icon theme
    NIXOS_OZONE_WL = "1"; # Force wayland for some apps
  };

  # To find mime type of file: `= file --mime-type -b <filename>`
  # To list global package desktop files: `ls /run/current-system/sw/share/applications`
  # To list local package desktop files: `ls /etc/profiles/per-user/$(id -n -u)/share/applications`
  # To list home manager desktop files: `ls ~/.nix-profile/share/applications`
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "sioyek.desktop";
      "image/png"  = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/jpg"  = "imv.desktop";
      "image/gif"  = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp"  = "imv.desktop";
      "image/tiff" = "imv.desktop";
    };
  };

  services.ollama = {
    enable = true;
    package = unstable-pkgs.ollama;
    environmentVariables = {
      OLLAMA_NUM_THREADS = "6";
      OLLAMA_NUM_THREAD = "6";
      OLLAMA_CONTEXT_LENGTH = "4096";
    };
  };

  services.kdeconnect.enable = true;

  services.cliphist = {
    enable = true;
    systemdTargets = [ "config.wayland.systemd.target" ];
  };

  programs.imv = {
    enable = true;
    settings = {
      options = {
        overlay = true;
        overlay_font = "Monospace:8";
        overlay_position_bottom = true;
        overlay_text = "[$imv_current_index/$imv_file_count]  \${imv_width}x\${imv_height}  $imv_current_file";
      };
      binds = {
        a = "zoom actual; rotate to 0";
        "<F1>" = "exec ${./extra/imv_help.sh} &";
      };
    };
  };

  programs.bash.initExtra  = ''
__c() { printf '\001\e[%sm\002' "$1"; } # Colour
__g() { printf ' \001\e[1D%s\002' "$1"; } # Glyph
__host='\h'
[ -n "$IN_NIX_SHELL" ] && __host='nix-shell'

PS1="\
$(__c '32')$(__g '')\
$(__c '30;42') \u@''${__host} \
$(__c '32;43')$(__g '')\
$(__c '30;43')\$(git branch --show-current 2>/dev/null | sed 's/^/ $(__g '')/;s/$/ /')\
$(__c '33;100')$(__g '')\
$(__c '35') \w \$\
$(__c '0;90')$(__g '')\
$(__c '0') "

unset __host -f __c __g
export NIX_SHELL_PRESERVE_PROMPT=1
'';

  programs.bash.profileExtra = ''
if [[ -z $NIRI_LAUNCHED ]]; then
  if [[ $XDG_VTNR == 1 ]]; then
    export NIRI_LAUNCHED=1
    export XDG_SESSION_TYPE=wayland
    exec niri-session
  elif [[ -n $XDG_VTNR && -t 0 && -t 1 ]]; then
    read -n 1 -p "Launch Niri? (y/n): " response
    echo
    if [[ "$response" =~ ^[Yy]$ ]]; then
      export NIRI_LAUNCHED=1
      export XDG_SESSION_TYPE=wayland
      exec niri --session
    fi
  fi
fi
'';
}
