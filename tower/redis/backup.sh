#!/bin/sh 
. ./config.sh

#first save to rdb file
./bgsave.sh

DDIR=$PWD/backup/$CURDATE
mkdir -p ${DDIR}

for PORT in $(seq $PORT_FROM $PORT_END)
do
	#zip aof files
	cd ./data/
	tar -zcf $DDIR/${PORT}_${CURTIME}.tar.gz $PORT.rdb
	cd ..
done

#删除7天前的所有东西
find ./backup/ -mtime +7 | xargs rm -rf



