#!/bin/bash

START_TIME=`date +%Y-%m-%d-%H-%M-%S-%a`  # may be used in filenames, careful with the characters
SCRIPT_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# BASH_SOURCE set by Bash
# add full cmd paths (/usr/bin/ most Linux) if no path set:
# SCRIPT_DIR=$(/usr/bin/dirname $(/usr/bin/readlink -f "$BASH_SOURCE"))
# more info: https://stackoverflow.com/questions/59895/how-can-i-get-the-directory-where-a-bash-script-is-located-from-within-the-scrip
# Note: [[ suppresses important error messages and is not portable to different shells. Only use if needed.
# https://stackoverflow.com/questions/13408493/an-and-operator-for-an-if-statement-in-bash

LOG_DIR="$SCRIPT_DIR/logs"
if [ -d $LOG_DIR ]; then
    echo "$START_TIME - Set logs dir: $LOG_DIR" # echos not sent to log file useful for troubleshooting cron jobs
else 
    mkdir -p $LOG_DIR
    echo "$START_TIME - Created logs dir: $LOG_DIR" | tee -a $LOG_DIR/backup.log;
fi

# Rerun protection, if the last run has not finished, do not start another run of backups
# If the script does not finish due to error or ctrl-C abort, runbackup-running.txt needs to be deleted
if [ -f $LOG_DIR/runbackup-running.txt ]; then
    echo "$START_TIME - $LOG_DIR/runbackup-running.txt found, exiting. Delete runbackup-running.txt to clear lock." | tee -a $LOG_DIR/backup.log;
    exit 1
else
    echo -e "\n$START_TIME - runbackup-running.txt not found, creating semaphore runbackup-running.txt" | tee -a $LOG_DIR/backup.log;
    touch $LOG_DIR/runbackup-running.txt;
fi

run_sync() {
	echo "$START_TIME - Start sync backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" | tee -a $LOG_DIR/backup.log;
	SOURCE_SIZE=$(du -s -l "${EXCLUDE_OPTIONS[@]}" "$BU_SOURCE_BASE/$BU_SOURCE" | cut -f1)
	if [ -z "$SOURCE_SIZE" ]; then
	    SOURCE_SIZE=0
	fi
	TARGET_SIZE=$(du -s -l "${EXCLUDE_OPTIONS[@]}" "$BU_TARGET_BASE/$BU_TARGET" | cut -f1)
	if [ -z "$TARGET_SIZE" ]; then
	    TARGET_SIZE=0
	fi
	# TARGET_SIZE_ALLOWED_REDUCTION is the min size the source must be if EXCESSIVE_SIZE_REDUCTION_ABORT > 0
	# Used to protect the target in the case much or all of the source is lost.
	# EXCESSIVE_SIZE_REDUCTION_ABORT=80 requires source size to be at least 80% of target.
	TARGET_SIZE_ALLOWED_REDUCTION=`expr $TARGET_SIZE \* $EXCESSIVE_SIZE_REDUCTION_ABORT / 100`
	CURRENT_TIME=`date +%Y-%m-%d-%H-%M-%S-%a`
	echo "$CURRENT_TIME - SOURCE_SIZE: $SOURCE_SIZE / TARGET_SIZE: $TARGET_SIZE / TARGET_SIZE_ALLOWED_REDUCTION: $TARGET_SIZE_ALLOWED_REDUCTION" | tee -a $LOG_DIR/backup.log;
	if [ $EXCESSIVE_SIZE_REDUCTION_ABORT -eq 0 ] || [ $SOURCE_SIZE -gt $TARGET_SIZE_ALLOWED_REDUCTION ]; then
	    echo "$CURRENT_TIME - Run sync / EXCLUDE_OPTIONS: ${EXCLUDE_OPTIONS[@]}" | tee -a $LOG_DIR/backup.log;
	    rsync "${EXCLUDE_OPTIONS[@]}" --delete-excluded --hard-links --sparse -a --verbose  --progress --stats --times --links --delete --debug=FILTER "$BU_SOURCE_BASE/$BU_SOURCE" "$BU_TARGET_BASE/$BU_TARGET"
        # --dry-run --perms
	    # Using options from below got the difference between source and target to under 1%
        # https://unix.stackexchange.com/questions/679882/different-directory-size-after-rsync-and-using-du
        # df /tmp --output=avail  source,fstype,size,used,avail,pcent
        SOURCE_SIZE=$(du -s -l "${EXCLUDE_OPTIONS[@]}" "$BU_SOURCE_BASE/$BU_SOURCE" | cut -f1)
	    TARGET_SIZE=$(du -s -l "${EXCLUDE_OPTIONS[@]}" "$BU_TARGET_BASE/$BU_TARGET" | cut -f1)
	    CURRENT_TIME=`date +%Y-%m-%d-%H-%M-%S-%a`
	    echo "$CURRENT_TIME - SOURCE_SIZE: $SOURCE_SIZE / TARGET_SIZE: $TARGET_SIZE" | tee -a $LOG_DIR/backup.log;
	else
	    echo "$CURRENT_TIME - Abort due to excessive size reduction sync backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" | tee -a $LOG_DIR/backup.log;
	fi
    CURRENT_TIME=`date +%Y-%m-%d-%H-%M-%S-%a`
    echo "$CURRENT_TIME - End a sync backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" | tee -a $LOG_DIR/backup.log;
}

