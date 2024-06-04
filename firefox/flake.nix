{
  description = "heywoodlh tmux flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixos-configs.url = "github:heywoodlh/nixos-configs";

  outputs = { self, nixpkgs, flake-utils, nixos-configs, }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      heywoodlh-home = nixos-configs.packages.${system}.homeConfigurations.heywoodlh.activationPackage;
      heywoodlh-profile = "${heywoodlh-home}/home-files/.mozilla/firefox";
      firefox-setup-script = pkgs.writeShellScriptBin "firefox-setup" ''
        if [[ -z $1 ]]
        then
          FIREFOX_DIR="$HOME/.mozilla/firefox"
        else
          FIREFOX_DIR="$1"
        fi
        if [[ ! -e "$FIREFOX_DIR/setup.txt"  ]]
        then
          rm -rf "$FIREFOX_DIR"
          mkdir -p "$(dirname $FIREFOX_DIR)"
          if [[ ! -d "$FIREFOX_DIR" ]]
          then
            cp -rL ${heywoodlh-profile} "$FIREFOX_DIR"
          fi
          ${pkgs.coreutils}/bin/chmod -R a-x,a=rX,u+w "$FIREFOX_DIR"
          touch "$FIREFOX_DIR/setup.txt"
        fi
      '';
    in {
      packages = rec {
        firefox-setup = firefox-setup-script;
        firefox-wrapper = pkgs.writeShellScriptBin "firefox" ''
            ${firefox-setup-script}/bin/firefox-setup "$HOME/.local/share/firefox/heywoodlh"
            if ! which firefox > /dev/null
            then
              FIREFOX_BIN="${pkgs.firefox}/bin/firefox"
            else
              FIREFOX_BIN=$(which firefox)
            fi
            "$FIREFOX_BIN" --new-instance --profile "$PROFILE_DIR" $@
          '';
        default = firefox-wrapper;
        };
      }
    );
}
