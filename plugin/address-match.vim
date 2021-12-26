" vim:set ts=4 sts=0 sw=4 ai et sr tw=0:
"
" address-match.vim: match MAC and IPv4 addresses, convert MAC styles
" Last Change: Dec 26, 2021 (comments only; prior change Mar 12, 2019)
" Maintainer: Greg Paris <gregory at paris dot name>
" Copyright (C) 2019 Gregory M Paris
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}

" Module Information {{{
" This module does search matches of the following types:
"   Traditional colon-style MAC addresses of the form xx:xx:xx:xx:xx:xx (ignoring case)
"   Cisco dot-style MAC addresses of the form xxxx.xxxx.xxxx (ignoring case)
"   IPv4 addresses of the form ddd.ddd.ddd.ddd, with each octet restricted to 0-255
"   CIDR blocks of the form ddd.ddd.ddd.ddd/pfxlen, with pfxlen restricted to 0-32
"   IPv4 private addresses and CIDR blocks
"   IPv4 special and reserved addresses and CIDR blocks (all lumped together)
"   IPv4 public addresses and CIDR blocks
" It can convert colon-style MACs to dot-style MACs and vice-versa
"   When converting, dot-style MACs are generated in lowercase
" It can convert uppercase colon-style MACs to lowercase MACs vice-versa
"
" Creates :xxx command registration aliases for the AddressMatch() function.
"   Set g:address_match_no_commands to disable.
" Creates <leader>xxx normal mode key mappings for match and convert operations.
"   Set g:address_match_no_mappings to disable.
" Creates text objects for all address types using the textobj-user plugin is loaded.
"   Set g:address_match_no_textobj to disable.
" }}}

" VARIABLES NAMING SCHEME {{{
"   g:address_match         top-level dictionary containing all global definitions
"       .<address_type>     2nd level dictionaries, one for each address type
"           .look_behind    negative lookbehind base_pattern to minimize false matches
"           .look_ahead     negative lookahead base_pattern to minimize false matches
"           .base_pattern   match base_pattern including lookahead/behind and escaped bars (\|)
"           .pattern        pattern with \v prepended and bars unescaped, for convenient use
"           .search         /base_pattern/
"           .topsearch      gg/base_pattern/<cr>
" }}}

" Housekeeping {{{
if exists('g:loaded_address_match')
    finish
endif
let g:loaded_address_match = 1
" }}}

" s:DotToColon function {{{
" Change dot-style MAC to colon style
" Optional second argument causes uppercasing if truthy
function! s:DotToColon(dot,...)
    let octets = []
    for g in [0, 1, 2]
        let ofs = 5 * g
        let octets += [a:dot[ofs : ofs+1], a:dot[ofs+2 : ofs+3]]
    endfor
    let colon = join(octets, ':')
    if a:0 > 0 && a:1
        let colon = toupper(colon)
    else
        let colon = tolower(colon)
    endif
    return colon
endfunction
" }}}

" s:ColonToDot function {{{
" Change colon-style MAC to dot-style (always lowercase)
function! s:ColonToDot(colon)
    let octets = []
    for n in [0, 1, 2, 3, 4, 5]
        let ofs = 3 * n
        call add(octets, tolower(a:colon[ofs:ofs+1]))
    endfor
    let dot = join([octets[0].octets[1], octets[2].octets[3], octets[4].octets[5]], '.')
    return dot
endfunction
" }}}

" s:FixBars function {{{
" Allow our base_patterns above to be used in let @/ = statements
" by un-escaping the bar characters in the patterns.
function! s:FixBars(str)
    return substitute(a:str, '\\|', '\|', 'g')
endfunction
" }}}

let g:address_match = {}

" Non-global convenience definitions {{{
let s:cr = '<cr>'
" let s:bscr = "\<cr>"
let s:bsv = '\v'
let s:last = 'G$'
" NOTE: Everything named *search is a /\v<base_pattern> string (no <cr>).
let s:search = '/' . s:bsv
let s:search_end = '/'
" NOTE: Everything named *top_search is a G$/\v<base_pattern>/<cr> string.
let s:top_search = s:last . s:search
let s:top_search_end = '/' . s:cr
let s:hex4 = '\x{4}'
let s:hex4_dot = '%('. s:hex4 .'[.])'
let s:hex2 = '\x\x'
let s:hex2_colon = '%('. s:hex2 .':)'
let s:dec_octet = '%(25[0-6]\|2[0-4]\d\|1\d\d\|[1-9]\d\|\d)'
let s:dec_octet_dot = '%('. s:dec_octet .'[.])'
" }}}

