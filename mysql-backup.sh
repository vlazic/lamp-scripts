#!/usr/bin/env bash

# Author: Vladimir Lazic - contact@vlazic.com - 2017

# Create file /usr/local/etc/mysql-backup.conf
# and in each line add database info in following format:
# DB_USER1 DB_PASS1 DB_NAME1
# DB_USER2 DB_PASS2 DB_NAME2

# Add cron job similar to this:
# 15 */6 * * * /usr/local/bin/mysql-backup 2>&1 | /usr/bin/ts >> /var/log/mysql-backup.log
# for 'ts' (prefix each log line with date) first install 'moreutils' package

# Change thi value if you want to change how many days you want to keep all backups.
# One backup file of each of the previous months will be kept anyways.
KEEP_BACKUP_DAYS=15

# Location of files and folders
LOG_FILE="/var/log/mysql-backup.log"
CONF_FILE="/usr/local/etc/mysql-backup.conf"
BACKUP_FOLDER="/var/local/mysql-backup"

CURRENT_TIME=$(date +"%Y-%m-%d-%H-%M")
THIS_MONTH=$(date +"%Y/%m")
PAST_MONTH=$(date --date="$(date +%Y-%m-15) -1 month" +%Y/%m)

CONF_HELP_MESSAGE="
For each database create line in ${CONF_FILE} with the following format:
DB_USER DB_PASS DB_NAME"

# Check if all nessesary files and folders exist, if not create them
[ ! -f $CONF_FILE ] && {
    touch $CONF_FILE
    chmod 600 $CONF_FILE
    echo "$CONF_HELP_MESSAGE"
    exit 1
}
[ ! -f $LOG_FILE ] && touch $LOG_FILE
[ ! -d $BACKUP_FOLDER ] && mkdir -p $BACKUP_FOLDER

# Run backup process for each database
cat $CONF_FILE | while read -r CONFIG_LINE; do

    DB_USER=$(echo "${CONFIG_LINE}" | cut -d' ' -f1)
    DB_PASS=$(echo "${CONFIG_LINE}" | cut -d' ' -f2)
    DB_NAME=$(echo "${CONFIG_LINE}" | cut -d' ' -f3)

    BACKUP_PATH=$BACKUP_FOLDER/$DB_NAME/$THIS_MONTH

    mkdir -p "${BACKUP_FOLDER}/${DB_NAME}"
    cd "${BACKUP_FOLDER}/${DB_NAME}" || return

    # Delete all but one file in
    if [ -d "${PAST_MONTH}" ]; then
        DO_NOT_DELETE=$(find "${PAST_MONTH}" -type f -printf '%T@ %f\n' | sort | cut -d' ' -f2 | tail -n 1)
        find "${PAST_MONTH}" -mtime +"${KEEP_BACKUP_DAYS}" -type f -not -name "${DO_NOT_DELETE}" -exec rm {} \;
    fi

    mkdir -p "${BACKUP_PATH}"

    BACKUP_FILE="${BACKUP_PATH}/${DB_NAME}-${CURRENT_TIME}.sql.gz"

    (ionice -c2 -n6 mysqldump --user="${DB_USER}" --password="${DB_PASS}" "${DB_NAME}" | gzip >"${BACKUP_FILE}") &&
        echo "Database '${DB_NAME}' has been successfully saved here: ${BACKUP_FILE}"

done
