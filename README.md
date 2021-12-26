Match IPv4 addresses and MAC addresses (colon- and dot-styles)

This module does search matches of the following types:
* Traditional colon-style MAC addresses of the form *xx:xx:xx:xx:xx:xx* (ignoring case)
* Cisco dot-style MAC addresses of the form *xxxx.xxxx.xxxx* (ignoring case)
* IPv4 addresses of the form *ddd.ddd.ddd.ddd*, with each octet restricted to 0-255
* CIDR blocks of the form *ddd.ddd.ddd.ddd/pfxlen*, with pfxlen restricted to 0-32
* IPv4 private addresses and CIDR blocks
* IPv4 special and reserved addresses and CIDR blocks (all lumped together)
* IPv4 public addresses and CIDR blocks

It can convert colon-style MACs to dot-style MACs and vice-versa
* When converting, dot-style MACs are generated in lowercase

It can convert uppercase colon-style MACs to lowercase MACs and vice-versa

Creates *:xxx* command registration aliases for **AddressMatch()** function.
* Set **g:address_match_no_commands** to disable.
Creates *<leader>xxx* normal mode key mappings for match and convert operations.
* Set **g:address_match_no_mappings** to disable.
Creates text objects for all address types using the **kana/vim-textobj-user** plugin.
* Set **g:address_match_no_textobj** to disable.