" Prefix length specification for CIDR {{{
" No separate look_behind needed for CIDR block because IPv4 already has it.
" The look_ahead is for the prefix length specification, so call it that.
" We don't want to match /digits/ as a possible prefix length specification.
let g:address_match.pfxlen = {}
let g:address_match.pfxlen.look_ahead = '[0-9/]@!'
let g:address_match.pfxlen.specification = '%([/]%(3[012]\|[12]\d\|\d))'
let g:address_match.pfxlen.base_pattern = '%('. g:address_match.pfxlen.specification . g:address_match.pfxlen.look_ahead .')'
let g:address_match.pfxlen.pattern = s:bsv . s:FixBars(g:address_match.pfxlen.base_pattern)
" }}}

" Cisco dot-style MAC address matching {{{
let g:address_match.dot_mac = {}
let g:address_match.dot_mac.look_behind = '%(\x\|[.])@<!'
let g:address_match.dot_mac.look_ahead = '%([.]?\x)@!'
let g:address_match.dot_mac.base_pattern = '%('. g:address_match.dot_mac.look_behind . s:hex4_dot .'{2}'. s:hex4 . g:address_match.dot_mac.look_ahead .')'
let g:address_match.dot_mac.pattern = s:bsv . s:FixBars(g:address_match.dot_mac.base_pattern)
let g:address_match.dot_mac.search =  s:search . g:address_match.dot_mac.base_pattern . s:search_end
let g:address_match.dot_mac.top_search =  s:top_search . g:address_match.dot_mac.base_pattern . s:top_search_end
" }}}

" Traditional colon-style MAC address matching {{{
let g:address_match.colon_mac = {}
let g:address_match.colon_mac.look_behind = '%(\x\|[.])@<!'
let g:address_match.colon_mac.look_ahead = '%(:?\x)@!'
let g:address_match.colon_mac.base_pattern = '%('. g:address_match.colon_mac.look_behind . s:hex2_colon .'{5}'. s:hex2 . g:address_match.colon_mac.look_ahead .')'
let g:address_match.colon_mac.pattern = s:bsv . s:FixBars(g:address_match.colon_mac.base_pattern)
let g:address_match.colon_mac.search = s:search . g:address_match.colon_mac.base_pattern . s:search_end
let g:address_match.colon_mac.top_search = s:top_search . g:address_match.colon_mac.base_pattern . s:top_search_end
" }}}

" Either style MAC address matching {{{
let g:address_match.any_mac = {}
let g:address_match.any_mac.base_pattern = '%('. g:address_match.dot_mac.base_pattern .'\|'. g:address_match.colon_mac.base_pattern .')'
let g:address_match.any_mac.pattern = s:bsv . s:FixBars(g:address_match.any_mac.base_pattern)
let g:address_match.any_mac.search = s:search . g:address_match.any_mac.base_pattern . s:search_end
let g:address_match.any_mac.top_search = s:top_search . g:address_match.any_mac.base_pattern . s:top_search_end
" }}}

" All IPv4 address matching (no block exclusions) {{{
" Note: Will match the IP portion of a CIDR block.
let g:address_match.ipv4 = {}
let g:address_match.ipv4.look_behind = '[0-9.]@<!'
let g:address_match.ipv4.look_ahead = '%([.]?\d)@!'
let g:address_match.ipv4.base_pattern = '%('. g:address_match.ipv4.look_behind . s:dec_octet_dot.'{3}'. s:dec_octet . g:address_match.ipv4.look_ahead .')'
let g:address_match.ipv4.pattern = s:bsv . s:FixBars(g:address_match.ipv4.base_pattern)
let g:address_match.ipv4.search = s:search . g:address_match.ipv4.base_pattern . s:search_end
let g:address_match.ipv4.top_search = s:top_search . g:address_match.ipv4.base_pattern . s:top_search_end
" }}}

