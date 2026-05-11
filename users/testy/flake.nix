{
  inputs = {
    grapefru14.url = "../grapefru14";
  };
  outputs = inputs: let
    system = "x86_64-linux";
    grapefru14 = inputs.grapefru14;
    uinputs = grapefru14.inputs;
    pkgs = import uinputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    master-pkgs = import uinputs.nixpkgs-master {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    homeConfigurations.testy = uinputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = grapefru14.homeManagerModules ++ [
        ./home.nix
      ];
      extraSpecialArgs = { inputs = uinputs; inherit master-pkgs; };
    };
  };
}
