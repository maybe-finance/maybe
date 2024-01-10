#!/bin/bash

if test -f ~/.ssh/jumpbox_key_production; then 
    echo "Key exists, starting session..."
else 
    echo -e "Prereqs: \n\n1. Create a file called ~/.ssh/jumpbox_key_production\n2. Get key from 1Password, paste into file\n3. Run chmod 400 ~/.ssh/jumpbox_key_production\n\n"
fi

echo "Enter Postgres string in host:port format"
read PG_HOST_PORT

ssh -i ~/.ssh/jumpbox_key_production -L 5555:$PG_HOST_PORT ubuntu@ec2-34-222-246-3.us-west-2.compute.amazonaws.com