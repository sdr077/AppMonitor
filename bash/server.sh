#!/bin/bash
date=$(date)
today="$( date +"%Y%m%d" )"
filename="webserver-$today.log"
serverdns="http://ec2-13-233-238-114.ap-south-1.compute.amazonaws.com"

status=$(curl -s -w '%{http_code}' -o /dev/null $serverdns)

if [ $status == "200" ]; then
	echo "Success : WebServer is running"
	echo "Checking the webpage content..."
	echo "====================================================================="
	curl -i $serverdns
	content=$(curl $serverdns)
	sleep 3
	echo "====================================================================="
	statusmessage="SUCCESS::Server is running"
else

	echo "Error : WebServer is not running!!"
	echo "Starting the WebServer..."
	sudo systemctl start httpd
	sleep 5
	status=$(curl -s -w '%{http_code}' -o /dev/null $serverdns)
	if [ $status == "200" ]; then
		echo "Success : WebServer is running"
		echo "Checking the webpage content..."
		echo "====================================================================="
		curl -i $serverdns
		sleep 3
		echo "====================================================================="
		echo "Server got rebooted"  | mail -s "SERVER ALERTS : `date`" dileepasenarathna2@gmail.com
		statusmessage="WARNING::Server is restarted"
		content=$(curl $serverdns)
		status="200"
	else 
		echo "Error : WebServer is not started. Please check with the support team"
		statusmessage="ERROR::Server ran into issue"
		echo "ERROR::Server ran into issues, httpd service can't be started. Please log into the server and check"  | mail -s "SERVER ALERTS : `date`" dileepasenarathna2@gmail.com
		status="404"
		content="not available"
	fi	 
				  
fi
#### Writing to log file###
if [ ! -e /home/ec2-user/logs/$filename ]; then
   echo "$date:::STATUS:$status:::$statusmessage:::{Message : $content}" > /home/ec2-user/logs/$filename
 else
   echo "$date:::STATUS:$status:::$statusmessage:::{Message : $content}" >> /home/ec2-user/logs/$filename
fi























