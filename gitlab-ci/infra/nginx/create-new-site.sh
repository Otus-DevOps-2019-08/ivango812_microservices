#!/bin/bash

if [ -z $1 ]; then

    echo "Pass branch_name as parametr:"
    echo "create-new-site.sh <branch_name>"
    exit 1
    
else

    branch_name=$1

    domain="$branch_name.dev.newbusinesslogic.com"
    container_name="branch-$branch_name"
    container_port=9292
    # config_file="./$branch_name"
    config_file="/etc/nginx/sites-available/$branch_name"
    link_name="/etc/nginx/sites-enabled/$branch_name"

    tee $config_file > /dev/null <<EOF 
server {
    listen 80;
    server_name $domain;
    location / {
        proxy_pass http://$container_name:$container_port;
    }
}

EOF

    ln -s $config_file $link_name

    nginx -t
    if [ $? -eq 0 ]; then
        service nginx reload
    else
        rm -f $link_name
        rm $config_file 
        echo "Could not found container $1" >&2
    fi

fi
