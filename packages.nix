{ pkgs, ... }:
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    gcc
    git
    wget
    alacritty
    fuzzel
    mako
    swayidle
    swaylock
  ];

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
