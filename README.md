# fuzzy.vim

Add fuzzy search capabilities to your *Vi* editor.

This Vim plugin is written in pure *vimscript* and doesn't have any dependencies.
It enables you to perform a fuzzy search in current file
or recursively in all files.

## Installation

- Install using your favorite package manager, e.g., [Vundle](https://github.com/VundleVim/Vundle.vim):

    1. Add the following to your *.vimrc*: `Plugin 'eranfrie/fuzzy.vim'`.
    2. Reload .vimrc.
    3. Run: `:PluginInstall`.

- Manual installation: copy *fuzzy.vim* to your plugin directory
    (e.g., *~/.vim/plugin/* in Unix / Mac OS X).

## Functions:

- `FuzzySearch(pattern)` -
perform a fuzzy search of *pattern* in the current file.
The search is case-insensitive.

- `FuzzySearchMenu(flags, pattern, cur_file_only)` -
perform an interactive fuzzy search (case-insensitive),
where `flags` is optional grep flags (can be empty string),
`pattern` is the pattern to search for
and `cur_file_only` is whether to search in current file only or not (set to `1`/`0` accordingly).
All matches will be presented in a selection menu.
Use the following keys to interact with the menu:
`j`, `k`, `Down`, `Up`, `PageDown`, `PageUp`, `Enter`, `Esc`, `Ctrl-C`.

- `FuzzyBack()` -
jump back to previous location.

## Customizations:

- Change the default *grep* tool. For example, use *git grep*:
```
let g:fuzzy_grep_cmd = "git grep"
```

- Exclude files using Vim's regex
```
let g:fuzzy_exclude_files = "<regex>"
```
  E.g., exclude files stsarting witth *test* or containing *simulation*:
```
let g:fuzzy_exclude_files = "^test\\|simulation"
```

- Set the height (number of lines) of the selection menu
```
let g:fuzzy_menu_height = 15
```

- Set the color of the file path of the results in the selection menu
```
let g:fuzzy_file_color = "blue"
```

- Set the color of the matched pattern in the results in the selection menu
```
let g:fuzzy_pattern_color = "red"
```

- Disable loading the plugin
```
let g:loaded_fuzzy = 1
```

## Mappings:

Keys are not automatically mapped. You can choose your own mappings, for example:
```
" perform a regular search by :F <pattern>
command! -bar -nargs=1 F call FuzzySearch(<q-args>)

" interative search -
" search in current file by :Fsf <pattern>
command -bang -nargs=* Fsf call FuzzySearchMenu("", expand(<q-args>), 1)
" search recursively :Fsf <pattern> (note the additional `-r` flag)
command -bang -nargs=* Fsa call FuzzySearchMenu("-r", expand(<q-args>), 0)
" return to previous location
nnoremap <leader>o :call FuzzyBack()<CR>
```

Instead, you can use *git grep* (`-r` is not required):
```
let g:fuzzy_grep_cmd = "git grep"
command -bang -nargs=* Fsf call FuzzySearchMenu("", expand(<q-args>), 1)
command -bang -nargs=* Fsa call FuzzySearchMenu("", expand(<q-args>), 0)
```
