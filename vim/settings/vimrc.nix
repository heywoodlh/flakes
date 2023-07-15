{ ... }:

{
  rc = ''
    if winheight(0) >= 35
    	set termwinsize=10x0
    	set confirm
    	set splitbelow
    end
    syntax on

    filetype plugin indent on
    let g:mapleader = "\<Space>"
    let g:maplocalleader = ','

    " Turn on line numbers
    set number

    set shiftwidth=4

    " Custom keybinds
    nnoremap zz :wa <bar> :qa!<CR>
    nnoremap zq <bar> :qa!<CR>
    map <silent> <C-y> :w! ~/tmp/vimbuf <CR>:silent !cat ~/tmp/vimbuf <Bar> pbcopy<CR>:redraw!<CR>
    map <silent> <C-t> :term ++kill=term<CR>
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

    " Show trailing whitespaces
    highlight ExtraWhitespace ctermbg=red guibg=red
    match ExtraWhitespace /\s\+$/

    " Check operating system
    if !exists("g:os")
        if has("win64") || has("win32") || has("win16")
            let g:os = "Windows"
        else
            let g:os = substitute(system('uname'), '\n', '''''', '''''')
        endif
    endif
    " OS-specific config
    " MacOS
    if g:os == "Darwin"
        map <silent> <C-y> :w! /tmp/vimbuf <CR>:silent !cat ~/tmp/vimbuf <Bar> pbcopy<CR>:redraw!<CR>
    " Linux
    elseif g:os == "Linux"
        map <silent> <C-y> :w! /tmp/vimbuf <CR>:silent !cat ~/tmp/vimbuf <Bar> xclip -selection clipboard<CR>:redraw!<CR>
    " Windows
    elseif g:os == "Windows"
        map <silent> <C-y> :w! ~/temp/vimbuf <CR>:silent !cat ~/temp/vimbuf <Bar> clip.exe<CR>:redraw!<CR>
    endif
  '';
}
