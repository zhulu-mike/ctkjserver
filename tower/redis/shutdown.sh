#!/bin/bash
. ./config.sh

pids=`ps aux | grep $ID-redis-server | awk -F " " '{if($11 != "grep")print $2;}'`
for pid in $pids;do
	kill -9 $pid
done