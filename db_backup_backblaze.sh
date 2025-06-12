#!/bin/bash
# A bash script to dump all databases and transfer them to Backblaze b2

mysqldump -A -R -E --triggers --single-transaction > /root/db-all.sql
cd /root && tar -cpzf db-all.tar.gz db-all.sql
/usr/local/bin/b2 file upload --no-progress BUCKETNAME db-all.tar.gz db-all.tar.gz
rm -rf db-all.*