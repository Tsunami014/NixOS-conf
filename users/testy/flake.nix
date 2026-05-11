{
  inputs.grapefru14.url = "../grapefru14";

  outputs = { self, grapefru14, ... }:
  let
    base = grapefru14.outputs;
  in
  {
    homeConfigurations.testy =
      base.homeConfigurations.grapefru14.extendModules {
        modules = [
          ./home.nix
        ];
      };
  };
}
