{ vimPlugins, ... }:

{
  plugins = with vimPlugins; [ nord-vim ];
  rc = ''
    " set comments to light blue
    hi Comment ctermfg=LightBlue
    colorscheme nord
  '';
}
