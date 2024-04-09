#!/bin/bash

# CONTROLE-VERSION 20240401

# Copyright 2024-2024 GECIB
# Copyright 2024-2024 Jose Henrique da Silva <jose.henrique@brb.com.br>
#
# Este codigo eh de uso restrito à Gerencia de Monitoração e Resposta a Incidentes
# Cibernéticos - GECIB. A sua divulgacao ou utilizacao, sem previa autorizacao escrita,
# nao estah autorizada. Para mais informacoes, contacte a GECIB.
#
# Este script realiza a configuração básica de servidores de rede do GECIB.
#
# Para fazer a exclusão de determinadas configurações especiais em alguns
# servidores, crie o arquivo /etc/gecib-control com a linha
# EXCLUDE-OPTIONS=yes

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

REF="lab-servers"

DIR_ROOT="/usr/share/${REF}"
DIR_ETC="/etc/${REF}"
DIR_ADMIN="/etc/adm"
DIR_BACKUP="/var/backups/${REF}"

CONF_CA="${DIR_ROOT}/ca"
CONF_FILES="${DIR_ROOT}/files"
CONF_GPG_KEYS="${DIR_ROOT}/keys"
CONF_CONFIG="${DIR_ROOT}/config"
CONF_SCRIPTS="${DIR_ROOT}/scripts"

# Teste sobre a necessidade de substituição de arquivos
#
function verify () {
    # Zera variável
    TROCA=0
    # Verifica existência de arquivo
    [ -e ${DIR}/${FILE} ] || return
    # IVERSION = Versão Instalada
    IVERSION=$(cat ${DIR}/${FILE} | grep CONTROLE-VERSION | cut -d" " -f3)
    [ ! ${IVERSION} ] && IVERSION=0
    # NVERSION = Versão Nova
    NVERSION=$(cat ${CONF_CONFIG}/${FILE} | grep CONTROLE-VERSION | cut -d" " -f3)
    # Decisão
    if [ "${IVERSION}" -lt "${NVERSION}" ]; then TROCA=1; fi
}

# Faz backup de arquivos existentes
#
function backup () {
    EPOCH=$(date '+%s')
    [ -e ${DIR}/${FILE} ] || return

    # Cria o arquivo de bckup caso não exista
    [ ! -e ${DIR_BACK} ] && mkdir ${DIR_BACK} && chmod 700 ${DIR_BACK}

    cp ${DIR}/${FILE} ${DIR_BACK}/${FILE}.${EPOCH}
    chmod 000 ${DIR_BACK}/${FILE}.${EPOCH}
    logger "GECIB - Realizado backup de ${DIR}/${FILE}."
}

# Realiza a troca dos arquivos
#
function novo () {
    echo "novo"
    PERMS1=644
    OWNER1=root
    GROUP1=root
    cp -f ${CONF_CONFIG}/${FILE} ${DIR}/${FILE}
    chmod $PERMS1 ${DIR}/${FILE}
    chown $OWNER1:$GROUP1 ${DIR}/${FILE}
    logger "GECIB - Aplicando as permissões necessárias no arquivo ${DIR}/${FILE}."
}

# Realiza a troca dos arquivos
#
function troca () {
    [ ! -e ${DIR}/${FILE} ] && eval novo && return

    PERMS1=$(stat -c "%a" ${DIR}/${FILE})
    OWNER1=$(stat -c "%U" ${DIR}/${FILE})
    GROUP1=$(stat -c "%G" ${DIR}/${FILE})
    cp -f ${CONF_CONFIG}/${FILE} ${DIR}/${FILE}
    chmod $PERMS1 ${DIR}/${FILE}
    chown $OWNER1:$GROUP1 ${DIR}/${FILE}
    logger "GECIB - Aplicando as permissões necessárias no arquivo ${DIR}/${FILE}."
}

###################################################

# Criação de swap
#
if [ ! -e /swapfile ]; then
    echo -e "\nCriando arquivo de swap com 2GB."
    dd if=/dev/zero of=/swapfile bs=128M count=8
    mkswap -f /swapfile
    chmod 600 /swapfile
    echo "/swapfile  none  swap  sw  0  0" >> /etc/fstab
    swapon -a
    logger "GECIB - Criado arquivo de swap."
fi

