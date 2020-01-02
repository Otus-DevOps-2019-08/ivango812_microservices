#!/bin/bash

if [ -z $1 ]; then

    echo "Pass branch_name as parametr:"
    echo "remove-site.sh <branch_name>"
    exit 1

else

    branch_name=$1

    config_file="/etc/nginx/sites-available/$branch_name"
    link_name="/etc/nginx/sites-enabled/$branch_name"

    rm -f $link_name
    rm $config_file 
    echo "Site $branch_name removed"
    service nginx reload

fi
