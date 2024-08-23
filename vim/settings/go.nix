{ pkgs, vimPlugins, ... }:

{
  plugins = with vimPlugins; [ vim-go ];
}
