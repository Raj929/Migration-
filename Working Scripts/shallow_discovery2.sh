#!/bin/bash
# Author: Raj
# Revised by: Larry 
# "Shallow Discovery Bash script for migrating existing servers to Azure VMs
# Note: 6/29/2020 Larry to Raj: "Raj, I formmated this file to be readable.  I also added a condition to check if the nginx conf file
#       exists.  If it does, it gets copied, if it doesn't it does that dpkg thing, that I'm not sure what it's for...
#       Also, I took out the exit 0, not sure that's needed.
#       Also, please note that this is mostly hard coded.  So if there is stuff in other places, it won't get picked up.
#       
# Updates: 6/29/2020 Larry: Combined all the output into ONE single file at the end.

if [ -d "/tmp/instance" ]; then
	echo "Required Directory already exists. Files will be created in path /tmp/instance"
	rm -r /tmp/instance/* > /dev/null 2>&1
   else
	cd /tmp
	mkdir instance
fi

dpkg-query --showformat='${Package}\n' --show nginx php |
while read -r line
do
	LOG="/tmp/instance/$line.`date "+%d-%m-%Y-%H-%M-%S"`.out"
	echo $LOG
	echo -e "Information of $line" >> $LOG
	if [[ $line = "php" ]]; then
		echo -e "\t" >> $LOG
		echo "$line Version is :" >> $LOG
		php -v | awk 'NR<=1{ print $1 " " $2 }' >> $LOG
		echo -e "\t" >> $LOG
		echo "$line Installation Path" >> $LOG
		which "$line" >> $LOG
		echo -e "\t" >> $LOG
		echo "Process ID $line running with:" >> $LOG
		ps aux | grep "$line" | awk '{print $2}' >> $LOG
		echo -e "\t" >> $LOG
		#echo "PHP extension Info: latest build as of 20190902" >> $LOG
		#cd /usr/lib/php/20190902/
		#ls *.so >> $LOG
	else
		echo -e "\t" >> $LOG
		echo "$line Version is:" >> $LOG
		dpkg-query --showformat='${Version}\n' --show "$line" >> $LOG
		echo -e "\t" >> $LOG
		echo "$line Installation Path" >> $LOG
		which "$line" >> $LOG
		echo -e "\t" >> $LOG
		echo "Process ID $line running with:" >> $LOG
		ps aux | grep "$line" | awk '{print $2}' >> $LOG
		echo -e "\t" >> $LOG
	fi

	echo -e "\t" >> $LOG
	echo "Wordpress version is:" >> $LOG
        grep wp_version /var/www/html/wordpress/wp-includes/version.php | awk -F "'" 'NF > 1 {print $2}' >> $LOG
	echo -e "\t" >> $LOG

        # Nginx STUFF
	if [[ $line = "nginx" ]]; then
		NGINX_PATH=$(nginx -V 2>&1 | grep -o '\-\-conf-path=\(.*conf\)' | cut -d '=' -f2) ;
		echo "nginx Configuration Path:" >> $LOG
		echo "$NGINX_PATH" >> $LOG
		#if [ -f $NGINX_PATH ]; then 
		#   cp -f "$NGINX_PATH" /tmp/instance/
		#fi 
		#cp -f /etc/nginx/sites-enabled/*conf /tmp/instance/ # Larry commented out, changing to *.conf
		#if [ -f "/etc/nginx/sites-enabled/nginx.conf" ]; then
		#	cp -f /etc/nginx/sites-enabled/*.conf /tmp/instance  
                #        echo "All the CONF files have been copied from /etc/nginx/sites-enabled"
   		#else
         	#	echo "Warning: /etc/nginx/sites-enabled/nginx.conf is missing,nothing copied"
		#fi
	else
		 echo "nginx conf not found, so doing something else.."
		 #dpkg -S "$line" | grep '/etc' >> $LOG # Larry: What are we doing here?
        fi
 done

cat /tmp/instance/* > /tmp/instance/shallow_discovery.txt

