{ callPackage, ...}:

let
  modFiles = [
    # Plugins
    ./ale.nix
    ./base16-vim.nix
    ./colorizer.nix
    ./fugitive.nix
    ./git.nix
    ./gitgutter.nix
    ./glow.nix
    ./go.nix
    ./indentline.nix
    ./json.nix
    ./lastplace.nix
    ./llm.nix
    ./nerdtree.nix
    ./theme.nix
    ./sensible.nix
    ./betterwhitespace.nix
    ./shell.nix
    ./os-specific.nix
    ./pets.nix
    ./copilot.nix
    ./localvimrc.nix
    # Base vim config
    ./vimrc.nix
  ];

  importModFile = f: callPackage f {};
in map importModFile modFiles
