{
  description = "heywoodlh wezterm flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.tmux-flake.url = "github:heywoodlh/flakes?dir=tmux";
  inputs.nixgl.url = "github:nix-community/nixGL";

  outputs = { self, nixpkgs, tmux-flake, flake-utils, nixgl, }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlay ];
      };
      myTmux = tmux-flake.packages.${system}.tmux;
      jetbrains_nerdfont = (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; });
      settings = pkgs.writeText "wezterm.lua" ''
        -- Add config folder to watchlist for config reloads.
        local wezterm = require 'wezterm';
        wezterm.add_to_config_reload_watch_list(wezterm.config_dir)

        -- Pull in the wezterm API
        local wezterm = require 'wezterm'

        -- This table will hold the configuration.
        local config = {}

        -- In newer versions of wezterm, use the config_builder which will
        -- help provide clearer error messages
        if wezterm.config_builder then
          config = wezterm.config_builder()
        end

        -- Nord color scheme:
        config.color_scheme = 'nord'
        config.font = wezterm.font_with_fallback {
          'JetBrainsMono Nerd Font Mono',
          'Iosevka Nerd Font Mono',
          'SF Mono Regular',
          'DejaVu Sans Mono',
        }
        config.font_size = 14.0

        -- Appearance tweaks
        config.window_decorations = "RESIZE"
        config.hide_tab_bar_if_only_one_tab = true
        config.audible_bell = "Disabled"
        config.window_background_opacity = 0.9

        -- Set tmux to default shell
        config.default_prog = { "${myTmux}/bin/tmux" }

        -- Use Jetbrains font directory
        config.font_dirs = { "${jetbrains_nerdfont}/share/fonts" }

        -- and finally, return the configuration to wezterm
        return config
      '';
    in {
      packages = rec {
        wezterm = pkgs.writeShellScriptBin "wezterm" ''
            ${pkgs.wezterm}/bin/wezterm --config-file ${settings}
          '';
        wezterm-gl = pkgs.writeShellScriptBin "wezterm" ''
            ${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL ${pkgs.wezterm}/bin/wezterm --config-file ${settings}
          '';
          default = wezterm;
        };
      }
    );
}
