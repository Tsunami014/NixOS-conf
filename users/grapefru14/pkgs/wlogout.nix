{ pkgs, ... }:
{
  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "niri msg action quit";
        text = "Exit";
        keybind = "E";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "s";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "S";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "R";
      }
    ];

    style = ''    
* {
	background-image: none;
	box-shadow: none;
}

window {
	background-color: rgba(26, 27, 38, 0.9);
}

button {
    border-radius: 0;
    border-color: #C0CAF5;
	font-size: 1.3em;
	text-decoration-color: #CFC9C2;
    color: #FFFFFF;
	background-color: #414868;
	border-style: solid;
	border-width: 1px;
	background-repeat: no-repeat;
	background-position: center;
	background-size: 25%;
}

button:focus, button:active, button:hover {
	background-color: #6A82E7;
	outline-style: none;
}

#lock {
	border-top-left-radius: 50px;
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"), url("${pkgs.wlogout}/local/share/wlogout/icons/lock.png"));
}
#logout {
	border-bottom-left-radius: 50px;
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"), url("${pkgs.wlogout}/local/share/wlogout/icons/logout.png"));
}
#suspend {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"), url("${pkgs.wlogout}/local/share/wlogout/icons/suspend.png"));
}
#shutdown {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"), url("${pkgs.wlogout}/local/share/wlogout/icons/shutdown.png"));
}
#hibernate {
	border-top-right-radius: 50px;
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"), url("${pkgs.wlogout}/local/share/wlogout/icons/hibernate.png"));
}
#reboot {
	border-bottom-right-radius: 50px;
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"), url("${pkgs.wlogout}/local/share/wlogout/icons/reboot.png"));
}
'';
  };
}
