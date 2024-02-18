{ vimPlugins, pkgs, ... }:

{
  plugins = with vimPlugins; [ ale ];

  rc = ''
    " https://github.com/dense-analysis/ale/blob/master/supported-tools.md
    " External dependencies
    " REMINDER TO SELF: don't use cspell (has some annoying defaults)
    let $PATH = "${pkgs.ansible-lint}/bin:" . $PATH
    let $PATH = "${pkgs.html-tidy}/bin:" . $PATH
    let $PATH = "${pkgs.nixfmt}/bin:" . $PATH
    let $PATH = "${pkgs.nodePackages.jsonlint}/bin:" . $PATH
    let $PATH = "${pkgs.pandoc}/bin:" . $PATH
    let $PATH = "${pkgs.pyright}/bin:" . $PATH
    let $PATH = "${pkgs.shellcheck}/bin:" . $PATH
    let $PATH = "${pkgs.terraform-ls}/bin:" . $PATH
    let $PATH = "${pkgs.vim-vint}/bin:" . $PATH

    " Ale-hover
    let g:ale_floating_preview = 1
    let g:ale_floating_window_border = []
    let g:ale_hover_to_floating_preview = 1
    let g:ale_detail_to_floating_preview = 1
    let g:ale_echo_cursor = 1

    " Fix for hover: https://github.com/dense-analysis/ale/issues/4424#issuecomment-1397609473
    let g:ale_virtualtext_cursor = 'disabled'
  '';
}
