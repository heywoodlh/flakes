{
  description = "heywoodlh vim config";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, flake-utils, nixpkgs }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      mods = pkgs.callPackage ./settings {};
    in {
      defaultPackage = pkgs.callPackage ./default.nix {
        inherit mods;
      };
    }
  );
}

