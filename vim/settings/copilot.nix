{ vimPlugins, ... }:

{
  plugins = with vimPlugins; [
    copilot-vim
    codecompanion-nvim
  ];
}
