{
  description = "heywoodlh fish flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

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
        # Function to add a directory to $PATH
        # Only if exists
        function add-to-path
            if not contains $argv[1] $PATH
                set -gx PATH $argv[1] $PATH
            end
        end

        # Special stuff for appimage to work
        add-to-path ${pkgs.coreutils}/bin
        add-to-path ${pkgs.ncurses5}/bin

        # Source default nix profile if exists
        test -e /nix/var/nix/profiles/default/etc/profile.d/nix.fish && source /nix/var/nix/profiles/default/etc/profile.d/nix.fish || true

        fish_config theme choose Nord
        set fish_greeting ""

        # Starship
        set -gx STARSHIP_CONFIG "${starship_config}"
        ${pkgs.starship}/bin/starship init fish | source

        # Direnv
        eval (${pkgs.direnv}/bin/direnv hook fish)

        # Use 1password SSH agent if it exists (not over SSH/headless environment)
        if test -z $SSH_CONNECTION
            if test -e $HOME/.1password/agent.sock
                set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
            end
            if test -e "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
                set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
            end
        end

        # Start ssh-agent if not using 1password
        if not echo $SSH_AUTH_SOCK | ${pkgs.gnugrep}/bin/grep -q 1password
            # Check if ssh-agent running with ~/.ssh/agent.sock socket
            if not ${pkgs.ps}/bin/ps -fjH -u $USER | ${pkgs.gnugrep}/bin/grep ssh-agent | ${pkgs.gnugrep}/bin/grep -q "$HOME/.ssh/agent.sock" &> /dev/null
                mkdir -p $HOME/.ssh
                rm -f $HOME/.ssh/agent.sock &> /dev/null
                eval (${pkgs.openssh}/bin/ssh-agent -t 4h -c -a "$HOME/.ssh/agent.sock") &> /dev/null || true
            else
                # ssh-agent running, set SSH_AUTH_SOCK
                export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
            end
        end

        # Add ~/bin to $PATH (ALWAYS)
        if not contains $HOME/bin $PATH
            set -gx PATH $HOME/bin $PATH
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
            env | grep -iqE "^OP_SESSION" || eval $(${pkgs._1password-cli}/bin/op signin)
        end

        function geoiplookup
            ${pkgs.curl}/bin/curl -s ipinfo.io/$argv[1]
        end

        function nix-flake-init
            ${pkgs.nix}/bin/nix flake init -t gitlab:kylesferrazza/nix-flake-templates
        end

        source ${./nix.fish}
        source ${aws_config}

        mkdir -p ~/.config/fish

        # Use host-specific configs if they exist
        test -e ~/.config/fish/machine.fish && source ~/.config/fish/machine.fish || true

        # Always re-source ~/.config/fish/config.fish last
        # Prioritize local config
        test -e ~/.config/fish/config.fish && source ~/.config/fish/config.fish

        # Use custom config if exists
        test -e ~/.config/fish/custom.fish && source ~/.config/fish/custom.fish || true

      '';
      fishExe = pkgs.writeShellScriptBin "fish" ''
        ${pkgs.fish}/bin/fish --init-command="source ${fish_config}" $@
      '';
      # Tmux configs
      myClip = if pkgs.stdenv.isDarwin then pkgs.writeShellScript "myClip" ''
        stdin=$(cat)

        /usr/bin/printf "%s" "$stdin" | /usr/bin/pbcopy
      '' else pkgs.writeShellScript "myClip" ''
        stdin=$(cat)
        env | grep -qE '^WAYLAND' && clipboard_command="${pkgs.wl-clipboard}/bin/wl-copy"
        if env | grep -qE '^DISPLAY'
        then
          clipboard_command="${pkgs.xclip}/bin/xclip -sel clip"
        else
          clipboard_command="${pkgs.tmux}/bin/tmux loadb -"
        fi
        printf "%s" "$stdin" | $clipboard_command
      '';
      clipConf = ''
        ## Clipboard
        bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${myClip}"
        bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "${myClip}"
      '';
      nordTmux = pkgs.writeShellScript "nord.tmux" ''
        ${pkgs.tmux}/bin/tmux set-option -g mode-style 'bg=brightblack, fg=cyan'
        ${pkgs.tmux}/bin/tmux set-option -g message-style 'bg=brightblack, fg=cyan'

        ${pkgs.tmux}/bin/tmux set-option -g status-justify centre
        ${pkgs.tmux}/bin/tmux set-option -g status-style "bg=brightblack"
        ${pkgs.tmux}/bin/tmux set-option -g status-left ' #S #[fg=cyan, bg=brightblack] '
        ${pkgs.tmux}/bin/tmux set-option -g status-left-style "bg=cyan,fg=black"

        ${pkgs.tmux}/bin/tmux set-option -g status-right "#[fg=cyan, bg=brightblack] #[fg=brightblack, bg=cyan] %d/%m %R "
        ${pkgs.tmux}/bin/tmux set-option -g status-right-style "bg=brightblack,fg=cyan"

        ${pkgs.tmux}/bin/tmux set-window-option -g window-status-format ' #I:#W '
        ${pkgs.tmux}/bin/tmux set-window-option -g window-status-style "bg=black"
        ${pkgs.tmux}/bin/tmux set-window-option -g window-status-current-format '#[bold] #I:#W '
        ${pkgs.tmux}/bin/tmux set-window-option -g window-status-current-style "bg=cyan,fg=black"
        ${pkgs.tmux}/bin/tmux set-window-option -g window-status-separator ''''''
      '';
      tmuxConf = pkgs.writeText "tmux.conf" ''
        # Set shell
        set -g default-shell ${fishExe}/bin/fish
        run-shell ${nordTmux}
        # Change default prefix key to C-a, similar to screen
        unbind-key C-b
        set-option -g prefix C-a

        # Enable 24-bit color support
        set-option -ga terminal-overrides ",xterm-termite:Tc"

        # Start window indexing at one
        set-option -g base-index 1

        # Use vi-style key bindings in the status line, and copy/choice modes
        set-option -g status-keys vi
        set-window-option -g mode-keys vi

        # Large scrollback history
        set-option -g history-limit 10000

        # Xterm Keys on
        set-window-option -g xterm-keys on

        # Set 256 colors
        set -g default-terminal "screen-256color"

        # Set escape time to zero
        set -sg escape-time 0

        # move between panes with vim-like motions
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        unbind % # Split vertically
        unbind '"' # Split horizontally

        bind-key | split-window -h -c "#{pane_current_path}"
        bind-key - split-window -v -c "#{pane_current_path}"

        # Synchronizing panes
        #bind-key y set-window-option synchronize-panes

        # SSH to Host
        bind-key S command-prompt -p ssh: "new-window -n %1 'ssh %1'"
        # Mosh to Host
        bind-key M command-prompt -p mosh: "new-window -n %1 'mosh %1'"

        # Mouse mode
        set -g mouse on

        # Tmux Scrolling
        bind -n WheelUpPane   select-pane -t= \; copy-mode -e \; send-keys -M
        bind -n WheelDownPane select-pane -t= \;                 send-keys -M

        bind a send-prefix
        # vim-selection
        bind-key -T copy-mode-vi 'v' send-keys -X begin-selection

        ${clipConf}

        # if SSH, disable status bar
        if-shell "[ -n \"$SSH_TTY\" ]" "set -g status off"
        if-shell "[ -n \"$SSH_CONNECTION\" ]" "set -g status off"
        # Allow forcing Tmux status bar
        if-shell "[ -n \"$FORCE_TMUX_STATUS\" ]" "set -g status on"
      '';
      # Zellij config
      zellijEditor = pkgs.writeShellScript "editor" ''
        # Check for Helix, fall back to Vim if unavailable
        if ${pkgs.which}/bin/which hx &>/dev/null
        then
          hx $@
        else
          ${pkgs.vim}/bin/vim $@
        fi
      '';
      zellijConf = pkgs.writeText "config.yaml" ''
        default_shell "${fishExe}/bin/fish"
        theme "nord"
        simplified_ui true
        pane_frames false
        scrollback_editor "${zellijEditor}"
      '';
      ghosttyOsConf = if pkgs.stdenv.isDarwin then ''
        # macos ghostty config
        macos-window-shadow = false
        # https://github.com/ghostty-org/ghostty/pull/3742
        # quick-terminal-size = 80%

        # quake mode; on MacOS give Ghostty accessibility permissions
        keybind = global:ctrl+grave_accent=toggle_quick_terminal
        quick-terminal-animation-duration = 0.1
      '' else ''
        # linux ghostty config
      '';
      ghosttyConf = pkgs.writeText "config" ''
        theme = catppuccin-frappe
        command = ${pkgs.tmux}/bin/tmux -f ${tmuxConf}
        window-decoration = false
        font-size = 12
        ${ghosttyOsConf}
      '';
      ghosttyXdgDir = pkgs.stdenv.mkDerivation {
        name = "xdgDir";
        builder = pkgs.bash;
        args = [ "-c" "${pkgs.coreutils}/bin/mkdir -p $out/ghostty; ${pkgs.coreutils}/bin/cp ${ghosttyConf} $out/ghostty/config;" ];
      };
    in {
      packages = rec {
        fish = fishExe;
        ghostty = pkgs.writeShellScriptBin "ghostty" ''
          XDG_CONFIG_HOME=${ghosttyXdgDir} ${pkgs.ghostty}/bin/ghostty $@
        '';
	ghostty-conf = ghosttyConf;
        tmux = pkgs.writeShellScriptBin "tmux" ''
          # Include BASH (for appimage to work properly)
          PATH=${pkgs.bash}/bin:$PATH
          if env | grep -i en_US
          then
            # If running on normal system
            ${pkgs.tmux}/bin/tmux -f ${tmuxConf} $@
          else
            # If running in more minimal env
            ${pkgs.tmux}/bin/tmux -u -f ${tmuxConf} $@
          fi
        '';
        zellij = pkgs.writeShellScriptBin "zellij" ''
          PATH=${pkgs.zellij}/bin:$PATH # Include zellij in path
          ${pkgs.zellij}/bin/zellij --config ${zellijConf} $@
        '';
        default = fish;
        };
      }
    );
}
