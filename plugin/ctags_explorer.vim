" File: ctags_explorer.vim
" Author: Pablo Cerda
" Description: Library of functions to explore ctags.

if exists('g:loaded_ctags_explorer')
    finish
endif
let g:loaded_ctags_explorer = 1

let s:save_cpo = &cpo
set cpo&vim

if executable('sqlite')
  let s:sqlite = 'sqlite'
elseif executable('sqlite3')
  let s:sqlite = 'sqlite3'
endif

" Execute a sqlite SQL query.
function! s:exec_query(query, options)
  let s:cmd = printf('%s tags.sqlite %s "%s"', s:sqlite, a:options, a:query)
  let s:output = system(s:cmd)

  " Log executed message.
  echom s:cmd
  if v:shell_error && s:output !=# ""
    echohl Error | echon s:output | echohl None
    return -1
  endif
  return s:output
endfunction

" Escape SQL query parameter.
function! s:param_escape(val)
  return "'" . escape(a:val, "'\"") . "'"
endfunction

" Find the parent classes for a class.
function! ctags_explorer#find_parents(class_name, namespace)
  let s:query = "SELECT tags2db_inherits FROM tags_php WHERE tags2db_kind = 'c'" .
        \ " AND tags2db_tagname = %s AND tags2db_namespace LIKE %s;"
  " Complete the arguments of the query.
  let s:query_final = printf(s:query, s:param_escape(a:class_name),
        \ s:param_escape('%' . a:namespace))
  " Execute the query.
  let s:response = s:exec_query(s:query_final, '')

  " If command execution was successful we have the parents
  " but when class implements an interface will be received
  " with multiples parents separated by comma.
  " TODO: Implement comma split and recursive parents lookup.
  if s:response != -1
    return s:response
  endif
endfunction

" List all namespaced classes from tags sqlite DB.
function! ctags_explorer#list_classes()
  let s:query = "SELECT tags2db_namespace, tags2db_tagname FROM tags_php WHERE tags2db_kind IN ('c', 't');"
  " Execute the query.
  let s:response = s:exec_query(s:query, '-separator ''\''')

  if s:response != -1
    return s:response
  endif
endfunction

" List all functions from tags sqlite DB.
function! ctags_explorer#list_functions()
  let s:query = "SELECT tags2db_namespace, tags2db_tagname FROM tags_php WHERE tags2db_kind = 'f';"
  " Execute the query.
  let s:response = s:exec_query(s:query, '-separator ''\''')

  if s:response != -1
    return s:response
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
