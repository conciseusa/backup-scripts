#!/bin/bash

START_TIME=`date +%Y-%m-%d:%H:%M:%S`
SCRIPT_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# BASH_SOURCE set by Bash
# add full cmd paths (/usr/bin/ most Linux) if no path set:
# SCRIPT_DIR=$(/usr/bin/dirname $(/usr/bin/readlink -f "$BASH_SOURCE"))
# more info: https://stackoverflow.com/questions/59895/how-can-i-get-the-directory-where-a-bash-script-is-located-from-within-the-scrip

if [ -d $SCRIPT_DIR/logs ]; then
    LOG_DIR="$SCRIPT_DIR/logs"
    echo "$START_TIME - Set logs dir: $SCRIPT_DIR/logs" # echos not sent to log file useful for troubleshooting cron jobs
else 
    mkdir -p $SCRIPT_DIR/logs
    LOG_DIR="logs"
    echo "$START_TIME - Set logs dir: $SCRIPT_DIR/logs"
    echo "$START_TIME - Created logs dir: $SCRIPT_DIR/logs" >> $LOG_DIR/backup.log;
fi

run_sync() {
	echo "$START_TIME - Start a sync backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET"
	echo "$START_TIME - Start a sync backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" >> $LOG_DIR/backup.log;
	rsync --verbose  --progress --stats --recursive --times --links --delete --exclude ".DS_Store" --exclude "*~" --exclude ".AppleDouble" "$BU_SOURCE_BASE/$BU_SOURCE" "$BU_TARGET_BASE/$BU_TARGET"
    # --exclude "Podcasts" --exclude "Automatically Add to iTunes" --exclude "Downloads" --dry-run --perms
    END_TIME=`date +%Y-%m-%d:%H:%M:%S`
    echo "$END_TIME - End a sync backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" >> $LOG_DIR/backup.log;
}

if [ -f $SCRIPT_DIR/../config/bujobs.sh ]; then
    # Best to use config data from outside the check out to avoid git update conflicts
    echo "Run jobs from $SCRIPT_DIR/../config/bujobs.sh"
    source $SCRIPT_DIR/../config/bujobs.sh
else 
    echo "Run local/default bujobs.sh"
    source $SCRIPT_DIR/bujobs.sh
fi
