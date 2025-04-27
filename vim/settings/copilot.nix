{ vimPlugins, ... }:

{
  plugins = with vimPlugins; [
    copilot-vim
    CopilotChat-nvim
  ];
}