# Remoção de usuários pre-existentes
#
USERS=$(ls /home)
if [ "${USERS}" ]; then
    for USER in ${USERS} ; do
        [[ ${USER} ]] || break
        if [ $(cat /etc/passwd | grep "${USER}") ]; then
            echo -e "\n\nRemovendo o usuário ${USER}."
            userdel -r ${USER}
            logger "GECIB - Removido o usuário ${USER}."
        fi
    done
fi

# Substituição do /etc/sysctl.d/swappiness.conf
#
DIR=/etc/sysctl.d
FILE=swappiness.conf
verify
#
if [ ${TROCA} ] && [ -f ${CONF_CONFIG}/${FILE} ]
then
    echo -e "\nAdicionando/Substituindo o arquivo ${DIR}/${FILE}."
    backup
    troca
    sysctl -p ${DIR}/${FILE}
    logger "GECIB - Adicionando/Substituido o arquivo ${DIR}/${FILE}"
fi

# Substituição do /etc/bash.bashrc
# sudo apt install linuxlogo
DIR=/etc
FILE=bash.bashrc
verify
#
if [ ${TROCA} ] && [ -f ${CONF_CONFIG}/${FILE} ]
then
    echo -e "\nAdicionando/Substituindo o arquivo ${DIR}/${FILE}."
    backup
    troca
    source ${DIR}/${FILE}
    logger "GECIB - Adicionando/Substituido o arquivo ${DIR}/${FILE}"
fi

# Substituição do /etc/ssh/sshd_config/sshd_gecib.conf
#
DIR="/etc/ssh/sshd_config.d"
FILE="sshd_gecib.conf"
verify
#
if [ ${TROCA} ] && [ -e ${CONF_CONFIG}/${FILE} ]
then
    echo -e "\nAdicionando/Substituindo o arquivo ${DIR}/${FILE}."
    backup
    troca
    logger "GECIB - Adicionando/Substituido o arquivo ${DIR}/${FILE}"
    systemctl restart ssh
fi

# Substituição do /etc/apt/sources.list
#
DIR=/etc/apt
FILE=sources.list
verify
#
if [ ${TROCA} ] && [ -e ${CONF_CONFIG}/${FILE} ]
then
    echo -e "\nAdicionando/Substituindo o arquivo ${DIR}/${FILE}."
    backup
    troca
    logger "GECIB - Adicionando/Substituindo o arquivo ${DIR}/${FILE}"
fi

# Substituição do /etc/default/grub
#
DIR=/etc/default
FILE=grub
verify
#
if [ ${TROCA} ] && [ -e ${CONF_CONFIG}/${FILE} ]
then
    echo -e "\nAdicionando/Substituindo o arquivo ${DIR}/${FILE}."
    backup
    troca
    update-grub
    logger "GECIB - Adicionando/Substituindo o arquivo ${DIR}/${FILE}"
fi

# Substituição de chaves SSH, sem backup
#
DIR=/root/.ssh
FILE=authorized_keys
#
if [ ! -e ${CONF_CONFIG}/${FILE} ]
then
    echo -e "\n\nCriando o arquivo ${DIR}/${FILE}."
    mkdir -p ${DIR}
    chmod 700 ${DIR}
    > "${DIR}/${FILE}"
    logger "GECIB - Criado o arquivo ${DIR}/${FILE}"
fi

verify
#
if [ ${TROCA} ]
then
    echo -e "\nSubstituindo o arquivo ${DIR}/${FILE}."
    chattr -i "${DIR}/${FILE}"
    troca
    # Altera o arquivo, caso o servidor em questão seja da rede externa
    #    SERVERN=$(hostname | egrep '(stella|brian)')
    #    if [ "$SERVERN" ]
    #    then
    #      cat $DIR/$FILE | sed 's/^from="/from="177.15.130.90,/' > /tmp/$FILE
    #      mv /tmp/$FILE "${DIR}/${FILE}"
    #    fi
    chmod 400 "${DIR}/${FILE}"
    chattr +i "${DIR}/${FILE}"
    logger "GECIB - Substituido o arquivo ${DIR}/${FILE}"
fi

# Substituição do /etc/systemd/timesyncd.conf
# sudo apt install systemd-timesyncd -y
DIR=/etc/systemd/
FILE=timesyncd.conf
verify
#
if [ ${TROCA} ] && [ -e ${CONF_CONFIG}/${FILE} ]
then
    echo -e "\n\nSubstituindo o arquivo ${DIR}/${FILE}."
    backup
    troca

    timedatectl set-timezone America/Sao_Paulo
    timedatectl set-ntp true
    service systemd-timesyncd restart
    localectl set-locale LC_TIME=pt_BR.UTF-8
    export LC_TIME="pt_BR.UTF-8"
    logger "GECIB - Substituido o arquivo ${DIR}/${FILE}"
