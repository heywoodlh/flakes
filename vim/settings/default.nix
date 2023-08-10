{ pkgs, ...}:

let
  modFiles = [
    # Plugins
    ./ale.nix
    ./base16-vim.nix
    ./colorizer.nix
    ./copilot.nix
    ./fish.nix
    ./fterm.nix
    ./fugitive.nix
    ./git.nix
    ./gitgutter.nix
    ./glow.nix
    ./indentline.nix
    ./json.nix
    ./lastplace.nix
    ./nerdtree.nix
    ./nord.nix
    ./sensible.nix
    ./todoist.nix
    # Base vim config
    ./vimrc.nix
  ];

  importModFile = f: pkgs.callPackage f {};
in map importModFile modFiles
