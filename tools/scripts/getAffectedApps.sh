#!/bin/bash

NX_COMMAND=$(./node_modules/.bin/nx affected:apps --plain)

echo -e "Apps that will deploy: $NX_COMMAND \n"

APPS=(client server workers)

for APP in "${APPS[@]}"
do 
    APP_AFFECTED=$(echo $NX_COMMAND | grep -wq $APP && echo 'true' || echo 'false' )
    echo "::set-output name=${APP}_affected::$APP_AFFECTED"
done