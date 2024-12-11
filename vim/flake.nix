{
  description = "heywoodlh vim config";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, flake-utils, nixpkgs, }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      mods = pkgs.callPackage ./settings {};
      myVim = pkgs.callPackage ./default.nix {
        inherit mods;
      };
    in {
      packages = rec {
        # bulkier wrapper including languages
        vimWrapper = pkgs.writeShellScriptBin "vim" ''
          export PATH="${pkgs.go}/bin:${pkgs.python3}/bin:$PATH"
          ${myVim}/bin/vim "$@"
        '';
        vim = myVim;
        default = vimWrapper;
      };
    }
  );
}
