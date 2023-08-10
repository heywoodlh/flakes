{ pkgs, ... }:

{
  rc = ''
    command GitAdd :w! <bar> !${pkgs.git}/bin/git add -v %
    command GitCommit !$gitmessage = ($gitmessage = read-host -prompt "commit message") && git commit -s -m ''${gitmessage}

    nnoremap ga :GitAdd<CR>
    nnoremap gc :GitCommit<CR>
  '';
}
