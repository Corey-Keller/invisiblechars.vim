" ============================================================
" Name: invisiblechars.vim
" Author: Corey Keller
" Web: https://github.com/corey-keller/invisiblechars.vim
" Modification Date: 2020-01-24
" License: Mozilla Public License, Version 2.0
" This Source Code Form is subject to the terms of the Mozilla Public
" License, v. 2.0. If a copy of the MPL was not distributed with this
" file, You can obtain one at http://mozilla.org/MPL/2.0/.
" ============================================================

if get(g:, 'autoloaded_invisiblechars')
	finish
endif

function! invisiblechars#show() abort "{{{1
	if !get(g:, 'invisiblechars_ran_init')
		call invisiblechars#_init()
	endif

	if empty(get(g:, 'invisiblechars#list#override',{}))
		let g:invisiblechars_list = g:invisiblechars#extended_font ?
		\ g:invisiblechars#list#extend : g:invisiblechars#list#noextend
	else
		let g:invisiblechars_list = g:invisiblechars#list#override
	endif

	set listchars=""

	let l:char_count=0

	for char in keys(g:invisiblechars_list)
		let show_char_var = 'invisiblechars#show#' . char

		if !index(['conceal', 'eol', 'extends', 'nbsp', 'precedes',
		\ 'space', 'tab', 'trail'], char)
			echoerr 'The value ''' . char . ''' is not a valid listchars' .
			\ ' type. To see valid types run ":help ''listchars''"'
			continue
		elseif (!has('conceal') && char ==# 'conceal')
			echomsg 'The ''conceal'' value is being ignored because '.
			\ 'you don''t have the conceal feature.'
			continue
		endif

		" If we want to force all invisible characters to be visible
		" then we set all g:invisiblechars#show#* variables to one (1)
		if get(g:, 'invisiblechars#show#all_force')
			let g:{show_char_var} = 1

		" If we want to show characters by default then we set any
		" currently unset variables to one (1)
		elseif get(g:, 'invisiblechars#show#all')
			let g:{show_char_var} =  get(g:, show_char_var, 1)

		" Otherwise we get the value of the variable, defaulting to
		" zero (0). We don't have to specify the default value here
		" because get() defaults it to 0 if it is omitted.
		else
			let g:{show_char_var} =  get(g:, show_char_var)
		endif

		" If the g:invisiblechars#show# variable is one (1) for the
		" current character type then add it to the listchars option
		if g:{show_char_var}
			if l:char_count
				let l:listchars_string = ',' . char
			else
				let l:listchars_string = char
				let l:char_count+=1
			endif
			let &listchars.=l:listchars_string . ':' .
			\ get(g:invisiblechars_list, char)
		endif
	endfor

	" If we don't want to show tabs, but we do want to see our indentation
	" levels, set the 'tab' listchar to g:invisiblechars#indent_chars
	if (!get(g:, 'invisiblechars#show#tab') &&
	\ get(g:, 'invisiblechars#show#indent'))
		if l:char_count
			let l:listchars_string = ',tab:'
		else
			let l:listchars_string = 'tab:'
			let l:char_count+=1
		endif
		let &listchars.=l:listchars_string . g:invisiblechars#indent_chars
	endif

	if !get(g:, 'invisiblechars_ran_wrapup')
		call invisiblechars#_wrapup()
	endif

	" Don't display the trailing space character while in insert mode.
	" To override set g:invisiblechars#show#trail_ins to one (1)
	augroup InvisibleCharsNoTrailInsMode
		" Remove all auto-commands from the group, so that it isn't
		" added a second time if we re-source the file
		autocmd!
		if has_key(g:invisiblechars_list, 'trail')
			if !get(g:, 'invisiblechars#show#trail_ins')
				autocmd InsertEnter * :execute 'set listchars-=trail:' .
				\ get(g:invisiblechars_list, 'trail')
				autocmd InsertLeave * :execute 'set listchars+=trail:' .
				\ get(g:invisiblechars_list, 'trail')
			endif
		endif
	augroup END
endfunction "}}}1

function! invisiblechars#_init() abort "{{{1
	" Don't rerun this unless the user manually sets the variable
	" to zero (0)
	if get(g:, 'invisiblechars_ran_init')
		return
	endif

	" The 'g:invisiblechars#extended_font' variable is used to set if we
	" have a unicode font available
	if !exists('g:invisiblechars#extended_font')
		let g:invisiblechars#extended_font = get(g:, 'extended_font')
	endif

	if empty(get(g:, 'invisiblechars#list#extend',{}))
		let g:invisiblechars#list#extend = {
		\'tab' : '«-»',
		\'space' : '·',
		\'nbsp' : '␣',
		\'extends' : '❯',
		\'precedes':'❮',
		\'trail':'□',
		\}
	endif

	if empty(get(g:, 'invisiblechars#list#noextend',{}))
		let g:invisiblechars#list#noextend = {
		\'tab' : '<->',
		\'space' : '`',
		\'nbsp' : '+',
		\'extends' : '>',
		\'precedes':'<',
		\'trail':'~',
		\}
	endif

	" if !exists('g:invisiblechars#list#override')
	" 	let g:invisiblechars#list#override = {}
	" endif

	let g:invisiblechars_list = {}

	let g:invisiblechars#indent_chars = get(g:,
	\ 'invisiblechars#indent_chars',
	\ g:invisiblechars#extended_font?'⁞ ':'| ')

	" Re-call 'invisiblechars#show' whenever 'list' is set
	augroup InvisibleCharsUpdListChars
		" Remove all auto-commands from the group, so that it isn't
		" added a second time if we re-source the file
		autocmd!
		autocmd OptionSet list call invisiblechars#show()
	augroup END

	let g:invisiblechars_ran_init = 1
endfunction "}}}1

function! invisiblechars#_wrapup() abort "{{{1
	" Don't rerun this unless the user manually sets the variable
	" to zero (0)
	if get(g:, 'invisiblechars_ran_wrapup')
		return
	endif

	for name in ['all', 'all_force', 'conceal', 'eol', 'extends',
	\ 'indent', 'nbsp', 'precedes', 'space', 'tab', 'trail', 'trail_ins']
		let show_var_name = 'invisiblechars#show#' . name
		let g:{show_var_name} =  get(g:, show_var_name)
	endfor
	let g:invisiblechars_ran_wrapup = 1
endfunction "}}}1

let g:autoloaded_invisiblechars = 1

" vim:set filetype=vim:
