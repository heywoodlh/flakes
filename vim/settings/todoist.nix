{ pkgs, vimPlugins, ...}:
let
  todoist.nvim = pkgs.vimUtils.buildVimPlugin {
    name = "todoist.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "romgrk";
      repo = "todoist.nvim";
      rev = "7e8a5e58d721bb24c1f48162fed841f12c0c43db";
      sha256 = "0m8lay1zx1aga4s923434kc8j9d63059ifb9vq7dxnx62h1wy5x8";
    };
  };

in {
  plugins = [
    (pkgs.vim_configurable.customize {
      vimrcConfig.packages.myVimPackage = with pkgs.vimPlugins; {
        start = [ todoist.nvim ];
      };
    })
  ];
}
