{ pkgs, ... }:
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    gcc
    git
    wget
    fzf
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
