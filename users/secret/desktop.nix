{ pkgs, ... }: {
  programs.caelestia = {
    enable = true;
    systemd.enable = false;
    settings = {
      bar.statusIcons = [
        { id = "lockStatus"; enabled = true; }
        { id = "network"; enabled = true; }
        { id = "bluetooth"; enabled = true; }
        { id = "battery"; enabled = true; }
      ];

      # Don't be able to scroll for volume control
      bar.scrollActions.volume = false;

      # Change active window display
      bar.activeWindow.compact = true;
      bar.activeWindow.showOnHover = false;

      launcher.vimKeybinds = true;

      # Default apps
      general.apps.terminal = [ "kitty" ];
      general.apps.explorer = [ "kitty yazi" ];
      #general.apps.playback = [ ];
      #general.apps.audio = [ ];

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

      monitor = [
        "eDP-1,preferred,auto,1.3333334"
      ];

      "exec-once" = [
        "caelestia shell -d"
        (pkgs.lib.concatStrings [
          "bash -c '"
            "until caelestia shell lock lock 2>/dev/null; do sleep 0.1; done;"
            ''cp ${./keys.conf} "$HOME/.config/hypr/keys.conf";''
            "wallppr rand"
          "'"
        ])
        "iio-hyprland &"
        # Setup cliphist
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        # Required things to start, *after* caelestia shell
        "dbus-update-activation-environment --systemd --all"
        "systemctl --user start hyprland-session.target"
      ];

      input = {
        touchpad = {
          natural_scroll = true;
          disable_while_typing = false;
        };
      };
      decoration = {
        rounding = 10;
      };
      animations = {
        enabled = true;
        # Increase speed of some animations
        bezier = "fastShot, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "workspaces, 1, 5, fastShot, slide"
          "windows, 1, 6, fastShot, slide"
        ];
      };

      gesture = [
        "3, horizontal, workspace, scale: 0.1"
      ];

      source = "$HOME/.config/hypr/keys.conf";
      bind = [
        "$mod_CONTROL_SHIFT, ESCAPE, exit,"
        ''$mod_CONTROL_SHIFT, DELETE, exec, ${pkgs.kitty}/bin/kitty -- sh -c 'close; echo;read -rs -p "Press any key"' ''
      ];

      xwayland.force_zero_scaling = true;

      misc = {
        disable_hyprland_logo = true;
        background_color = "rgb(111111)";
        mouse_move_enables_dpms = true;
      };
    };
  };
}
