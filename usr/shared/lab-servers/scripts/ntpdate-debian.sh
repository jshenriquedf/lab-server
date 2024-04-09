#!/bin/sh

# CONTROLE-VERSION 20240401

# Este script faz a atualização de hora na
# máquina virtual e na real, se for o caso.

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ATUALIZA=0
NOME=$(hostname | grep base-)

test -x /usr/sbin/ntpdate-debian || { logger "NTPDATE-DEBIAN: command not found, exiting"; exit 0; }

ntpdate-debian > /dev/null && { ATUALIZA=1; logger "NTPDATE-DEBIAN: updating the VM time"; }

if [ "$ATUALIZA" -eq 1 ]
then
    [ $NOME ] && { hwclock -w > /dev/null; logger "NTPDATE-DEBIAN: updating the real machine time"; }
fi
