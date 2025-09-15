{ pkgs, vimPlugins, mcphub, ... }:

let
  system = pkgs.system;
  mcphub-plugin = mcphub.packages.${system}.default;
in {
  plugins = with vimPlugins; [
    copilot-vim
    codecompanion-nvim
    codecompanion-history-nvim
    mcphub-plugin
    llm-nvim
  ];
}
