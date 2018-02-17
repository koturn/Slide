" <C-x> ヒント表示
let s:compl_key_dict = {
      \ char2nr("\<C-l>"): "\<C-x>\<C-l>",
      \ char2nr("\<C-n>"): "\<C-x>\<C-n>",
      \ char2nr("\<C-p>"): "\<C-x>\<C-p>",
      \ char2nr("\<C-k>"): "\<C-x>\<C-k>",
      \ char2nr("\<C-t>"): "\<C-x>\<C-t>",
      \ char2nr("\<C-i>"): "\<C-x>\<C-i>",
      \ char2nr("\<C-]>"): "\<C-x>\<C-]>",
      \ char2nr("\<C-f>"): "\<C-x>\<C-f>",
      \ char2nr("\<C-d>"): "\<C-x>\<C-d>",
      \ char2nr("\<C-v>"): "\<C-x>\<C-v>",
      \ char2nr("\<C-u>"): "\<C-x>\<C-u>",
      \ char2nr("\<C-o>"): "\<C-x>\<C-o>",
      \ char2nr('s'): "\<C-x>s",
      \ char2nr("\<C-s>"): "\<C-x>s"
      \}
let s:hint_i_ctrl_x_msg = join([
      \ '<C-l>: While lines',
      \ '<C-n>: keywords in the current file',
      \ "<C-k>: keywords in 'dictionary'",
      \ "<C-t>: keywords in 'thesaurus'",
      \ '<C-i>: keywords in the current and included files',
      \ '<C-]>: tags',
      \ '<C-f>: file names',
      \ '<C-d>: definitions or macros',
      \ '<C-v>: Vim command-line',
      \ "<C-u>: User defined completion ('completefunc')",
      \ "<C-o>: omni completion ('omnifunc')",
      \ "s: Spelling suggestions ('spell')"
      \], "\n")
function! s:hint_i_ctrl_x() abort
  let more_old = &more
  set nomore
  echo s:hint_i_ctrl_x_msg
  let &more = more_old
  let c = getchar()
  return get(s:compl_key_dict, c, nr2char(c))
endfunction
inoremap <expr> <C-x>  <SID>hint_i_ctrl_x()


" レジスタ・マークヒント表示
function! s:hint_cmd_output(prefix, cmd) abort
  redir => str
    execute a:cmd
  redir END
  let more_old = &more
  set nomore
  echo str
  let &more = more_old
  return a:prefix . nr2char(getchar())
endfunction
nnoremap <expr> m  <SID>hint_cmd_output('m', 'marks')
nnoremap <expr> `  <SID>hint_cmd_output('`', 'marks')
nnoremap <expr> '  <SID>hint_cmd_output("'", 'marks')
nnoremap <expr> "  <SID>hint_cmd_output('"', 'registers')
nnoremap <expr> q  <SID>hint_cmd_output('q', 'registers')
nnoremap <expr> @  <SID>hint_cmd_output('@', 'registers')


" 既存ウィンドウに移動するコマンド
if exists('*win_gotoid')
  " Vim8.0以降用
  function! s:buf_open_existing(qmods, bname) abort
    let bnr = bufnr(a:bname)
    if bnr == -1
      throw 'E94: No matching buffer for ' . a:bname
    endif
    let wids = win_findbuf(bnr)
    if empty(wids)
      execute a:qmods 'new'
      execute 'buffer' bnr
    else
      call win_gotoid(wids[0])
    endif
  endfunction
  command! -bar -nargs=1 -complete=buffer Buffer  call s:buf_open_existing(<q-mods>, <f-args>)
else
  " Vim8.0以前用
  function! s:buf_open_existing(bname) abort
    let bnr = bufnr(a:bname)
    if bnr == -1
      throw 'E94: No matching buffer for ' . a:bname
    endif
    let tindice = map(filter(map(range(1, tabpagenr('$')), '{"tindex": v:val, "blist": tabpagebuflist(v:val)}'), 'index(v:val.blist, bnr) != -1'), 'v:val.tindex')
    if empty(tindice)
      new
      execute 'buffer' bnr
    else
      execute 'tabnext' tindice[0]
      execute bufwinnr(bnr) 'wincmd w'
    endif
  endfunction
  command! -bar -nargs=1 -complete=buffer Buffer  call s:buf_open_existing(<f-args>)
endif


" 各タブのウィンドウ・バッファ情報一覧表示コマンド
function! s:show_tab_info() abort
  echo "====== Tab Page Info ======"
  let current_tnr = tabpagenr()
  let winid2bufnr_dict = s:create_winid2bufnr_dict()
  for tnr in range(1, tabpagenr('$'))
    let current_winnr = tabpagewinnr(tnr)
    echo (tnr == current_tnr ? '>' : ' ') 'Tab:' tnr
    echo '    Buffer number | Window Number | Window ID | Buffer Name'
    for wininfo in map(map(range(1, tabpagewinnr(tnr, '$')), '{"wnr": v:val, "wid": win_getid(v:val, tnr)}'), 'extend(v:val, {"bnr": winid2bufnr_dict[v:val.wid]})')
      echo '   ' (wininfo.wnr == current_winnr ? '*' : ' ') printf('%11d | %13d | %9d | %s', wininfo.bnr, wininfo.wnr, wininfo.wid, bufname(wininfo.bnr))
    endfor
  endfor
endfunction
command! -bar TabInfo call s:show_tab_info()
