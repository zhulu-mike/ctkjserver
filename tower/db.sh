#!/bin/bash
. ./config.sh

cd ${SKYNET_PATH}
nameTerminal "$GATE_NAME-database"

./$ID-skynet ../../etc/config.db


