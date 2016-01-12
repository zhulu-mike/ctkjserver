#!/bin/bash
. ./config.sh

for PORT in $(seq $PORT_FROM $PORT_END)
do
	./"$ID-redis-server" ./conf/$PORT.conf
	sleep 5
done

echo "main startup done"