run_tar() {
	START_TIME=`date +%Y-%m-%d-%H-%M-%S-%a`  # day of week at end to help with delete logic
	echo "$START_TIME - Start tar backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" | tee -a $LOG_DIR/backup.log;
	# Do not delete the last tar backup file. Do delete first to open up space for new file.
	TAR_FILE_COUNT=$(find "$BU_TARGET_BASE/" -name "$BU_TARGET-*-$DAY_TO_RUN.tgz"  | wc -l)
	if [ $TAR_FILE_COUNT -gt 1 ]; then
	    echo "$START_TIME - Delete old files, pre delete tar file count: $TAR_FILE_COUNT Keep days: $TAR_KEEP_DAYS" | tee -a $LOG_DIR/backup.log;
	    echo "Files to delete:" | tee -a $LOG_DIR/backup.log;
	    find "$BU_TARGET_BASE/" -name "$BU_TARGET-*-$DAY_TO_RUN.tgz" -mtime "+$TAR_KEEP_DAYS" -print | tee -a $LOG_DIR/backup.log;
	    find "$BU_TARGET_BASE/" -name "$BU_TARGET-*-$DAY_TO_RUN.tgz" -mtime "+$TAR_KEEP_DAYS" -exec rm -f {} \;
	else
	    echo "$START_TIME - Abort old file delete due to tar file count of: $TAR_FILE_COUNT" | tee -a $LOG_DIR/backup.log;
	fi
    tar "${EXCLUDE_OPTIONS[@]}" -vczf "$BU_TARGET_BASE/$BU_TARGET-$START_TIME.tgz" "$BU_SOURCE_BASE/$BU_SOURCE"
    # find "$BU_TARGET_BASE/" -name "$BU_TARGET-*-$DAY_TO_RUN.tgz";
    CURRENT_TIME=`date +%Y-%m-%d-%H-%M-%S-%a`
    echo "$CURRENT_TIME - End a tar backup of $BU_SOURCE_BASE/$BU_SOURCE to $BU_TARGET_BASE/$BU_TARGET" | tee -a $LOG_DIR/backup.log;
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

CURRENT_TIME=`date +%Y-%m-%d-%H-%M-%S-%a`
echo "$CURRENT_TIME - Remove semaphore: $LOG_DIR/runbackup-running.txt" | tee -a $LOG_DIR/backup.log;
rm -f $LOG_DIR/runbackup-running.txt;
