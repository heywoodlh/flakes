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
      starship_config = pkgs.writeText "starship.toml" ''
        [character]
        success_symbol = '[❯](bold white)'

        [container]
        disabled = true

        [battery]
        disabled = true
      '';
      aws_config = pkgs.writeText "aws.fish" ''
        if test -z "$AWS_CONFIG_FILE"
          set -gx AWS_CONFIG_FILE "$HOME/.aws/config"
        end

        # Helper function to get aws-profiles
        function _get_aws_profiles
          if grep -q '\[profile ' "$AWS_CONFIG_FILE"
            set -x aws_profiles "$(${pkgs.gnugrep}/bin/grep '\[profile' $AWS_CONFIG_FILE)"
            set -x aws_profiles "$(echo $aws_profiles | ${pkgs.gnused}/bin/sed 's/\[profile //g' | ${pkgs.gnused}/bin/sed 's/\]//g')"
            echo $aws_profiles
          end
        end

        # Function to easily switch aws profiles in config
        function asp
          if test -e "$AWS_CONFIG_FILE"
            set -x aws_profiles "$(${pkgs.gnugrep}/bin/grep '\[profile' $AWS_CONFIG_FILE)"
            set -x aws_profiles "$(echo $aws_profiles | ${pkgs.gnused}/bin/sed 's/\[profile //g' | ${pkgs.gnused}/bin/sed 's/\]//g')"
            set -x profile_selection "$argv[1]"
            if test -z "$profile_selection"
              set -x profile_selection "$(echo $aws_profiles | ${pkgs.coreutils}/bin/tr " " "\n" | ${pkgs.fzf}/bin/fzf)"
            end
            test -n "$profile_selection" && echo "$aws_profiles" | ${pkgs.gnugrep}/bin/grep -q "$profile_selection" && set -gx AWS_PROFILE "$profile_selection"
          end
        end

        # Autocompletion for asp
        complete -e asp
        if test -e "$AWS_CONFIG_FILE"
          complete -x -c asp -d "AWS profiles" -n "_get_aws_profiles" -a "$(_get_aws_profiles)"
        end
      '';
      fish_config = pkgs.writeText "profile.fish" ''
        fish_config theme choose Nord
        set fish_greeting ""

        # Starship
        set -gx STARSHIP_CONFIG "${starship_config}"
        ${pkgs.starship}/bin/starship init fish | source

        # Direnv
        eval (${pkgs.direnv}/bin/direnv hook fish)

        # Use 1password SSH agent if it exists
        if test -z $SSH_CONNECTION
            if test -e $HOME/.1password/agent.sock
                set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
            end
            if test -e "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
                set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
            end
        end

        # Add ~/bin to $PATH (ALWAYS)
        if not contains $HOME/bin $PATH
            set -gx PATH $HOME/bin $PATH
        end

        # Function to add a directory to $PATH
        # Only if exists
        function add-to-path
            if not contains $argv[1] $PATH
                set -gx PATH $argv[1] $PATH
            end
        end

        # Ensure nix-darwin system is added to path
        add-to-path /run/current-system/sw/bin

        # Add homebrew to $PATH
        add-to-path /opt/homebrew/bin
        # Add direnv to $PATH
        add-to-path ${pkgs.direnv}/bin

        # Set EDITOR to vim
        set -gx EDITOR "vim"
        set -gx GIT_EDITOR "vim"

        # Hammerspoon
        add-to-path /Applications/Hammerspoon.app/Contents/Frameworks/hs

        # Custom functions

        function op-unlock
            env | grep -iqE "^OP_SESSION" || eval $(${pkgs._1password}/bin/op signin)
        end

        function geoiplookup
            ${pkgs.curl}/bin/curl -s ipinfo.io/$argv[1]
        end

        function nix-flake-init
            ${pkgs.nix}/bin/nix flake init -t gitlab:kylesferrazza/nix-flake-templates
        end

        source ${./nix.fish}
        source ${aws_config}

        # Always re-source ~/.config/fish/config.fish last
        # Prioritize local config
        mkdir -p ~/.config/fish
        test -e ~/.config/fish/config.fish && source ~/.config/fish/config.fish

        # Use custom config if exists
        test -e ~/.config/fish/custom.fish && source ~/.config/fish/custom.fish || true
      '';
    in {
      packages = rec {
        fish = pkgs.writeShellScriptBin "fish" ''
          ${pkgs.fish}/bin/fish --init-command="source ${fish_config}" $@
          '';
        default = fish;
        };
      }
    );
}
