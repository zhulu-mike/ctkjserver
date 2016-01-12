#!/bin/bash
. ./config.sh

cd ${SKYNET_PATH}

nameTerminal "$GATE_NAME-gate1"
./$ID-skynet ../../etc/config.gate

