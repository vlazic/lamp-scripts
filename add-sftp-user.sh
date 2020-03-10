#!/bin/bash

# this script adds SFTP user and restrict his access to specific directory
# you can use it to limit SFTP user access to specific web site under /var/www
# tested on Ubuntu 18.04

SSH_CONFIG=/etc/ssh/sshd_config
VSFTPD_CONFIG=/etc/vsftpd.conf
BACKUP_DIR=/var/local/sftp-user/backups/$(date +%F)

echo "Enter SFTP user you want to create: "
read -r SFTP_USER

echo "Enter name of group this user shoud be added to: "
read -r SFTP_GROUP

# create user
adduser --ingroup="$SFTP_GROUP" --shell=/sbin/nologin --no-create-home "$SFTP_USER"

echo "Enter location where '${SFTP_USER}' will have access to: "
read -r SFTP_FOLDER

mkdir -p "$SFTP_FOLDER"

# install `vsftpd` if it is not already installed
apt install vsftpd

# change folder permissions
chown -R "$SFTP_GROUP":"$SFTP_GROUP" "$SFTP_FOLDER"
chown root:root "$SFTP_FOLDER"

# create backup of ssh
mkdir -p "${BACKUP_DIR}"
cp $VSFTPD_CONFIG $SSH_CONFIG "${BACKUP_DIR}"
echo "Backup of $VSFTPD_CONFIG and $SSH_CONFIG files are created in ${BACKUP_DIR} directory"

# uncomment following line in file /etc/vsftpd.conf
# chroot_local_user=YES
sed -i '0,/^#chroot_local_user=YES/{s/^#chroot_local_user=YES/chroot_local_user=YES/}' $VSFTPD_CONFIG

# comment out following line:
# Subsystem sftp /usr/lib/openssh/sftp-server
sed -i "s|^Subsystem sftp /usr|#Subsystem sftp /usr|" $SSH_CONFIG

# add at the bottom ssh config file
grep "Subsystem sftp internal-sftp" $SSH_CONFIG || echo "Subsystem sftp internal-sftp" >>$SSH_CONFIG
cat >>$SSH_CONFIG <<EOF
Match user ${SFTP_USER}
    ChrootDirectory ${SFTP_FOLDER}
    ForceCommand internal-sftp
    PasswordAuthentication yes
    AllowTcpForwarding no
EOF

# restart services
service vsftpd restart
service sshd restart
