{
  description = "meta-flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fish-flake = {
      url = "./fish";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vim-flake = {
      url = "./vim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fish-flake.follows = "fish-flake";
    };
    git-flake = {
      url = "./git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.vim-flake.follows = "vim-flake";
    };
    vscode-flake = {
      url = "./vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nushell-flake = {
      url = "./nushell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tmux-flake = {
      url = "./tmux";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fish-flake.follows = "fish-flake";
    };
    st-flake = {
      url = "./st";
      inputs.tmux-flake.follows = "tmux-flake";
    };
    wezterm-flake = {
      url = "./wezterm";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.tmux-flake.follows = "tmux-flake";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    fish-flake,
    git-flake,
    nushell-flake,
    vim-flake,
    tmux-flake,
    vscode-flake,
    st-flake,
    wezterm-flake,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = {
        fish = fish-flake.packages.${system}.fish;
        nushell = nushell-flake.packages.${system}.nushell;
        git = git-flake.packages.${system}.git;
        tmux = tmux-flake.packages.${system}.tmux;
        vim = vim-flake.defaultPackage.${system};
        vscode = vscode-flake.packages.${system}.default;
        st = st-flake.packages.${system}.st;
        wezterm = wezterm-flake.packages.${system}.wezterm;
        wezterm-gl = wezterm-flake.packages.${system}.wezterm-gl;
      };
      formatter = pkgs.alejandra;
    });
}
