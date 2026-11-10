{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, nixpkgs-master, nixpkgs-unstable, ... }: let
    system = "x86_64-linux";
    master-pkgs = import nixpkgs-master {
      inherit system;
      config.allowUnfree = true;
    };
    unstable-pkgs = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.grapey = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ./configuration.nix ];
      specialArgs = { inherit master-pkgs unstable-pkgs; };
    };
  };
}
