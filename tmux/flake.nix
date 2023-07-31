{
  description = "heywoodlh tmux flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = rec {
        tmux = pkgs.writeShellScriptBin "tmux" ''
            ${pkgs.tmux}/bin/tmux -f ${./tmux.conf} $@
          '';
        default = tmux;
        };
      }
    );
}
