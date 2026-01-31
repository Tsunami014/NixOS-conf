# The yucky user config that couldn't fit within the user's space
{ master-pkgs, services, ... }: {
  # Bring the udev rules from the logic analyzer software
  services.udev.packages = [
    master-pkgs.saleae-logic-2
  ];
}
