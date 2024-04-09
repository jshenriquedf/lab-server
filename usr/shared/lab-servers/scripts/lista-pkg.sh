#!/bin/bash

# CONTROLE-VERSION 20240401

# Este script lista os pacotes instalados dentro do arquivo /etc/pkgs.txt, com
# a data atual, para o controle por parte do sistema de backup.
#
# Este arquivo deverá estar em cron.

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

DATACTRL=$(date '+%Y%m%d')
FILECTRL=/etc/pkgs.txt

echo $DATACTRL > $FILECTRL
dpkg -l >> $FILECTRL
