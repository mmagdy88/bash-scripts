#!/bin/bash
# Killing mysql queries running for more than 100 seconds

# Defining the query's timeout
time_out="100"

# Cleaning up the last query list
>/root/ids.txt

# Retrieving the ID of all queries above "time_out" seconds
mysql -e "select id from information_schema.processlist where info is not null and time > $time_out;" | awk {' print $1 '} | grep -v id > /root/ids.txt

# Looping through IDs and killing them
for query in $(cat ids.txt)
do
    mysql -e "KILL $query;"
done