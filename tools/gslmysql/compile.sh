#!/bin/sh
echo "Compiling gslmysql, please wait..."
gcc -o gslmysql $(mysql_config --cflags) gslmysql.c common.c $(mysql_config --libs) -leibclient
