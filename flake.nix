{
  description = "meta-flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fish-flake = {
      url = path:./fish;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vim-flake = {
      url = path:./vim;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fish-flake.follows = "fish-flake";
    };
    git-flake = {
      url = path:./git;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.vim-flake.follows = "vim-flake";
    };
    vscode-flake = {
      url = path:./vscode;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nushell-flake = {
      url = path:./nushell;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tmux-flake = {
      url = path:./tmux;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fish-flake.follows = "fish-flake";
    };
    st-flake = {
      url = path:./st;
      inputs.tmux-flake.follows = "tmux-flake";
    };
    wezterm-flake = {
      url = path:./wezterm;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.tmux-flake.follows = "tmux-flake";
    };
    jetporch-flake = {
      url = path:./jetporch;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ansible-flake = {
      url = path:./ansible;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vimb-flake = {
      url = path:./vimb;
      inputs.nixpkgs.follows = "nixpkgs";
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
    jetporch-flake,
    ansible-flake,
    vimb-flake,
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
        workstation = ansible-flake.packages.${system}.workstation;
        server = ansible-flake.packages.${system}.server;
        vimb = vimb-flake.packages.${system}.vimb;
        vimb-gl = vimb-flake.packages.${system}.vimb-gl;
      };
      formatter = pkgs.alejandra;
    });
}
