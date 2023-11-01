{
  description = "heywoodlh vim config";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    fish-flake.url = "github:heywoodlh/flakes?dir=fish";
  };
  outputs = { self, flake-utils, fish-flake, nixpkgs }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      myFish = fish-flake.packages.${system}.fish;
      mods = pkgs.callPackage ./settings { inherit myFish; };
    in {
      defaultPackage = pkgs.callPackage ./default.nix {
        inherit mods;
      };
    }
  );
}