" All CIDR block matching (no block exclusions) {{{
let g:address_match.cidr = {}
let g:address_match.cidr.base_pattern = '%('. g:address_match.ipv4.base_pattern . g:address_match.pfxlen.base_pattern .')'
let g:address_match.cidr.pattern = s:bsv . s:FixBars(g:address_match.cidr.base_pattern)
let g:address_match.cidr.search = s:search . g:address_match.cidr.base_pattern . s:search_end
let g:address_match.cidr.top_search = s:top_search . g:address_match.cidr.base_pattern . s:top_search_end
" }}}

" Match any style MAC, IPv4 address or CIDR block {{{
let g:address_match.any_address = {}
let g:address_match.any_address.base_pattern = '%('. join([g:address_match.colon_mac.base_pattern, g:address_match.dot_mac.base_pattern, g:address_match.cidr.base_pattern, g:address_match.ipv4.base_pattern], '\|') .')'
let g:address_match.any_address.pattern = s:bsv . s:FixBars(g:address_match.any_address.base_pattern)
let g:address_match.any_address.search = s:search . g:address_match.any_address.base_pattern . s:search_end
let g:address_match.any_address.top_search = s:top_search . g:address_match.any_address.base_pattern . s:top_search_end
" }}}

" RFC-1918 IPv4 private addresses and CIDR blocks {{{
" NOTE: Does not judge whether prefix lengths make sense.
let g:address_match.private = {}
let g:address_match.private.10_block = '%(10.'. s:dec_octet_dot.'{2}' . s:dec_octet .')'
let g:address_match.private.172_16_block = '%(172.%(1[6-9]\|2\d\|3[01]).' . s:dec_octet_dot . s:dec_octet .')'
let g:address_match.private.192_168_block = '%(192.168.' . s:dec_octet_dot . s:dec_octet .')'
let s:private_list = [g:address_match.private.10_block, g:address_match.private.172_16_block, g:address_match.private.192_168_block]
let g:address_match.private.blocks = '%(' . join(s:private_list, '\|') .')'
let g:address_match.private.base_pattern = '%('. g:address_match.ipv4.look_behind . g:address_match.private.blocks . g:address_match.ipv4.look_ahead . g:address_match.pfxlen.base_pattern .'?)'
let g:address_match.private.pattern = s:bsv . s:FixBars(g:address_match.private.base_pattern)
let g:address_match.private.search = s:search . g:address_match.private.base_pattern . s:search_end
let g:address_match.private.top_search = s:top_search . g:address_match.private.base_pattern . s:top_search_end
" }}}

" Special IPv4 addresses and CIDR blocks: link local, loopback, multicast, reserved {{{
" NOTE: There are other reserves, but they're too special to list.
" NOTE: Does not judge whether prefix lengths make sense.
let g:address_match.special = {}
let g:address_match.special.zero_block = '%(0.'. s:dec_octet_dot.'{2}' . s:dec_octet .')'
let g:address_match.special.local_block = '%(169.254.' . s:dec_octet_dot . s:dec_octet .')'
let g:address_match.special.loopback_block = '%(127.'. s:dec_octet_dot.'{2}' . s:dec_octet .')'
let g:address_match.special.multicast_block = '%(2%(2[4-9]\|3\d).' . s:dec_octet_dot.'{2}' . s:dec_octet .')'
" NOTE: Next definition has the (desired) effect of excluding netmasks.
let g:address_match.special.reserved_block = '%(2%(4\d\|5[0-5]).' . s:dec_octet_dot.'{2}' . s:dec_octet .')'
let s:special_list = [g:address_match.special.zero_block, g:address_match.special.local_block, g:address_match.special.loopback_block, g:address_match.special.multicast_block, g:address_match.special.reserved_block]
let g:address_match.special.blocks = '%(' . join(s:special_list, '\|') .')'
let g:address_match.special.base_pattern = '%('. g:address_match.ipv4.look_behind . g:address_match.special.blocks . g:address_match.ipv4.look_ahead . g:address_match.pfxlen.base_pattern .'?)'
let g:address_match.special.pattern = s:bsv . s:FixBars(g:address_match.special.base_pattern)
let g:address_match.special.search = s:search . g:address_match.special.base_pattern . s:search_end
let g:address_match.special.top_search = s:top_search . g:address_match.special.base_pattern . s:top_search_end
" }}}

