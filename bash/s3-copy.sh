#!/bin/bash
content_path="/var/www/html/index.html"
today="$( date +"%Y%m%d" )"
log_path="/home/ec2-user/logs/webserver-$today.log"

##Start th zipping the files
ls $log_path
zip  -j "/home/ec2-user/logs/$today-log+content-backup".zip $log_path $content_path

##Copy to s3 bucket
aws s3 cp "/home/ec2-user/logs/$today-log+content-backup.zip" s3://webserver-logs-monitor/webserver-logs/

##Checking the file is there in the s3 and delete the compressed file
sleep 20
exists=$(aws s3 ls s3://webserver-logs-monitor/webserver-logs/$today-log+content-backup.zip)
if [ -z "$exists" ]; then
	echo "Log archive did not copy to S3 please check. Email sent!"	 
       	echo "Log archive did not copy to S3 please check"  | mail -s "AWS S3 log alert : `date`" dileepasenarathna2@gmail.com
  else
	  echo "Removing old log archive" 
	  rm -rf /home/ec2-user/logs/$today-log+content-backup.zip
fi
