#!/bin/bash
# This script is to take a local back and transfer it to a remote destination using rsync

# Defining variables
localbackup='/local/path/'
remotebackup='/remote/path/'
lockbox='REMOTEIP'
remoteuser='REMOTEUSER'

# Executing command
rsync -arzopug $localbackup $remoteuser@$lockbox:$remotebackup --delete 2>&1 >> /dev/null

# Adjusting permissions on remote server
ssh root@$lockbox "chown -R USER:USER /remote/path/*"

# Exporting database
mysqldump DB_NAME > /tmp/DB_NAME.sql

# Transferring database to remote server
rsync -arzopug /tmp/DB_NAME.sql $remoteuser@$lockbox:/root/ 2>&1 >> /dev/null

# Restoring database on remote server and cleaning up
ssh root@$lockbox "mysql DB_NAME < /root/DB_NAME.sql"
ssh root@$lockbox "rm -rf /root/DB_NAME.sql"