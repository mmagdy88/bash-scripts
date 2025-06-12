#!/bin/bash
# Adding DMARC record to multiple domains

# Instructions
# 1. Create list of domains in the file /root/domains
# 2. Run the script

whmapi1 --output=jsonpretty get_domain_info | grep parent_domain | awk {' print $3 '} | sed "s/\"//g" | sed "s/,//g" > /root/domains.txt

file="/root/domains.txt"

for i in `cat $file`
do
    grep -iq dmarc /var/named/$i.db
    sed -ie '/dmarc/s/^/;/' /var/named/$i.db
    #sed -i "/DMARC/d" /var/named/$i.db
    echo "_dmarc     14400     IN     TXT     \"v=DMARC1; p=reject; rua=mailto:postmaster@$i, mailto:dmarc@$i; pct=100; adkim=s; aspf=s\"" >> /var/named/$i.db
    named-checkzone $i /var/named/$i.db
if [ $? = "0" ]; then
    echo "$i changed successfully."
else
    echo "Error in $i."
    exit;
fi
done