#!/bin/bash
. ./config.sh

dbpath="$PWD/db.sh"
worldpath="$PWD/world.sh"
gatepath="$PWD/gate.sh"

#删除命令文件
if [ -f "close.cmd" ]; then
  rm close.cmd
fi

./shutdown.sh

#运行时变量
export GROUP=1
export GATE_NAME=sample
export GATE_PORT=6000

while :
do
  dbstillRunning=$(ps -ef |grep "$ID-skynet ../../etc/config.db" |grep -v "grep")
  worldstillRunning=$(ps -ef |grep "$ID-skynet ../../etc/config.world" |grep -v "grep")
  gatestillRunning=$(ps -ef |grep "$ID-skynet ../../etc/config.gate" |grep -v "grep")
  
  if [ "$dbstillRunning" = "" ] ; then
    echo "db service was not started" 
    echo "Starting db service ..." 

    nohup $dbpath > log/db.log 2>&1 &
  fi

  if [ "$worldstillRunning" = "" ] ; then
    echo "world service was not started" 
    echo "Starting world service ..." 
    
    nohup $worldpath > log/world.log 2>&1 &
  fi

  if [ "$gatestillRunning" = "" ] ; then
    echo "gate service was not started" 
    echo "Starting gate service ..." 
    
    nohup $gatepath > log/gate.log 2>&1 &
  fi

   sleep 30
done
