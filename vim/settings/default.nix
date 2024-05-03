{ pkgs, myFish, ...}:

let
  modFiles = [
    # Plugins
    ./ale.nix
    ./base16-vim.nix
    ./colorizer.nix
    ./copilot.nix
    ./fish.nix
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
    ./betterwhitespace.nix
    ./shell.nix
    ./os-specific.nix
    ./vim-pets.nix
    ./localvimrc.nix
    # Base vim config
    ./vimrc.nix
  ];

  importModFile = f: pkgs.callPackage f { inherit myFish; };
in map importModFile modFiles
