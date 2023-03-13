#!/bin/bash

# script to help setup backup-scripts
# run this script in the dir where the raspberry-pi-json-data-logger clone dir should created
# or run some or all the commands one by one on the command line

# rbackup-scripts looks for a config dir in its parent dir for configuration info
mkdir -p ../config

# copy default job file to config dir so updates will not conflict with upstream changes
# backup file if already present
# review config/bujobs.sh and make any needed changes
[ -f ../config/bujobs.sh ] && mv ../config/bujobs.sh ../config/bujobs_$(date +%T).sh
cp bujobs.sh ../config/bujobs.sh
