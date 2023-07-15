{ ... }:

{
  rc = ''
    command GitAdd :w! <bar> !git add -v %
    command GitCommit !$gitmessage = ($gitmessage = read-host -prompt "commit message") && git commit -s -m ''${gitmessage}
    command GitPush !gpsup

    nnoremap ga :GitAdd<CR>
    nnoremap gc :GitCommit<CR>
    nnoremap gp :GitPush<CR>
  '';
}
