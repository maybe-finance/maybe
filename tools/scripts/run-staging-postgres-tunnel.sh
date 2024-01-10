#!/bin/bash

if test -f ~/.ssh/jumpbox_key_staging; then 
    echo "Key exists, starting session..."
else 
    echo -e "Prereqs: \n\n1. Create a file called ~/.ssh/jumpbox_key_staging\n2. Get key from 1Password, paste into file\n3. Run chmod 400 ~/.ssh/jumpbox_key_staging\n\n"
fi

echo "Enter Postgres string in host:port format"
read PG_HOST_PORT

ssh -i ~/.ssh/jumpbox_key_staging -L 5555:$PG_HOST_PORT ubuntu@ec2-54-185-10-3.us-west-2.compute.amazonaws.com