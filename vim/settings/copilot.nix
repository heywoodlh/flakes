{ vimPlugins, ... }:

{
  plugins = with vimPlugins; [
    copilot-vim
    CopilotChat-nvim
  ];
  rc = ''
    lua << EOF
      require("CopilotChat").setup {
        chat_autocomplete = false,
        model = 'gpt-4o',
      }
    EOF
  '';
}
