{ vimPlugins, ... }:

{
  plugins = with vimPlugins; [ nord-vim ];
  rc = ''
    colorscheme nord
  '';
}
