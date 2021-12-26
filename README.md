# vim-address-match
Match IPv4 addresses and MAC addresses (colon- and dot-styles)

This plugin enables search matches of the following types:
* Traditional colon-style MAC addresses of the form *xx:xx:xx:xx:xx:xx* (ignoring case)
* Cisco dot-style MAC addresses of the form *xxxx.xxxx.xxxx* (ignoring case)
* IPv4 addresses of the form *d.d.d.d*, with each decimal octet restricted to 0-255
* IPv4 CIDR blocks of the form *d.d.d.d/pfxlen*, with pfxlen restricted to 0-32
* IPv4 private addresses and CIDR blocks (i.e., within blocks 10/8, 172.16/12, 192.168/16)
* IPv4 special and reserved addresses and CIDR blocks (all lumped together)
* IPv4 public addresses and CIDR blocks

In addition to matching the patterns noted above, the plugin enables the following.
* Conversion of colon-style MACs to dot-style MACs and vice-versa.
(Note: when converting, dot-style MACs always are generated in lowercase.)
* Conversion of uppercase colon-style MACs to lowercase MACs and vice-versa.

The plugin defines the following command registrations and key mappings.
* Creates *:xxx* command registration aliases for the `AddressMatch()` function.
(Set **g:address_match_no_commands** to disable.)
* Creates `<leader>xxx` normal mode key mappings for match and convert operations.
(Set **g:address_match_no_mappings** to disable.)
* Creates text objects for all address types using the **kana/vim-textobj-user** plugin,
establishing key mappings for search and selection.
(Set **g:address_match_no_textobj** to disable.)

## Command-mode registrations
Unless **g:address_match_no_commands** is set, the following commands will be registered.

### MAC address matching
*   `:MCM`  MAC address colon-style match
*   `:MDM`  MAC address dot-style match
*   `:MAM`  MAC address any-style match

### IPv4 address and address-block matching
*   `:MIP`  IPv4 address match
*   `:MBL`  IPv4 address block match (i.e., CIDR match *n.n.n.n/p*)
*   `:MIS`  IPv4 subnet match (same as `MBL` above)
*   `:MPR`  IPv4 private address/block match (i.e., 10/8, 172.16/12, 192.168/16)
*   `:MSP`  IPv4 special address/block match (i.e., multicast, reserved)
*   `:MPU`  IPv4 public address/block match (neither private nor special)

## Normal-mode mappings using `<leader>`
Unless **g:address_match_no_mappings** is set, the following VIM normal-mode mappings
will be defined.

### MAC address matching and manipulation
* `<leader>mcm` MAC address colon-style match
* `<leader>mdm` MAC address dot-style match
* `<leader>mam` MAC address any-style match
* `<leader>dtc` MAC address dot- to lower-case colon-style conversion, then match as with `mcm`
* `<leader>dtC` MAC address dot- to upper-case colon-style conversion, then match as with `mcm`
* `<leader>ctd` MAC address colon- to lower-case dot-style conversion, then match as with `mdm`
* `<leader>ctl` MAC address colon-style to lower-case conversion, then match as with `mcm`
* `<leader>ctu` MAC address colon-style to upper-case conversion, then match as with `mcm`

### IPv4 address and CIDR matching
* `<leader>mip` IPv4 address match
* `<leader>mbl` IPv4 address block match (i.e., CIDR match *n.n.n.n/p*)
* `<leader>mis` IPv4 subnet match (same as `mbl` above)
* `<leader>maa` IPv4 any address/block match
* `<leader>mpr` IPv4 private address/block match (i.e., 10/8, 172.16/12, 192.168/16)
* `<leader>msp` IPv4 special address/block match (i.e., multicast, reserved)
* `<leader>mpu` IPv4 public address/block match (neither private nor special)

## MAC addresses and IPv4 addresses/blocks as text objects
Leveraging the
[kana/vim-textobj-user](https://github.com/kana/vim-textobj-user)
plugin, this plugin can treat MAC addresses and IPv4 addresses and address-blocks as textj objects.
This provides a set of motion-commands that can be used in conjunction with actions such as delete
and yank. It also establishes a set of navigation commands, leveraging the `<localleader>` character.

If the **vim-textobj-user** plugin is not installed, or if **g.address_match_no_textobj** is set,
text object functionality will be disabled.

If **g.textobj_addressmatch_no_default_key_mappings** set to True, the key mappings below will not
be established. (In other words `:TextobjAddressmatchDefaultKeyMappings` will not be executed
automatically.)

### TextobjAddressmatch selection key mappings
In all of the following cases, the `op` (yank, delete, etc.) will be executed upon the selected text
object. That object will be the one under the cursor or the next one in the buffer. The search will
not wrap to the beginning of the buffer. The cursor will be left positioned at the beginning of the
text object.
*   `{op}acm`   perform `op` on current/next colon-style MAC
*   `{op}adm`   perform `op` on current/next dot-style MAC
*   `{op}aam`   perform `op` on current/next any-style MAC
*   `{op}aip`   perform `op` on current/next IPv4 address
*   `{op}abl`   perform `op` on current/next IPv4 CIDR block
*   `{op}ais`   perform `op` on current/next IPv4 subnet (same as `abl`)
*   `{op}aaa`   perform `op` on current/next IPv4 address or block
*   `{op}apr`   perform `op` on current/next IPv4 private address or block
*   `{op}apu`   perform `op` on current/next IPv4 public address or block
*   `{op}asp`   perform `op` on current/next IPv4 special address or block

### TextobjAddressmatch movement key mappings
In all of the following cases, the cursor will move to the beginning of the next matching text
object. The search will not wrap to the beginning (or in the case of reverse search, end) of the
buffer.
*   `<localleader>cm`, `<localleader>CM`    forward, backward to colon-style MAC
*   `<localleader>dm`, `<localleader>DM`    forward, backward to dot-style MAC
*   `<localleader>am`, `<localleader>AM`    forward, backward to any-style MAC
*   `<localleader>ip`, `<localleader>IP`    forward, backward to IPv4 address
*   `<localleader>bl`, `<localleader>BL`    forward, backward to IPv4 CIDR block
*   `<localleader>is`, `<localleader>IS`    forward, backward to IPv4 subnet (same as `bl`, `BL`)
*   `<localleader>aa`, `<localleader>aa`    forward, backward to any IPv4 address/block
*   `<localleader>pr`, `<localleader>pr`    forward, backward to private IPv4 address/block
*   `<localleader>pr`, `<localleader>pu`    forward, backward to public IPv4 address/block
*   `<localleader>sp`, `<localleader>sp`    forward, backward to special IPv4 address/block

## Matching pattern definitions
The regular expressions used to match MAC addresses and IPv4 addresses and blocks are available in
the following global variables.
*   **g:address_match.dot_mac.pattern** - dot-style MAC address
*   **g:address_match.colon_mac.pattern** - colon-style MAC address
*   **g:address_match.any_mac.pattern** - any-style MAC address
*   **g:address_match.ipv4.pattern** - IPv4 address
*   **g:address_match.any_address.pattern** - IPv4 address or address-block (CIDR)
*   **g:address_match.private.pattern** - IPv4 private address (aka, RFC-1918)
*   **g:address_match.public.pattern** - IPv4 public addresses (neither public nor special)
*   **g:address_match.special.pattern** - IPv4 special addresses (multicast, reserved)
*   **g:address_match.cidr.pattern** - IPv4 address block in CIDR notation, *n.n.n.n/p*
