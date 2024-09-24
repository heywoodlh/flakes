{
  description = "meta-flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    fish-flake = {
      url = "./fish";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vim-flake = {
      url = "./vim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix-flake = {
      url = "./helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-flake = {
      url = "./git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.vim-flake.follows = "vim-flake";
    };
    vscode-flake = {
      url = "./vscode";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fish-flake.follows = "fish-flake";
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
    jetporch-flake = {
      url = "./jetporch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ansible-flake = {
      url = "./ansible";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vimb-flake = {
      url = "./vimb";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    op-flake = {
      url = "./1password";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lima-flake = {
      url = "./nixos-lima";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chromium-widevine-flake = {
      url = "./chromium-widevine";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gnome-flake = {
      url = "./gnome";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
      inputs.fish-flake.follows = "fish-flake";
      inputs.tmux-flake.follows = "tmux-flake";
    };
    qutebrowser-flake = {
      url = "./qutebrowser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser-flake = {
      url = "./zen-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tabby-flake = {
      url = "./tabby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-stable,
    flake-utils,
    fish-flake,
    git-flake,
    nushell-flake,
    vim-flake,
    helix-flake,
    tmux-flake,
    vscode-flake,
    st-flake,
    wezterm-flake,
    jetporch-flake,
    ansible-flake,
    vimb-flake,
    op-flake,
    lima-flake,
    chromium-widevine-flake,
    gnome-flake,
    qutebrowser-flake,
    zen-browser-flake,
    tabby-flake,
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
        helix = helix-flake.packages.${system}.helix;
        helix-config = helix-flake.packages.${system}.helix-config;
        vscode = vscode-flake.packages.${system}.default;
        vscode-userdir = vscode-flake.packages.${system}.user-dir;
        vscode-bin = vscode-flake.packages.${system}.code-bin;
        st = st-flake.packages.${system}.st;
        wezterm = wezterm-flake.packages.${system}.wezterm;
        wezterm-gl = wezterm-flake.packages.${system}.wezterm-gl;
        workstation = ansible-flake.packages.${system}.workstation;
        server = ansible-flake.packages.${system}.server;
        vimb = vimb-flake.packages.${system}.vimb;
        vimb-gl = vimb-flake.packages.${system}.vimb-gl;
        op = op-flake.packages.${system}.op;
        op-desktop-setup = op-flake.packages.${system}.op-desktop-setup;
        nixos-vm = lima-flake.packages.${system}.runVm;
        lima-nixos-img = lima-flake.packages.${system}.img;
        chromium-widevine = chromium-widevine-flake.packages.aarch64-linux.chromium-widevine;
        gnome = gnome-flake.packages.${system}.gnome-desktop-setup;
        gnome-dconf = gnome-flake.packages.${system}.dconf;
        qutebrowser = qutebrowser-flake.packages.${system}.qutebrowser;
        qutebrowser-config = qutebrowser-flake.packages.${system}.qutebrowser-config;
        zen-browser = zen-browser-flake.packages.${system}.default;
        tabby = tabby-flake.packages.${system}.tabby-wrapper;
      };
      formatter = pkgs.alejandra;
    });
}
