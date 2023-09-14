{ stdenv, xclip, wl-clipboard, ... }:

{
  rc = if stdenv.isDarwin then ''
    # MacOS specific config
    " Yank to system clipboard with Ctrl + y
    noremap <silent> <C-y> "*y
  '' else ''
    let $PATH = "${xclip}/bin:" . $PATH
    " Wayland-specific config
    if !empty($WAYLAND_DISPLAY)
        let g:clipboard = {
              \   'name': 'wayland-clip',
              \   'copy': {
              \      '+': '${wl-clipboard}/bin/wl-copy --foreground --type text/plain',
              \      '*': '${wl-clipboard}/bin/wl-copy --foreground --type text/plain --primary',
              \    },
              \   'paste': {
              \      '+': {-> systemlist('${wl-clipboard}/bin/wl-paste --no-newline | sed -e "s/\r$//"')},
              \      '*': {-> systemlist('${wl-clipboard}/bin/wl-paste --no-newline --primary | sed -e "s/\r$//"')},
              \   },
              \   'cache_enabled': 1,
              \ }
    else
        " X11-specific config
    endif

    " Yank to system clipboard with Ctrl + y
    noremap <silent> <C-y> "+y
  '';
}
