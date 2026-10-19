{ lib, buildFHSEnv, symlinkJoin, makeDesktopItem, slack, slick }:

let
  fhs = buildFHSEnv {
    name = "slick";
    targetPkgs = _: [ slack ];
    runScript = lib.getExe' slick "slick";
  };

  # App-menu entry that also claims slack:// links, so browser sign-in
  # redirects open Slick.
  desktopItem = makeDesktopItem {
    name = "slick";
    desktopName = "Slick";
    comment = "Slack client mod";
    exec = "slick %U";
    categories = [ "Network" "InstantMessaging" ];
    mimeTypes = [ "x-scheme-handler/slack" ];
    startupWMClass = "Slick";
  };
in
symlinkJoin {
  name = "slick";
  paths = [
    fhs
    desktopItem
  ];
  meta = {
    description = "Slick (Slack client mod) in an FHS sandbox with nixpkgs' Slack";
    mainProgram = "slick";
    platforms = [ "x86_64-linux" ];
  };
}
