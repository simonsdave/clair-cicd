set ruler
set hlsearch
filetype plugin on
set ts=4
set sw=4
set expandtab
set encoding=UTF8
syntax on
au BufNewFile,BufRead *.raml set filetype=raml
au BufNewFile,BufRead *.json set filetype=json
au BufNewFile,BufRead *.yaml set filetype=yaml
autocmd Filetype shell setlocal expandtab tabstop=4 shiftwidth=4
autocmd Filetype python setlocal expandtab tabstop=4 shiftwidth=4
autocmd FileType raml setlocal expandtab tabstop=2 shiftwidth=2
autocmd FileType yaml setlocal expandtab tabstop=2 shiftwidth=2