" Public IPv4 addresses and CIDR blocks (ie, excludes private and special) {{{
" Works by using negative look_ahead of excluded address blocks.
" NOTE: Does not judge whether prefix lengths make sense.
let g:address_match.public = {}
let s:exclude_list = s:private_list + s:special_list
let g:address_match.public.exclude_blocks = '%(' . join(s:exclude_list, '\|') .')'
let g:address_match.public.begin_look_ahead = '%('. g:address_match.ipv4.look_behind . g:address_match.public.exclude_blocks . g:address_match.ipv4.look_ahead .')@!'
let g:address_match.public.base_pattern = '%('. g:address_match.ipv4.look_behind . g:address_match.public.begin_look_ahead . g:address_match.ipv4.base_pattern . g:address_match.ipv4.look_ahead . g:address_match.pfxlen.base_pattern .'?)'
let g:address_match.public.pattern = s:bsv . s:FixBars(g:address_match.public.base_pattern)
let g:address_match.public.search = s:search . g:address_match.public.base_pattern . s:search_end
let g:address_match.public.top_search = s:top_search . g:address_match.public.base_pattern . s:top_search_end
" }}}

" AddressMatch function {{{
" Match MAC addresses, positioning at first.
" NOTE: Does not highlight reliably, but does match.
function! s:AddressMatch(style)
    let fc = a:style[0]
    let ft = a:style[:1]
    if fc ==? '.' || fc == 'd'
        let pat = g:address_match.dot_mac.base_pattern
    elseif fc ==? ':' || fc ==? 'c'
        let pat = g:address_match.colon_mac.base_pattern
    elseif fc ==? 'm'
        let pat = g:address_match.any_mac.base_pattern
    elseif fc ==? 'i'
        let pat = g:address_match.ipv4.base_pattern
    elseif fc ==? 'b' || ft ==? 'su'
        let pat = g:address_match.cidr.base_pattern
    elseif ft ==? 'pr'
        let pat = g:address_match.private.base_pattern
    elseif ft ==? 'pu'
        let pat = g:address_match.public.base_pattern
    elseif ft ==? 'sp'
        let pat = g:address_match.special.base_pattern
    elseif fc ==? '*'
        let pat = g:address_match.any_address.base_pattern
    else
        echom 'AddressMatch argument must be .,:,m,i,b,pr,pu,sp or *'
        return 0
    endif
    execute 'normal! ' . s:last
    let @/ = s:bsv . s:FixBars(pat)
    execute 'normal! n'
endfunction
" }}}

" Optional command registrations for AddressMatch() {{{
" Set g:address_match_no_commands to disable.
if !exists('g:address_match_no_commands')
    command! -register MDM call s:AddressMatch('dot')
    command! -register MCM call s:AddressMatch('colon')
    command! -register MAM call s:AddressMatch('mac')
    command! -register MIP call s:AddressMatch('ip')
    command! -register MIS call s:AddressMatch('block')
    command! -register MBL call s:AddressMatch('block')
    command! -register MPR call s:AddressMatch('private')
    command! -register MPU call s:AddressMatch('public')
    command! -register MSP call s:AddressMatch('special')
    command! -register MAA call s:AddressMatch('*')
endif
" }}}