fi


# Substituição do /etc/chrony//chrony.conf
# sudo apt-get install chrony -y
#DIR=/etc/chrony/
#FILE=chrony.conf
#verify
#
#if [ ${TROCA} ] && [ -e ${CONF_CONFIG}/${FILE} ]
#then
#    echo -e "\n\nSubstituindo o arquivo ${DIR}/${FILE}."
#    backup
#    troca

#    service chrony restart

#    timedatectl set-timezone America/Sao_Paulo
#    timedatectl set-ntp true
#    service systemd-timesyncd restart
#    localectl set-locale LC_TIME=pt_BR.UTF-8
#    export LC_TIME="pt_BR.UTF-8"
#    logger "GECIB - Substituido o arquivo ${DIR}/${FILE}"
#fi

# Configuração do APT para ignorar traduções
#
DIR=/etc/apt
FILE=apt.conf
verify
#
if [ "$TROCA" -eq 1 ]
then
    echo -e "\n\nSubstituindo o arquivo ${DIR}/${FILE}."
    backup
    troca

    logger "GECIB - Substituido o arquivo ${DIR}/${FILE}"
    echo -e "\n\nRemovendo arquivos de traducao existentes.\n\n"
    rm -f /var/lib/apt/lists/*i18n*
elif [ ! -e ${DIR}/${FILE} ]
then
    echo -e "\n\nCriando o arquivo ${DIR}/${FILE}.\n\n"
    cp -f "${CONF_CONFIG}/${FILE}" ${DIR}/${FILE}
    logger "GECIB - Criado o arquivo ${DIR}/${FILE}"
    echo -e "\n\nRemovendo arquivos de traducao existentes.\n\n"
    rm -f /var/lib/apt/lists/*i18n*
fi

# Carrega as chaves GPG existentes
# apt-get -y install gnupg
#FILE1=/etc/gecib.gpg.ctrl
#FILE2=${CONF_GPG_KEYS}/VERSAO

#[ -e ${FILE1} ] || echo 0 > ${FILE1}

#VAR1=$(cat ${FILE1} | grep 0)
#VAR2=$(cat ${FILE2} | grep 0)

#if [ "${VAR1}" -lt "${VAR2}" ]
#then
#    cat ${FILE2} > ${FILE1}
#    gpg --import-options import-minimal --import ${GPGKEYS}/*
#    logger "GECIB - Carregadas novas chaves GPG"
#    echo -e "\n\nCarregadas novas chaves GPG.\n\n"
#fi

# Adiciona a chave GPG do repositório BRB
#
#TEST=$(apt-key list 2> /dev/null | grep BRB)
#
#if [ ! "$TEST" ]
#then
#    apt-key add $GPGKEYS/BRB-repo_....
#    logger "GECIB - Adicionada a chave do servidor de pacotes"
#    echo -e "\n\nAdicionada a chave do servidor de pacotes.\n\n"
#fi

# Adiciona servidor de log, caso necessário
#
#FILE=/etc/rsyslog.conf
#TESTE=$(cat $FILE | grep server)
#
#if [ ! "$TESTE" ]
#then
#    echo -e "\n#Adicionado servidor central de logs:" >> $FILE
#    echo "*.* @server" >> $FILE
#    systemctl restart rsyslog
#    echo -e "\n\nAdicionado servidor central de logs.\n\n"
#fi

# Instala o certificado do Lab GECIB

#FILE=/usr/local/share/ca-certificates/lab.crt
#TESTE=$(ls $FILE 2> /dev/null)

#[ "$TESTE" ] || { cp $CAFILE/* /usr/local/share/ca-certificates/; \
#                  update-ca-certificates; \
#                  logger "GECIB - Adicionado certificado do LAB pelo CA Certificates"; \
#                  echo -e "\n\nAdicionado o certificado do LAB pelo CA Certificates.\n\n"; }

############################################
# MANTER NO FIM DO ARQUIVO DE CONFIGURAÇÃO #
############################################

# Mensagem para servidores especiais

#if [ "$EXCLUSAO" ]
#then
#    echo -e "\n\n\n\nVerifique e atualize os seguintes arquivos:\n"
#    echo -e "/etc/apt/sources.list\n/root/.ssh/authorized_keys\n/etc/default/ntpdate\n"
#fi
