{
  description = "heywoodlh 1password helper scripts";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      op-unlock = pkgs.writeShellScriptBin "op-unlock" ''
        env | grep -iq OP_SESSION || eval $(${pkgs._1password}/bin/op signin) && export OP_SESSION
        echo "export OP_SESSION=$OP_SESSION"
      '';
      op-wrapper = pkgs.writeShellScriptBin "op-wrapper.sh" ''
        ${op-unlock}/bin/op-unlock | grep -v export
        ${pkgs._1password}/bin/op "$@"
      '';
    in {
      packages = rec {
        op = pkgs.writeShellScriptBin "op" ''
          ${op-wrapper}/bin/op-wrapper.sh "$@"
        '';
        default = op;
        };
      }
    );
}
