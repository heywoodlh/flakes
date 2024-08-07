{
  description = "heywoodlh tmux flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.fish-flake.url = "github:heywoodlh/flakes?dir=fish";

  outputs = { self, nixpkgs, flake-utils, fish-flake, }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      myFish = fish-flake.packages.${system}.fish;
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
        set -g default-shell ${myFish}/bin/fish
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
      '';
    in {
      packages = rec {
        tmux = pkgs.writeShellScriptBin "tmux" ''
            # Include BASH (for appimage to work properly)
            PATH=${pkgs.bash}/bin:$PATH
            ${pkgs.tmux}/bin/tmux -f ${tmuxConf} $@
          '';
        default = tmux;
        };
      }
    );
}
