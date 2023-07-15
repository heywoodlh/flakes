{ pkgs, ...}:

let
  settingsFiles = [
    # Plugins
    ./ale.nix
    ./base16-vim.nix
    ./colorizer.nix
    ./copilot.nix
    ./fugitive.nix
    ./git.nix
    ./gitgutter.nix
    ./indentline.nix
    ./json.nix
    ./lastplace.nix
    ./nerdtree.nix
    ./nord.nix
    ./sensible.nix
    ./todo.txt.nix
    # Base vim config
    ./vimrc.nix
  ];

  importSettingsFile = f: pkgs.callPackage f {};
in map importSettingsFile settingsFiles
