" Vim global plugin for fuzzy search
" Last Change:  2023 Jun 13
" Maintainer:   Eran Friedman
" License:      This file is placed in the public domain.


if exists("g:loaded_fuzzy")
  finish
endif
let g:loaded_fuzzy= 1


let s:save_cpo = &cpo
set cpo&vim


let s:prev_locations = []


function s:CloseBuffer(bufnr)
  wincmd p
  execute "bwipe" a:bufnr
  redraw
  return ""
endfunction


function s:Grep(flags, pattern, cur_file_only) abort
  " settings
  let l:grep_cmd = get(g:, 'fuzzy_grep_cmd', 'grep')
  let l:exclude_files = get(g:, 'fuzzy_exclude_files', '')

  let l:raw_pattern = a:pattern

  " prepare the command
  let l:regex = Regex(a:pattern)
  let l:pattern = shellescape(l:regex)
  let l:cmd = l:grep_cmd . " -ni " . a:flags  . " " . l:pattern
  if a:cur_file_only
    let l:cur_file = @%
    let l:cmd = l:cmd . " " . l:cur_file
  else
    let l:cmd = l:cmd . " * 2>/dev/null"
  endif

  let l:options = systemlist(l:cmd)

  " filter files
  if !empty(l:exclude_files)
    let l:filtered_options = []
    for i in range(0, len(l:options) - 1)
      let l:filename = split(l:options[i], ":")[0]
      let result = matchstr(l:filename, l:exclude_files)
      if empty(result)
        call add(l:filtered_options, l:options[i])
      endif
    endfor
    let l:options = l:filtered_options
  endif

  let l:prompt = "Cmd: '" . l:cmd . "'. Pattern: " . l:raw_pattern . " (" . len(l:options) . " matches)"
  return [l:options, l:prompt, l:pattern]
endfunction


function s:InteractiveMenu(input, prompt, pattern) abort
  bo new +setlocal\ buftype=nofile\ bufhidden=wipe\ nofoldenable\
    \ colorcolumn=0\ nobuflisted\ number\ norelativenumber\ noswapfile\ wrap\ cursorline

  " settings
  let l:fuzzy_menu_height = get(g:, 'fuzzy_menu_height', 15)
  let l:fuzzy_file_color = get(g:, 'fuzzy_file_color', "blue")
  let l:fuzzy_pattern_color = get(g:, 'fuzzy_pattern_color', "red")

  exe 'highlight filename_group ctermfg=' . l:fuzzy_file_color
  exe 'highlight pattern_group ctermfg=' . l:fuzzy_pattern_color
  match filename_group /^.*:\d\+:/
  call matchadd("pattern_group", a:pattern[1:-2]) " remove shellescape from pattern

  let l:cur_buf = bufnr('%')
  call setline(1, a:input)
  exe "res " . l:fuzzy_menu_height
  redraw
  echo a:prompt

  while 1
    try
      let ch = getchar()
    catch /^Vim:Interrupt$/ " CTRL-C
      return s:CloseBuffer(l:cur_buf)
    endtry

    if ch ==# 0x1B " ESC
      return s:CloseBuffer(l:cur_buf)
    elseif ch ==# 0x0D " Enter
      let l:result = getline('.')
      call s:CloseBuffer(l:cur_buf)
      return l:result
    elseif ch ==# 0x6B " k
      norm k
    elseif ch ==# 0x6A " j
      norm j
    elseif ch == "\<Up>"
      norm k
    elseif ch == "\<Down>"
      norm j
    elseif ch == "\<PageUp>"
      for i in range(1, l:fuzzy_menu_height)
        norm k
      endfor
    elseif ch == "\<PageDown>"
      for i in range(1, l:fuzzy_menu_height)
        norm j
      endfor
    endif

    redraw
  endwhile
endfunction


" format of str is <file>:<line number>:...
function s:ParseFileAndLineNo(str) abort
  let l:splitted_line = split(a:str, ":")
  let l:filename = l:splitted_line[0]
  let l:full_filename = fnamemodify(l:filename, ':p')
  let l:line_no = l:splitted_line[1]
  return [l:full_filename, l:line_no]
endfunction


function Regex(pattern) abort
  let l:chars = split(a:pattern, '\zs')
  let l:regex = join(l:chars, ".*")
  return l:regex
endfunction


" main function - do a fuzzy search
function FuzzySearchMenu(flags, pattern, cur_file_only) abort
  let l:res = s:Grep(a:flags, a:pattern, a:cur_file_only)
  let l:options = l:res[0]
  let l:prompt = l:res[1]
  let l:pattern = l:res[2]

  " user selection
  let l:selected_line = s:InteractiveMenu(l:options, l:prompt, l:pattern)
  if empty(l:selected_line)
    return
  endif

  " process selection
  let l:splitted_line = split(l:selected_line, ":")
  " if we grep in current file only, some grepping tools omit the file name
  if a:cur_file_only && l:splitted_line[0] !=# l:cur_file
    let l:filename = l:cur_file
    let l:line_no = l:splitted_line[0]
  else
    let l:filename = l:splitted_line[0]
    let l:line_no = l:splitted_line[1]
  endif

  " store previous location to allow jumping back
  call add(s:prev_locations, [line("."), expand('%:p')])

  " jump to selection
  execute 'edit +' . l:line_no l:filename
endfunction


" Jump back to previous location
function FuzzyBack()
  if empty(s:prev_locations)
    echo "No previous location"
    return
  endif

  let l:prev_loc = remove(s:prev_locations, -1)
  execute 'edit +' . l:prev_loc[0] l:prev_loc[1]
endfunction


" regular (non-interactive) fuzzy search
function FuzzySearch(pattern)
  let l:regex = Regex(a:pattern)
  let l:cmd = "/\\c" . l:regex . "\<CR>"
  call feedkeys(l:cmd)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
