" Copyright 2011 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" fmt.vim: Vim command to format Go files with gofmt.
"
" This filetype plugin add a new commands for go buffers:
"
"   :GoFmt
"
"       Filter the current Go buffer through gofmt.
"       It tries to preserve cursor position and avoids
"       replacing the buffer with stderr output.
"
" Options:
"
"   g:go_fmt_command [default="gofmt"]
"
"       Flag naming the gofmt executable to use.
"
"   g:go_fmt_autosave [default=1]
"
"       Flag to auto call :Fmt when saved file
"

if !exists("g:go_fmt_command")
    let g:go_fmt_command = "gofmt"
endif

if !exists("g:go_goimports_bin")
    let g:go_goimports_bin = "goimports"
endif

if !exists('g:go_fmt_fail_silently')
    let g:go_fmt_fail_silently = 0
endif

if !exists('g:go_fmt_options')
    let g:go_fmt_options = ''
endif

let s:got_fmt_error = 0

function! go#fmt#Format(withGoimport)
    let view = winsaveview()

    let fmt_command = g:go_fmt_command
    if a:withGoimport  == 1 
        " check if the user has installed goimports
        let bin_path = go#tool#BinPath(g:go_goimports_bin) 
        if empty(bin_path) 
            return 
        endif

        let fmt_command = bin_path
    endif

    " populate the final command with user based fmt options
    let command = fmt_command . ' ' . g:go_fmt_options
    silent execute "%!" . command
    if v:shell_error
        let errors = []
        for line in getline(1, line('$'))
            let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)')
            if !empty(tokens)
                call add(errors, {"filename": @%,
                                 \"lnum":     tokens[2],
                                 \"col":      tokens[3],
                                 \"text":     tokens[4]})
            endif
        endfor
        if empty(errors)
            % | " Couldn't detect gofmt error format, output errors
        endif
        undo
        if !empty(errors)
            call setqflist(errors, 'r')
        endif
        echohl Error | echomsg "Gofmt returned error" | echohl None
    endif
    call winrestview(view)
endfunction


" vim:ts=4:sw=4:et
