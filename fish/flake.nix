{
  description = "heywoodlh fish flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      fish_config = pkgs.writeText "profile.fish" ''
        set fish_greeting ""

        ${pkgs.starship}/bin/starship init fish | source
        eval (${pkgs.direnv}/bin/direnv hook fish)

        # Use 1password SSH agent if it exists
        if test -e $HOME/.1password/agent.sock
            set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
        end
        if test -e "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
            set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        end

        # Add ~/bin to $PATH (ALWAYS)
        if not contains $HOME/bin $PATH
            set -gx PATH $HOME/bin $PATH
        end

        # op-unlock function
        function op-unlock
            eval $(op signin)
        end

        # Function to add a directory to $PATH
        # Only if exists
        function add-to-path
            if not contains $argv[1] $PATH
                set -gx PATH $argv[1] $PATH
            end
        end

        # Add homebrew to $PATH
        add-to-path /opt/homebrew/bin
        add-to-path ${pkgs.direnv}/bin

        # Set EDITOR to vim
        set -gx EDITOR "vim"
        set -gx GIT_EDITOR "vim"
      '';
    in {
      packages = rec {
        fish = pkgs.writeShellScriptBin "fish" ''
          ${pkgs.fish}/bin/fish --init-command="source ${fish_config} && source ${./nix.fish}" $@
          '';
        default = fish;
        };
      }
    );
}
