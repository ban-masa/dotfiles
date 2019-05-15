set notitle
set whichwrap+=h,l
set expandtab
set smarttab
set hlsearch
set ignorecase
set smartcase
set number
set showmatch
set autoindent
set title
set clipboard=autoselect
set clipboard+=unnamed
set clipboard=unnamedplus
syntax on
set tabstop=2
set smartindent
set shiftwidth=2
set background=dark

autocmd BufNewFile,BufRead *.l set filetype=lisp
autocmd BufNewFile,BufRead *.launch set filetype=xml
autocmd BufNewFile,BufRead *.ino set filetype=cpp

set nocompatible
filetype off
set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim
call dein#begin(expand('~/.vim/dein'))
call dein#add('Shougo/dein.vim')
call dein#add('Shougo/unite.vim')
call dein#add('Shougo/vimshell.vim')
call dein#add('Shougo/neocomplcache.vim')
call dein#add('Shougo/vimproc.vim', {'build' : 'make'})
call dein#add('aharisu/vim_goshrepl', {'build' : 'make'})
call dein#add('vim-scripts/AnsiEsc.vim')
call dein#add('taketwo/vim-ros')
call dein#end()
filetype plugin indent on

let g:slimv_repl_split = 4
let g:slimv_repl_name = 'REPL'
let g:slimv_repl_simple_eval = 0
let g:slimv_lisp = '/opt/ros/indigo/bin/roseus'
let g:slimv_impl = 'roseus'
let g:slimv_preferred = 'roseus'
let g:lisp_rainbow=1
let g:roseus_opened = 0
vmap <silent> <C-c> :w !xsel -bi<CR><CR>
nnoremap <silent> <C-c> <S-v>:w !xsel -bi<CR><CR>
nnoremap <silent> <F5> :w<CR>:!make<CR><CR>

function! s:SendCtrlCToREPL()
  call ieie#execute("\<C-c>", bufnr("%"), 0)
endfunction
function! s:HistoryBeginningSearch(prev)
  let ctx = ieie#get_context(bufnr("%"))
  let lines_len = len(ctx["lines"])
  if lines_len == 0
    return
  endif
  let beginning = getline(line("."))[len(ieie#get_prompt(ctx, line("."))):col(".")-1]
  if beginning == ""
    return
  endif
  let his_index = ctx["input-history-index"]
  let i = 0
  while i < lines_len
    let his_index = his_index + (((a:prev == 1)?1 : -1))
    if his_index < 0
      let his_index = lines_len
    endif
    if his_index > 0
      if his_index <= lines_len
        if stridx(ctx["lines"][-his_index], beginning) == 0
          let l:text = ctx["lines"][-his_index]
          break
        endif
      else
        let his_index = 0
      endif
    endif
    if his_index == 0
      let l:text = beginning
      break
    endif
    let i = i + 1
  endwhile
  if exists("text")
    let line_num = line(".")
    call setline(line_num,(ieie#get_prompt(ctx,line_num)) . l:text)
    let ctx["input-history-index"] = his_index
  endif
endfunction
function! s:LoadHistFile()
  let ctx = ieie#get_context(bufnr("%"))
  if filereadable(b:histfile)
    let b:loaded_hist = readfile(b:histfile)
    let ctx["lines"] = deepcopy(b:loaded_hist)
  endif
endfunction
function! AddHistToFile(ctx)
  if filereadable(b:histfile) && filewritable(b:histfile)
    let new_hist = a:ctx["lines"][len(b:loaded_hist):]
    let old_hist = []
    if len(new_hist) < b:histfilesize
      let old_hist = readfile(b:histfile, "", len(new_hist)-b:histfilesize)
    else
      let new_hist = new_hist[(-b:histfilesize):]
    endif
    call writefile(old_hist+new_hist, b:histfile)
  endif
endfunction
"" roseus
function! Open_roseus(...)
  if a:0 == 0
    let l:proc = 'roseus'
  else
    let l:proc = 'roseus ' . a:1
  endif
  call ieie#open_interactive({
        \ 'caption'  : 'roseus',
        \ 'filetype' : 'lisp',
        \ 'buffer-open' : ':rightbelow split',
        \ 'proc'     : l:proc,
        \ 'pty'      : 1,
        \ 'exit-callback' : function('AddHistToFile'),
        \})
  let b:histfile = expand("~/.roseus_history")
  let b:histfilesize = 300
  call <SID>LoadHistFile()
  "" Unmap <C-p> and <C-n> in insert mode
""  iunmap <buffer><silent> <C-p>
""  iunmap <buffer><silent> <C-n>
  "" Map <Up> and <Down> to searching history in insert mode
  imap <buffer><silent> <Up> <Plug>(ieie_line_replace_history_prev)
  imap <buffer><silent> <Down> <Plug>(ieie_line_replace_history_next)
  "" Map <C-c> in insert and normal mode
  nnoremap <buffer><silent> <C-c> :call <SID>SendCtrlCToREPL()<CR>
  inoremap <buffer><silent> <C-c> <C-o>:call <SID>SendCtrlCToREPL()<CR>
  "" Map <C-f> and <C-b> in insert mode
  inoremap <buffer><silent> <C-f> <Esc>:call <SID>HistoryBeginningSearch(1)<CR>a
  inoremap <buffer><silent> <C-b> <Esc>:call <SID>HistoryBeginningSearch(0)<CR>a
  "" Display ANSI color
  if g:roseus_opened == 0
    AnsiEsc
    let g:roseus_opened = 1
  else
    AnsiEsc
    AnsiEsc
  endif
  setl concealcursor+=ic
endfunction
command! -nargs=? -complete=file Roseus :call Open_roseus(<f-args>)
command! -nargs=0 RoseusThis :call Open_roseus(expand("%:p"))
autocmd FileType lisp vmap <buffer> <F9> :call ieie#send_text_block(function('Open_roseus'), 'roseus')<CR>
"" python
function! Open_python(...)
  if a:0 == 0
    let l:proc = 'python'
  else
    let l:proc = 'python -i ' . a:1
  endif
  call ieie#open_interactive({
        \ 'caption'  : 'python',
        \ 'filetype' : 'python',
        \ 'buffer-open' : ':rightbelow split',
        \ 'proc'     : l:proc,
        \ 'pty'      : 1,
        \})
  "" Unmap <C-p> and <C-n> in insert mode
