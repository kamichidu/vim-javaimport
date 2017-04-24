" The MIT License (MIT)
"
" Copyright (c) 2017 kamichidu
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.
if exists('g:loaded_javaimport_debug') && g:loaded_javaimport_debug
    finish
endif
let g:loaded_javaimport_debug= 1

let s:save_cpo= &cpo
set cpo&vim

let s:exclude_package_regex= '\C^\(com\.oracle\|com\.sun\|sun\|sunw\|org\.ietf\|org\.jcp\|org\.omg\|org\.w3c\|\org\.xml\)\.'

function! s:init(context) dict abort
    let self.__candidates= []
    let a:context.job= job_start(['go-javaimport', '-cp', expand('$JAVA_HOME/jre/lib/rt.jar'), '-sp', './src/main/java/'], {
    \   'out_cb': self.__out_cb,
    \   'err_cb': self.__err_cb,
    \})
    return self.__candidates
endfunction

function! s:out_cb(channel, message) dict abort
    let info= json_decode(a:message)
    if info.package !~# s:exclude_package_regex
        let self.__candidates+= [info]
    endif
endfunction

function! s:err_cb(channel, message) dict abort
    echomsg a:message
endfunction

function! s:async_init(context) dict abort
    let [self.__candidates, candidates]= [[], self.__candidates]
    return {
    \   'done': job_status(a:context.job) !=# 'run',
    \   'candidates': candidates,
    \}
endfunction

function! s:get_abbr(context, candidate) dict abort
    return printf('%s.%s', a:candidate.package, a:candidate.simpleName)
endfunction

function! s:accept(context, candidate) dict abort
    call milqi#exit()

    echomsg printf('import %s.%s;', a:candidate.package, a:candidate.simpleName)
endfunction

function! s:exit(context) dict abort
    if has_key(a:context, 'job')
        call job_stop(a:context.job)
    endif
endfunction

command! JavaImportDebug call milqi#candidate_first({
\   'name': 'java-import',
\   'init': function('s:init'),
\   'async_init': function('s:async_init'),
\   'get_abbr': function('s:get_abbr'),
\   'accept': function('s:accept'),
\   'exit': function('s:exit'),
\   '__out_cb': function('s:out_cb'),
\   '__err_cb': function('s:err_cb'),
\})

let &cpo= s:save_cpo
unlet s:save_cpo
