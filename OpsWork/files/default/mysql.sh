#!/bin/bash

#Install mysql server
yum install mysql-server -y 

# Enable auto start
chkconfig mysqld on

#Start mysql server
service mysqld start




