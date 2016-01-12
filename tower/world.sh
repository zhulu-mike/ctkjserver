#!/bin/bash
. ./config.sh

cd ${SKYNET_PATH}
nameTerminal "$GATE_NAME-world"
./$ID-skynet ../../etc/config.world



