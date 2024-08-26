{
  description = "Zen Browser Flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zenBrowser = pkgs.callPackage ./zen.nix {};
        zenWrapper = pkgs.writeShellScriptBin "zen" ''
          mkdir -p $HOME/Documents/zen/Profiles/main
          ${zenBrowser}/bin/zen --profile $HOME/Documents/zen/Profiles/main
        '';
      in
      {
        packages = rec {
          zen-wrapper = zenWrapper;
          zen-browser = zenBrowser;
          default = zen-wrapper;
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
