{ pkgs, ...}:

let
  modFiles = [
    # Plugins
    ./base16-vim.nix
    ./colorizer.nix
    ./copilot.nix
    ./fish.nix
    ./fugitive.nix
    ./git.nix
    ./gitgutter.nix
    ./glow.nix
    ./indentline.nix
    ./lint.nix
    ./json.nix
    ./lastplace.nix
    ./nerdtree.nix
    ./nord.nix
    ./sensible.nix
    ./betterwhitespace.nix
    # Base vim config
    ./vimrc.nix
  ];

  importModFile = f: pkgs.callPackage f {};
in map importModFile modFiles
