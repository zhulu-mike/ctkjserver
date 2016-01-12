#!/bin/bash

PATH=$PATH

#redis组编号
export ID=2

#copy redis server
if [ ! -f "$ID-redis-server" ]; then
	cp -f ./bin/redis-server ./"$ID-redis-server"
fi

export REDISPASSWORD=ctkj0571

export CURDATE=`date +%Y%m%d`
export CURHOUR=`date +%Y%m%d_%H`
export CURTIME=`date +%H%M%S`

export PORT_FROM=9106
export PORT_END=9106



