{
  description = "heywoodlh vim config";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    fish-configs.url = "../fish";
  };
  outputs = { self, flake-utils, fish-configs, nixpkgs }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      myFish = fish-configs.packages.${system}.fish;
      mods = pkgs.callPackage ./settings { inherit myFish; };
    in {
      defaultPackage = pkgs.callPackage ./default.nix {
        inherit mods;
      };
    }
  );
}
