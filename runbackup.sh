#!/bin/bash

START_TIME=`date +%Y-%m-%d-%H-%M-%S`  # may be used in filenames, careful with the characters
SCRIPT_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# BASH_SOURCE set by Bash
# add full cmd paths (/usr/bin/ most Linux) if no path set:
# SCRIPT_DIR=$(/usr/bin/dirname $(/usr/bin/readlink -f "$BASH_SOURCE"))
# more info: https://stackoverflow.com/questions/59895/how-can-i-get-the-directory-where-a-bash-script-is-located-from-within-the-scrip

LOG_DIR="$SCRIPT_DIR/logs"
if [ -d $LOG_DIR ]; then
    echo "$START_TIME - Set logs dir: $LOG_DIR" # echos not sent to log file useful for troubleshooting cron jobs
else 
    mkdir -p $LOG_DIR
    echo "$START_TIME - Set logs dir: $LOG_DIR"
    echo "$START_TIME - Created logs dir: $LOG_DIR" >> $LOG_DIR/backup.log;
fi

run_sync() {
	echo "$START_TIME - Start a sync backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET"
	echo "$START_TIME - Start a sync backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" >> $LOG_DIR/backup.log;
	rsync --verbose  --progress --stats --recursive --times --links --delete --exclude ".DS_Store" --exclude "*~" --exclude ".AppleDouble" "$BU_SOURCE_BASE/$BU_SOURCE" "$BU_TARGET_BASE/$BU_TARGET"
    # --exclude "Podcasts" --exclude "Automatically Add to iTunes" --exclude "Downloads" --dry-run --perms
    END_TIME=`date +%Y-%m-%d-%H-%M-%S`
    echo "$END_TIME - End a sync backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" >> $LOG_DIR/backup.log;
}

run_tar() {
	START_TIME=`date +%Y-%m-%d-%H-%M-%S-%a`  # tar time has day of week at end to help with delete logic
	echo "$START_TIME - Start a tar backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET"
	echo "$START_TIME - Start a tar backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" >> $LOG_DIR/backup.log;
    tar $TAR_OPTIONS -vczf "$BU_TARGET_BASE/$BU_TARGET-$START_TIME.tgz" "$BU_SOURCE_BASE/$BU_SOURCE"
    # find "$BU_TARGET_BASE/" -name "$BU_TARGET-*-$DAY_TO_RUN.tgz";
    # command to delete old backups
    find "$BU_TARGET_BASE/" -name "$BU_TARGET-*-$DAY_TO_RUN.tgz" -mtime +31 -exec rm -f {} \;
    END_TIME=`date +%Y-%m-%d-%H-%M-%S-%a`
    echo "$END_TIME - End a tar backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" >> $LOG_DIR/backup.log;
}

if [ -f $SCRIPT_DIR/../config/bujobs.sh ]; then
    # Best to use config data from outside the check out to avoid git update conflicts
    echo "Run jobs from $SCRIPT_DIR/../config/bujobs.sh"
    source $SCRIPT_DIR/../config/bujobs.sh
    # Also run default jobs for testing / development
    # echo "Run local/default bujobs.sh Dev"
    # source $SCRIPT_DIR/bujobs.sh
else 
    echo "Run local/default bujobs.sh"
    source $SCRIPT_DIR/bujobs.sh
fi
