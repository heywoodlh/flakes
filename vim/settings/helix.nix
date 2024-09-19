{ pkgs, helix-vim, ... }:

{
  rc = ''
    source ${helix-vim}/helix.vim
  '';
}