""  iunmap <buffer><silent> <C-p>
""  iunmap <buffer><silent> <C-n>
  "" Map <Up> and <Down> to searching history in insert mode
  imap <buffer><silent> <Up> <Plug>(ieie_line_replace_history_prev)
  imap <buffer><silent> <Down> <Plug>(ieie_line_replace_history_next)
  "" Map <C-c> in insert and normal mode
  nnoremap <buffer><silent> <C-c> :call <SID>SendCtrlCToREPL()<CR>
  inoremap <buffer><silent> <C-c> <C-o>:call <SID>SendCtrlCToREPL()<CR>
endfunction
command! -nargs=? -complete=file Python :call Open_python(<f-args>)
command! -nargs=0 PythonThis :call Open_python(expand("%:p"))
autocmd FileType python vmap <buffer> <F9> :call ieie#send_text_block(function('Open_python'), 'python')<CR>


function! s:Grep(command)
  let orig_grepprg = &l:grepprg
  let &l:grepprg = substitute(a:command, '|', '\\|', 'g')
  grep
  let &l:grepprg = orig_grepprg
endfunction

function! RosTopicList()
  vnew +enew
  r! rostopic list
endfunction
command! RosTopicList :call RosTopicList()

function! RosmsgShow(msg)
  vnew +enew
  let com="r! rosmsg show ".a:msg
  execute com
  echo a:msg
endfunction
command! -nargs=1 RosmsgShow :call RosmsgShow(<f-args>)

let g:ros_build_system = 'catkin-tools'
let g:ros_make = 'current'

autocmd FileType c,cpp setl cindent
autocmd FileType cpp setl cinoptions=i-s,N-s,g0

autocmd FileType python setl autoindent
autocmd FileType python setl smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
autocmd FileType python setl tabstop=8 expandtab shiftwidth=4 softtabstop=4

autocmd FileType lisp setl nocindent
autocmd FileType lisp setl lisp
autocmd FileType lisp setl showmatch
autocmd FileType lisp setl tabstop=8 expandtab shiftwidth=2 softtabstop=2
autocmd FileType lisp setl lispwords+=while,until

autocmd FileType make setl noexpandtab
