{
  description = "Zen Browser Flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.zen-browser.url = "github:MarceColl/zen-browser-flake";

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      zen-browser,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zenBrowser = if pkgs.stdenv.system == "x86_64-linux" then zen-browser.packages.${system}.default 
        else pkgs.callPackage ./zen.nix {};
        # zenBin is only used if system is not x86_64-linux
        zenBin = if pkgs.stdenv.isDarwin then "${zenBrowser}/bin/zen"
        else "${pkgs.blink}/bin/blink -L /tmp/blink-zen.log ${zenBrowser}/zen/zen";
        zenWrapper = pkgs.writeShellScriptBin "zen" ''
          mkdir -p $HOME/Documents/zen/Profiles/main
          ${zenBin} --profile $HOME/Documents/zen/Profiles/main $@
        '';
      in
      {
        packages = rec {
          zen-wrapper = zenWrapper;
          zen-browser = zenBrowser;
          default = if pkgs.stdenv.system == "x86_64-linux" then zen-browser else zen-wrapper;
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
