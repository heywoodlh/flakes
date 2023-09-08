{ pkgs, myFish, ...}:

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
    ./shell.nix
    # Base vim config
    ./vimrc.nix
  ];

  importModFile = f: pkgs.callPackage f { inherit myFish; };
in map importModFile modFiles
