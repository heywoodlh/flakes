{ pkgs, vimPlugins, ... }:

let
  system = pkgs.system;
in {
  plugins = with vimPlugins; [ FTerm-nvim ];
  rc = ''
    nnoremap <silent><c-t> :ToggleTerm<CR>
    lua << EOF
      require'FTerm'.setup({
          border = 'double',
          dimensions  = {
              height = 0.9,
              width = 0.9,
          },
      })
      vim.keymap.set('n', '<C-t>', '<CMD>lua require("FTerm").toggle()<CR>')
    EOF
  '';
}
