{ vimPlugins, pkgs, ... }:

{
  plugins = with vimPlugins; [ ale ];

  rc = ''
    " https://github.com/dense-analysis/ale/blob/master/supported-tools.md
    " External dependencies
    let $PATH = "${pkgs.ansible-lint}/bin:" . $PATH
    let $PATH = "${pkgs.gopls}/bin:" . $PATH
    let $PATH = "${pkgs.html-tidy}/bin:" . $PATH
    let $PATH = "${pkgs.nimlsp}/bin:" . $PATH
    " Don't use cspell
    " let $PATH = "${pkgs.nodePackages.cspell}/bin:" . $PATH
    let $PATH = "${pkgs.nixfmt}/bin:" . $PATH
    let $PATH = "${pkgs.nodePackages.jsonlint}/bin:" . $PATH
    let $PATH = "${pkgs.pyright}/bin:" . $PATH
    let $PATH = "${pkgs.terraform-ls}/bin:" . $PATH
    let $PATH = "${pkgs.vale}/bin:" . $PATH
    let $PATH = "${pkgs.vim-vint}/bin:" . $PATH

    let b:ale_linters = {'markdown': ['vale']}
  '';
}
