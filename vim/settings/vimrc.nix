{ pkgs, ... }:

{
  rc = ''
    syntax on

    filetype plugin indent on
    let g:mapleader = "\<Space>"
    let g:maplocalleader = ','

    " Turn on line numbers
    set number

    set shiftwidth=4

    " Custom keybinds
    nnoremap zq <bar> :qa!<CR>
    map <silent> <C-l> :set invnumber<CR>

    command NoComments %s/#.*\n//g
    nnoremap nc :NoComments<CR>

    " Folding
    set foldmethod=syntax
    set foldlevel=99

    " Show matching characters like paranthesis, brackets, etc.
    set showmatch

    " Cursor settings:

    "  1 -> blinking block
    "  2 -> solid block
    "  3 -> blinking underscore
    "  4 -> solid underscore
    "  5 -> blinking vertical bar
    "  6 -> solid vertical bar

    " back to line cursor when in normal mode
    let &t_SI.="\e[5 q" "SI = INSERT mode
    let &t_SR.="\e[5 q" "SR = REPLACE mode
    let &t_EI.="\e[5 q" "EI = NORMAL mode (ELSE)

    " Convert tabs to spaces
    set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab

    " Ignore case with search
    set ignorecase smartcase

    " Yank to system clipboard with Ctrl + y
    noremap <silent> <C-y> "*y

    "This unsets the "last search pattern" register by hitting return
    nnoremap <CR> :noh<CR><CR>

    " Check operating system
    if has("mac")
        let g:os = "Darwin"
    elseif has("win32")
        let g:os = "Windows"
    elseif has("win32unix")
        let g:os = "Cygwin"
    elseif has("bsd")
        let g:os = "BSD"
    elseif has("linux")
        let g:os = "Linux"
    end
    " OS-specific config
    " MacOS
    if g:os == "Darwin"
        "Something
    " Linux
    elseif g:os == "Linux"
        let g:clipboard = {
              \   'name': 'wayland-clip',
              \   'copy': {
              \      '+': 'wl-copy --foreground --type text/plain',
              \      '*': 'wl-copy --foreground --type text/plain --primary',
              \    },
              \   'paste': {
              \      '+': {-> systemlist('wl-paste --no-newline | sed -e "s/\r$//"')},
              \      '*': {-> systemlist('wl-paste --no-newline --primary | sed -e "s/\r$//"')},
              \   },
              \   'cache_enabled': 1,
              \ }
    " Windows
    elseif g:os == "Windows"
        "Something
    endif
  '';
}
