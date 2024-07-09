{ vimPlugins, myFish, pkgs, ... }:

let
  system = pkgs.system;
in {
  plugins = with vimPlugins; [ toggleterm-nvim ];
  rc = ''
    lua << EOF
      require("toggleterm").setup{
        open_mapping = [[<c-t>]],
        shell = "${myFish}/bin/fish",
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        direction = 'float',
        hide_numbers = true,
        autochdir = true,
      }
    EOF
  '';
}
