{
  description = "heywoodlh wezterm flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = rec {
          wezterm = pkgs.writeShellScriptBin "wezterm" ''
            ${pkgs.wezterm}/bin/wezterm --config-file ${./wezterm.lua}
          '';
          default = wezterm;
        };
      }
    );
}
