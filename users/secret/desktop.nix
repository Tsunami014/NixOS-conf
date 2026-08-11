{ pkgs, ... }: {
  programs.caelestia = {
    enable = true;
    systemd.enable = false;
    settings = {
      bar.statusIcons = [
        { id = "lockStatus"; enabled = true; }
        { id = "network"; enabled = true; }
        { id = "bluetooth"; enabled = true; }
        { id = "battery"; enabled = false; }
      ];
      paths.wallpaperDir = "/etc/nixos/users/grapefru14/backgrounds/";
    };
    cli = {
      enable = true; # Also add caelestia-cli to path
      settings = {
        theme.enableGtk = false;
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    settings = {
      "$mod" = "SUPER";

      env = [
        "XDG_DATA_HOME,/home/secret/.local/share"
      ];

      "exec-once" = [
        "caelestia shell -d"
        (pkgs.lib.concatStrings [
          "bash -c '"
            "until caelestia shell lock lock 2>/dev/null; do sleep 0.1; done;"
            "wallppr rand;"
            "cp ${./keys.conf} ~/.config/hypr/keys.conf;"
          "'"
        ])
        # Required things to start, *after* caelestia shell
        "dbus-update-activation-environment --systemd --all"
        "systemctl --user start hyprland-session.target"
      ];

      input = {
        touchpad = {
          natural_scroll = true;
        };
      };
      decoration = {
        rounding = 10;
      };

      source = "./keys.conf";
      bind = [
        "$mod_CONTROL_SHIFT, ESCAPE, exit,"
        ''$mod_CONTROL_SHIFT, DELETE, exec, ${pkgs.kitty}/bin/kitty -- sh -c 'close; read -rs -p "\nPress any key"' ''
      ];
    };
  };
}
