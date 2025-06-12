#!/bin/bash
# Take a local backup of files and databases

# Variables
now=$(date +"%m_%d_%Y")

# Removing backups older than 7 days
find /backup/ -type f -mtime +7 -name '*.tar.gz' -execdir rm -- '{}' \;

# Files backup
mkdir -p /backup/files
tar -cpzf "/backup/files-$now.tar.gz" /var/www
rm -rf /backup/files/*

# Databases backup
mkdir -p /backup/databases
mysql -N -e 'show databases' | grep -vE "information_schema|performance_schema|mysql|sys" | while read dbname
do mysqldump --complete-insert --routines --triggers --single-transaction "$dbname" > /backup/databases/"$dbname".sql
done
tar -cpzf "/backup/databases-$now.tar.gz" /backup/databases
rm -rf /backup/databases/*