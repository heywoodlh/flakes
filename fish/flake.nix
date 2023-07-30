{
  description = "heywoodlh fish flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = rec {
        fish = pkgs.writeShellScriptBin "fish" ''
            ${pkgs.fish}/bin/fish --init-command="source ${./profile.fish}" $@
          '';
        default = fish;
        };
      }
    );
}
