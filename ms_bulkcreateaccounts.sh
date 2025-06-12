#!/bin/bash
# Bash script to create multiple websites running on cPanel/WHM
# Working at any OS running cPanel/WHM

# Instructions:
# 1. Create a list consists of 2 columns, 1st column (website name) and 2nd column (username)
# 2. Add that list in websites.txt file in the current directory then run the script

IFS=$'\n';
for WEBSITE in $(cat websites.txt); do
    DOMAIN=$(echo ${WEBSITE} | awk '{print $1}')
    USERNAME=$(echo ${WEBSITE} | awk '{print $2}')
    PASS=`mkpasswd -l 12 -s 5`
    FILE="website-data.txt"
    whmapi1 createacct username=$USERNAME domain=$DOMAIN password=$PASS bwlimit=0 dkim=1 hasshell=0 quota=0 spf=1 > /dev/null 2>&1 &
    echo "$DOMAIN created successfully"
    touch $FILE
    echo "Domain name: $DOMAIN" >> $FILE
    echo "Username: $USERNAME" >> $FILE
    echo "Password: $PASS" >> $FILE
    echo "" >> $FILE
done

echo
echo
cat $FILE