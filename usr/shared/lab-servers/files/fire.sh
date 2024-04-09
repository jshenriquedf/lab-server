#!/bin/bash

# CONTROLE-VERSION 20240401

# Este script é chamado por /etc/network/interfaces
# v20240401 by Jose Henrique

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

iptables -F
iptables -t nat -F

########################
### Segurança básica ###
########################
