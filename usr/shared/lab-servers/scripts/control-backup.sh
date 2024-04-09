#!/bin/bash

# CONTROLE-VERSION 20240401

# Este script cria o arquivo /etc/lab-backup-control, com a data atual, para o
# controle por parte do sistema de backup.
#
# Este arquivo deverá estar em cron.

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

DATACTRL=$(date '+%Y%m%d')
FILECTRL=/etc/lab-backup-control

echo $DATACTRL > $FILECTRL
