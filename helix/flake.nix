{
  description = "Helix editor flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    helix-src.url = "github:helix-editor/helix";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    helix-src,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      myConfig = pkgs.writeText "config.toml" ''
        theme = "base16_transparent"

        [editor.cursor-shape]
        insert = "bar"
        normal = "block"

        [editor.whitespace.render]
        space = "all"
        tab = "all"
        nbsp = "all"
        nnbsp = "all"

        [editor.whitespace.characters]
        space = '·'
        tab = '┆'

        [editor.indent-guides]
        render = true
        character = "┆"
        skip-levels = 1

        [editor.lsp]
        display-inlay-hints = true

        [editor.soft-wrap]
        enable = true

        [editor]
        auto-pairs = false
      '';
      #helixPackage = helix-src.packages.${system}.helix;
      helixPackage = pkgs.helix;
      helixDrv = pkgs.stdenv.mkDerivation {
        name = "helix";
        src = helixPackage;
        installPhase = ''
          mkdir -p $out
          cp -r * $out
          mkdir -p $out/config
          cp ${myConfig} $out/config/config.toml
        '';
      };
    in {
      packages = rec {
        helix = pkgs.writeShellScriptBin "hx" ''
          PATH="${pkgs.nix}/bin:${pkgs.nil}/bin:$PATH"
          ${helixDrv}/bin/hx -c ${helixDrv}/config/config.toml $@
        '';
        helix-config = pkgs.stdenv.mkDerivation {
          name = "config.toml";
          builder = pkgs.bash;
          args = [ "-c" "${pkgs.coreutils}/bin/cp ${myConfig} $out" ];
        };
        helixBin = helixPackage;
        default = helix;
      };

      formatter = pkgs.alejandra;
    });
}
