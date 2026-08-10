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
        "bash -c 'until caelestia shell lock lock 2>/dev/null; do sleep 0.1; done; wallppr rand'"
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

      bind = [
        "$mod_CONTROL_SHIFT, ESCAPE, exit,"
        "$mod, SPACE, global, caelestia:launcher"
        "$mod, RETURN, exec, ${pkgs.kitty}/bin/kitty"
        "$mod, L, exec, ${pkgs.kitty}/bin/kitty linkfile"
        "$mod, APOSTROPHE, exec, ${pkgs.kitty}/bin/kitty yazi"
        "$mod, V, exec, cliphist-fuzzel-img"
        "$mod, Q, killactive,"
        "$mod, X, togglefloating,"

        # Move focus
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod_SHIFT, 1, movetoworkspace, 1"
        "$mod_SHIFT, 2, movetoworkspace, 2"
        "$mod_SHIFT, 3, movetoworkspace, 3"
        "$mod_SHIFT, 4, movetoworkspace, 4"
        "$mod_SHIFT, 5, movetoworkspace, 5"
      ];
    };
  };
}
