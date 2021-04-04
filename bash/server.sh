#!/bin/bash

status=$(systemctl is-active httpd)

if [ $status == "active" ]; then

	    echo "Success : WebServer is running"
	    echo "Checking the webpage content..."
	    echo "====================================================================="
	    curl -i ec2-13-233-238-114.ap-south-1.compute.amazonaws.com
	    sleep 5
	    echo "====================================================================="
	        
   else

		        echo "Error : WebServer is not running!!"
			echo "Starting the WebServer..."
			sudo systemctl start httpd
			sleep 5
			status=$(systemctl is-active httpd)
			if [ $status == "active" ]; then
			 echo "Success : WebServer is running"
			 echo "Checking the webpage content..."
			 echo "====================================================================="
		         curl -i ec2-13-233-238-114.ap-south-1.compute.amazonaws.com
			 sleep 5
		         echo "====================================================================="
			 echo "Server got rebooted"  | mail -s "SERVER ALERTS : `date`" dileepasenarathna2@gmail.com
		       else 
			 echo "Error : WebServer is not started. Please check with the support team"
		       fi	 
			  
fi
