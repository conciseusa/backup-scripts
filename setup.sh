#!/bin/bash

# script to help setup backup-scripts
# run this script from the backup-scripts checkout (location of this file)
# or run some or all the commands one by one on the command line

# backup-scripts looks for a config dir in its parent dir for job/configuration info
echo "Create dir ../config if not there already"
mkdir -p ../config

# copy default job file to config dir so updates will not conflict with upstream changes
# backup file if already present
# review config/bujobs.sh and make any needed changes
RUN_TIME=`date +%F_%T`
[ -f ../config/bujobs.sh ] && mv ../config/bujobs.sh ../config/bujobs_$RUN_TIME.sh; echo "bujobs.sh present, backup bujobs.sh to bujobs_$RUN_TIME.sh";
echo "Copy default bujobs.sh to ../config/bujobs.sh"
cp bujobs.sh ../config/bujobs.sh
chmod 775 ../config/bujobs.sh

# echo crontab line to run nightly
PARENT_DIR=$(dirname "$(pwd)")
echo "Add line below to crontab (crontab -e) to run everyday at 1AM"
echo "0 1 * * * $PARENT_DIR/config/runbackup.sh"
