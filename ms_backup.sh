#!/bin/bash
# Take a daily local backup and transfer it to S3 Bucket
# Remove backups older than 3 days from local storage

# Checking to see if LiteSpeed Web Server is installed
if [ ! -d /usr/local/lsws ]; then
    echo "This script works with LSWS (LiteSpeed Web Server) only, please install it first then try again."
    exit 1
fi

date_now=$(date "+%H-%M-%d-%m-%Y")

# Remove older backups
find /backup/ -type f -mtime +3 -exec rm -f {} \;

# Changing current directory to backup
cd /backup

# Looping through Databases and Dumping each one of them to SQL files with the domain name
for DB in `mysql -D mysql -e 'SELECT Db from db;' | awk {' print $1 '} | grep -v Db`
do
    mysqldump $DB > $DB.sql
done

# Checking if we're in the correct directory
tar -cf databases-$date_now.tar *.sql
rm -rf *.sql

# Looping through LiteSpeed Web Server configuration file, extracting domain names and compressing them
for domain in `grep "<vhost>" /usr/local/lsws/conf/httpd_config.xml | sed -n 's:.*<vhost>\(.*\)</vhost>.*:\1:p' | grep -Eo '[^.]+\.[^.]+$' | sort | uniq`
do
    tar -cf $domain-$date_now.tar /usr/local/lsws/$domain
done

# Optional: if you want to transfer backup to AWS S3 bucket
# First you need to install AWS CLI and authorize your account
for backup in `find /backup/ -type f -mmin -720`
do
    /usr/local/bin/aws s3 cp $backup s3://BUCKET_NAME/DIRECTORY/ --profile PROFILENAME
done