#!/bin/bash

if [ -d "/tmp/instance" ]; then
        #echo "Required Directory already exists. Files will be created in path /tmp/instance"
        rm -r /tmp/instance/* > /dev/null 2>&1
else
        cd /tmp
        mkdir instance
fi

# DO wordpress:
wordpress_content=$(locate */wp-content)
wp_activate_path=$(sudo find /  -name 'wp-activate.php' -group www-data)
wordpress_install=$(dirname "$wp_activate_path")
wordpress_wp_content="$wordpress_install/wp-content"
wordpress_plugins="$wordpress_install/wp-content/plugins"
#json_list=$(ls "$wordpress_plugins" | jq -R -s -c 'split("\n")[:-1]')
wp_list=$(ls "$wordpress_plugins" | tr "\n" , | sed 's/,/","/g')
wp_list_trimed=$(echo $wp_list | rev | cut -c4- | rev)
wp_json=$(echo '{"entity_name":"wordpress","content":"'$wordpress_wp_content'","plugins":["'$wp_list_trimed'"]}')

echo "{" # Start of JSON

dpkg-query --showformat='${Package}\n' --show  php nginx|
        while read -r line
        do
                INFO="/tmp/instance/$line.`date "+%d-%m-%Y-%H-%M-%S"`.out"
                ENTITY_NAME=$line
                INST_PATH=`which $line`
                PROCESS_IDS=`ps aux | grep "$line" | awk '{print $2}' | tr ' ' ,`

                if [[ $line = "php" ]]; then
                        VERSION=`php -v | head -n 1 | cut -d " " -f 2`
                        LATEST_BUILDS=`basename -a /usr/lib/php/20190902/*.so | tr "\n" , | sed 's/,/","/g'` 
                        LB=`echo $LATEST_BUILDS | rev | cut -c4- | rev`
                        #LATEST_BUILDS=`ls -a /usr/lib/php/20190902/*.so | tr ' ' ,` # Commented out by larry
                        #LATEST_BUILDS=`basename -a /usr/lib/php/20190902/*.so | tr "\n" , | sed 's/,/","/g'` # Added by larry to get the BASENAME of the files, not sure why we are looking at a static directory, but this should be dynamicly obtained
                        JSON='{
                          "info": "'$INFO'",
                                "entity_name": "'$ENTITY_NAME'",
                                "process_ids": "['$PROCESS_IDS']",
                                "extensions": ["'$LB'"]
                        }'
                  php_json=$(echo ''$JSON'')                  
                  echo $JSON >> $INFO
                  echo '"php":'$JSON','
                  #exit 0
                else
                        VERSION=`dpkg-query --showformat='${Version}\n' --show "$line"`
                        NGINX_PATH=$(nginx -V 2>&1 | grep -o '\-\-conf-path=\(.*conf\)' | cut -d '=' -f2) ;

                        #echo $VERSION

                        JSON='{
                          "info": "'$INFO'",
                                "entity_name": "'$ENTITY_NAME'",
                                "process_ids": "'$PROCESS_IDS'",
                                "config_path": "'$NGINX_PATH'"
                        }'

                        echo $JSON >> $INFO
                        #echo $JSON
                        echo '"nginx":'$JSON','
                        nginx_json=$(echo $JSON)
                        #export $NGINX_JSON
                        cp -f "$NGINX_PATH" /tmp/instance/
                        if [ -d "/etc/nginx/sites-enabled/nginx.conf" ]; then
                        	cp -f /etc/nginx/sites-enabled/*.conf /tmp/instance/
			fi
                fi
        done

echo '"wordpress":'$wp_json''
echo '}'
