{ config, pkgs, ... }:

let
  mkuser = usrname: {
    isNormalUser = true;
    description = usrname;
    extraGroups = [ "networkmanager" "wheel" "config" "dialout" "input" ];
    packages = with pkgs; [];
  };
  autologin = user: {
    overrideStrategy = "asDropin";
    serviceConfig.ExecStart = [
      ""
      "${pkgs.util-linux}/sbin/agetty --autologin ${user} --noclear %I $TERM"
    ];
  };
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./packages.nix
      ./userConfig.nix
    ];

  # Ensure /tmp works normally
  boot.tmp.cleanOnBoot = true;
  boot.tmp.useTmpfs = true;

  programs.appimage = { # Execute appimages normally
    enable = true;
    binfmt = true;
  };
  programs.nix-ld.enable = true; # Be able to execute programs normally

  # Add /bin to the path
  environment.sessionVariables = {
    PATH = [ "/bin" ];
  };

  # Disable handling of the power button
  services.logind.settings.Login.HandlePowerKey = "ignore";

  # Add groups to user
  users.groups.config = {};
  # Define user accounts. Don't forget to set a password with 'sudo passwd username'.
  users.users.grapefru14 = mkuser "Grapefru14";
  users.users.secret = mkuser "Secret";
  # Add config access to root
  users.users.root = {
    extraGroups = [ "config" ];
  };

  # Auto logins
  systemd.services."getty@tty1" = autologin "grapefru14";
  systemd.services."getty@tty2" = autologin "secret";

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true; # bluetooth gui

  # Sound settings
  security.rtkit.enable = true; # Enable RealtimeKit for audio purposes

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Input remapping service
  services.input-remapper.enable = true;
  services.input-remapper.enableUdevRules = true;

  # Rotation sensor
  hardware.sensor.iio.enable = true;

  # Enable printing
  services.printing.enable = true;
  services.avahi = { # Printer discovery
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.printing.drivers = [ pkgs.canon-cups-ufr2 ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.extraEntries = {
    "ubuntu.conf" = ''
title Ubuntu
efi /EFI/ubuntu/grubx64.efi
    '';
  };

  # Enable networking
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; } # KDE Connect
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; } # KDE Connect
    ];
  };

  networking.hostName = "grapey"; # Define your hostname.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "au";
    variant = "";
  };

  # The desktop environment stuff
  programs.niri.enable = true;
  security.polkit.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  # Misc nix stuff
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Misc other stuff
  programs.fuse.userAllowOther = true;
  hardware.graphics.enable = true;

  # Fix udev sometimes freaking out
#   services.udev.extraRules = ''
#     SUBSYSTEM=="power_supply", KERNEL=="BAT1", ACTION=="change", OPTIONS+="ignore_device"
#   '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11";
}