" Optional normal mode keystroke mappings using <leader> {{{
" Set g:address_match_no_mappings to disable.
if !exists('g:address_match_no_mappings')
    " mdm, mcm, mam - match dot/colon/any MAC
    execute 'nnoremap <silent> <leader>mdm ' . g:address_match.dot_mac.top_search
    execute 'nnoremap <silent> <leader>mcm ' . g:address_match.colon_mac.top_search
    execute 'nnoremap <silent> <leader>mam ' . g:address_match.any_mac.top_search
    " dtc, dtC - dot to colon MAC lowercase/uppercase, then match all colon MACs
    execute 'nnoremap <silent> <leader>dtc :%s'.g:address_match.dot_mac.search .'\=<SID>DotToColon(submatch(0))'.s:top_search_end . g:address_match.colon_mac.top_search
    execute 'nnoremap <silent> <leader>dtC :%s'.g:address_match.dot_mac.search .'\=<SID>DotToColon(submatch(0),1)'.s:top_search_end . g:address_match.colon_mac.top_search
    " ctd - colon to dot (always lowercase), then match all dot MACs
    execute 'nnoremap <silent> <leader>ctd :%s'.g:address_match.colon_mac.search .'\=<SID>ColonToDot(submatch(0))'.s:top_search_end . g:address_match.dot_mac.top_search
    " ctl, ctu - colon to lowercase/uppercase, then match all colon MACs
    execute 'nnoremap <silent> <leader>ctl :%s'.g:address_match.colon_mac.search .'\=tolower(submatch(0))'.s:top_search_end . g:address_match.colon_mac.top_search
    execute 'nnoremap <silent> <leader>ctu :%s'.g:address_match.colon_mac.search .'\=toupper(submatch(0))'.s:top_search_end . g:address_match.colon_mac.top_search
    " mip, mis - match IP address or subnet (CIDR block)
    execute 'nnoremap <silent> <leader>mip ' . g:address_match.ipv4.top_search
    execute 'nnoremap <silent> <leader>mis ' . g:address_match.cidr.top_search
    execute 'nnoremap <silent> <leader>mbl ' . g:address_match.cidr.top_search
    " maa - match any address
    execute 'nnoremap <silent> <leader>maa ' . g:address_match.any_address.top_search
    " mpr - private IPv4 addresses
    execute 'nnoremap <silent> <leader>mpr ' . g:address_match.private.top_search
    " msp - special IPv4 addresses: link local, loopback, multicast, reserved
    execute 'nnoremap <silent> <leader>msp ' . g:address_match.special.top_search
    " mpu - public IPv4 addresses (i.e., no private or special)
    execute 'nnoremap <silent> <leader>mpu ' . g:address_match.public.top_search
endif
" }}}

" Optional addressmatch textobj definition {{{
" Skipped if textobj_user plugin is not installed.
" Set g:address_match_no_textobj to disable.
" select - selects the (next) address
" move-n - moves to the beginning of the next address
" move-p - moves to the beginning of the previous address
" NOTE: These commands to not wrap beyond the bottom/top of the buffer.
if !exists('g:address_match_no_textobj')
    call textobj#user#plugin('addressmatch', {
    \   'dot_mac':      {'pattern': g:address_match.dot_mac.pattern,    'select': 'adm', 'move-n': '<localleader>dm', 'move-p': '<localleader>DM', },
    \   'colon_mac':    {'pattern': g:address_match.colon_mac.pattern,  'select': 'acm', 'move-n': '<localleader>cm', 'move-p': '<localleader>CM', },
    \   'any_mac':      {'pattern': g:address_match.any_mac.pattern,    'select': 'aam', 'move-n': '<localleader>am', 'move-p': '<localleader>AM', },
    \   'ipv4':         {'pattern': g:address_match.ipv4.pattern,       'select': 'aip', 'move-n': '<localleader>ip', 'move-p': '<localleader>IP', },
    \   'any_address':  {'pattern': g:address_match.any_address.pattern,'select': 'aaa', 'move-n': '<localleader>aa', 'move-p': '<localleader>AA', },
    \   'private':      {'pattern': g:address_match.private.pattern,    'select': 'apr', 'move-n': '<localleader>pr', 'move-p': '<localleader>PR', },
    \   'public':       {'pattern': g:address_match.public.pattern,     'select': 'apu', 'move-n': '<localleader>pu', 'move-p': '<localleader>PU', },
    \   'special':      {'pattern': g:address_match.special.pattern,    'select': 'asp', 'move-n': '<localleader>sp', 'move-p': '<localleader>SP', },
    \   'cidr':         {'pattern': g:address_match.cidr.pattern,       'select': ['ais', 'abl'],
    \       'move-n': ['<localleader>is', '<localleader>bl'], 'move-p': ['<localleader>IS', '<localleader>BL'], },
    \ })
endif
" }}}
"
