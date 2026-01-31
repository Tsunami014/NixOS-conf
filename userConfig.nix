# The yucky user config that couldn't fit within the user's space
{ pkgs, services, ... }: {
  # Bring the udev rules from the logic analyzer software
  services.udev.packages = [
    (pkgs.callPackage ./users/grapefru14/extraPkgs/logic2.nix {})
  ];
}
