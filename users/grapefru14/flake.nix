{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qml-niri = {
      url = "github:imiric/qml-niri/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/efdd1e683da9412f515b9bd42c37861978c2fd3a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hexecute = {
      url = "github:ThatOtherAndrew/Hexecute";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprlock = {
      url = "github:Tsunami014/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    slick.url = "github:3kh0/slick";
  };

  outputs = { nixpkgs, nixpkgs-master, nixpkgs-unstable, home-manager, ... } @ inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    master-pkgs = import nixpkgs-master {
      inherit system;
      config.allowUnfree = true;
    };
    unstable-pkgs = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    modules = [
      ./home.nix
    ];
  in {
    homeManagerModules = modules;
    homeModules.grapefru14 = ./home.nix;
    homeConfigurations.grapefru14 = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs master-pkgs unstable-pkgs; };

      modules = modules;
    };
  };
}
