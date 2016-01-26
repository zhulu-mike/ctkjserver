#!/bin/bash
PATH=$PATH

export ID=3

cd share/skynet

#copy redis server
if [ ! -f "$ID-skynet" ]; then
	cp -f ./skynet ./"$ID-skynet"
fi

cd ..
cd ..

export SKYNET_PATH="./share/skynet/"