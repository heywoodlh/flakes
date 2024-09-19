{
  description = "heywoodlh vim config";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.helix-vim = {
    url = "github:chtenb/helix.vim";
    flake = false;
  };
  outputs = { self, flake-utils, nixpkgs, helix-vim, }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      mods = pkgs.callPackage ./settings { inherit helix-vim; };
    in {
      defaultPackage = pkgs.callPackage ./default.nix {
        inherit mods;
      };
    }
  );
}
