#!/bin/bash

. ./config.sh

./bgsave.sh

#close all server
for PORT in $(seq $PORT_FROM $PORT_END)
do
	echo "close $PORT"
	redis-cli -h 127.0.0.1 -p $PORT -a $REDISPASSWORD shutdown
	sleep 5
done

#写标识表示正常关闭
echo 2 > status.txt

./shutdown.sh
echo "done"



