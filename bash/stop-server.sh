#!/bin/bash
date=$(date)
today="$( date +"%Y%m%d" )"
filename="webserver-$today.log"
serverdns="http://ec2-13-233-238-114.ap-south-1.compute.amazonaws.com"

sudo systemctl stop httpd

status="404"
statusmessage="SUCCESS::Server Stopped..."
content="NULL"
#### Writing to log file###
if [ ! -e /home/ec2-user/logs/$filename ]; then
	echo "$date:::STATUS:$status:::$statusmessage:::{Message : $content}" > /home/ec2-user/logs/$filename
else
        echo "$date:::STATUS:$status:::$statusmessage:::{Message : $content}" >> /home/ec2-user/logs/$filename
fi

