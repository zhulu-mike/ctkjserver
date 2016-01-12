#!/bin/bash
. ./config.sh

pids=`ps aux | grep $ID-redis-server | awk -F " " '{if($11 != "grep")print $2;}'`

if [ "$pids" != "" ] ; then
	echo "mush stop all servers before run!"
	exit
fi

#如果非正常关闭启动recover
read status < status.txt

if [ "$status" = "2" ]; then
	./main_startup.sh	
	echo 1 > status.txt
else
	echo "server shutdown unnormal,should recover first?"
fi

echo "done"
