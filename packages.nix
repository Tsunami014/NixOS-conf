{ pkgs, ... }:
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    home-manager
    xwayland-satellite
    swayidle
    gcc
    git
    wget
    fzf

    (pkgs.writeShellApplication {
      name = "+";
      text = ''nix-shell -p "$@"'';
    })
    (pkgs.writeShellApplication {
      name = "=";
      text = ''nix-shell -p "$1" --run "$*"'';
    })
    (pkgs.writeShellApplication {
      name = "upd-system";
      text = builtins.readFile ./upd-all.sh;
    })
    (pkgs.writeShellApplication {
      name = "upd-user";
      text = ''
fprint() { printf "\e[1;93m%s\e[0m\n" "$1"; }
fprint "Syncing..."
syncf=$HOME/.config/home-manager/sync.sh
if [ -f "$syncf" ]; then
  cd "$(dirname "$syncf")"
  "$syncf"
fi
fprint "Updating git..."
git add .
fprint "Running rebuild..."
home-manager switch
'';
    })
    (pkgs.writeShellApplication {
      name = "upd-system-garbage";
      text = ''
sudo -v
printf "\e[1;93m%s\e[0m\n" "Collecting garbage..."
sudo nix-collect-garbage -d
upd-system
'';
    })
  ];

  system.activationScripts.text = ''
ln -sf ${pkgs.bash}/bin/bash /bin/bash
ln -sf ${./navi.sh} /bin/navi
'';

  fonts.packages = with pkgs; [
    nerd-fonts.ubuntu
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
