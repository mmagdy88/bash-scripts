#!/bin/bash

# cPanel account username
CPUSER="CPUSER"

# File containing emails (one per line: user@example.com)
EMAIL_LIST="emails.txt"

# Output file for new passwords (make sure to chmod 600 if you want to keep it on server)
OUTPUT_FILE="new_passwords.txt"

# Generate random secure password (16 chars)
generate_password() {
  tr -dc 'A-Za-z0-9!@#$%^&*()-_=+{}[]:,.?' </dev/urandom | head -c 16
}

# Empty output file at start
> "$OUTPUT_FILE"

# Loop through each email
while IFS= read -r EMAIL; do
  [ -z "$EMAIL" ] && continue   # skip empty lines

  PASSWORD=$(generate_password)

  echo "Changing password for $EMAIL"

  uapi --user="$CPUSER" Email passwd_pop \
    email="$EMAIL" \
    password="$PASSWORD" \
    --output=jsonpretty

  # Save result
  echo "$EMAIL : $PASSWORD" >> "$OUTPUT_FILE"

done < "$EMAIL_LIST"