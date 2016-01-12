#!/bin/bash

. ./config.sh

#给所有主数据库做快照
for PORT in $(seq $PORT_FROM $PORT_END)
do
	echo "begin save $PORT"
	redis-cli -h 127.0.0.1 -p $PORT -a $REDISPASSWORD bgsave
	sleep 5
done

echo "save done"
echo $CURTIME >> ./log/bgsave.log



