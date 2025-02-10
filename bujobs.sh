
# This file is a combination of config info and code to run the backup jobs.
# A common use case is backing up a collection of shared directories on a NAS.
# And/or the target is a NAS that can handle a large amount of data.
# The jobs are broken up because the directories can get very large,
# or the frequency of the backups can vary. The location of the device,
# and the items are seperated so the device does not need to be repeated.
# The default below backs up the home dir to the tmp dir. Not super useful,
# but should run out of the box on most Linux systems as an example.
# Do not put / at the end of paths. Do not put the backups in the home dir
# if you are backing up the home dir, it will create an endless loop.

BU_SOURCE_BASE=$HOME
BU_TARGET_BASE="/tmp"
# BU_TARGET_BASE="/var/backup-scripts/local"

BU_SOURCE=""

# If the source is less then this percentage of the target, abort sync.
# Used to protect against the souce being deleted or disconnected and wiping out the backup.
# But has the downside of if a large amount of data was intentionally deleted, sync will not run.
# Regular review of logs is recommended if this feature is on. Set to 0 to turn off.
# For Ping/Pong or Round-robin backups, turning on for one of the cycles,
# provides a balence of backups continuing to run, while a backup is protected.
EXCESSIVE_SIZE_REDUCTION_ABORT=0

# Files to exclude that can take up a lot of space, and may not have much value
# *~ - Many Unix/Linux systems programs create backup files that end in ~
EXCLUDE_OPTIONS=( --exclude='*.git*' --exclude='*.cache*' --exclude='*Nobackup*' --exclude='*Trash/files*' --exclude='.DS_Store' --exclude='.AppleDouble' --exclude='*~' )

# Below is an example of a ping pong backup. Use case is to have the
# backup bounce between the two backup drives each day.
# This  provides some protection against a drive failure and one day of
# rollback data without losing half the space if using a mirrored RAID.
DAY_OF_YEAR=$(date +"%-j")
(( DAY_OF_CYCLE = $DAY_OF_YEAR % 2 ))
# simple if logic
#if (( $DAY_OF_YEAR % 2 )); then
#    # echo $DAY_OF_YEAR is odd
#    BU_TARGET="HomeDirPing"
#else
#    # echo $DAY_OF_YEAR is even
#    BU_TARGET="HomeDirPong"
#fi
case $DAY_OF_CYCLE in

  0)
    echo "DAY_OF_YEAR: $DAY_OF_YEAR DAY_OF_YEAR % 2 = 0"
    EXCESSIVE_SIZE_REDUCTION_ABORT=80
    BU_TARGET="HomeDirPing"
    ;;

  1)
    echo "DAY_OF_YEAR: $DAY_OF_YEAR DAY_OF_YEAR % 2 = 1"
    BU_TARGET="HomeDirPong"
    ;;

  #2)
  #  Round-robin - change % 2 to number of targets and add case options
  #  echo "DAY_OF_YEAR: $DAY_OF_YEAR DAY_OF_YEAR % 2 = 2"
  #  BU_TARGET="HomeDirRR2"
  #  ;;

  *)
    echo "Error: Unknown DAY_OF_YEAR remainder" | tee -a $LOG_DIR/backup.log;
    ;;
esac
run_sync # always run with current config vars / add size reduction protection?

# DAY_OF_WEEK used for weekly cycle backups.
DAY_OF_WEEK=$(date +%a)

# Below is an example of a weekly cycle sync backup.
# This  provides up to a week of aged data to look back at.
DAY_TO_RUN="Tue Thu Sat"  # Sun Mon Tue Wed Thu Fri Sat Disable
if [[ "$DAY_TO_RUN" == *"$DAY_OF_WEEK"* ]]; then
    BU_TARGET="HomeDirWeekly"
    run_sync # run with current config vars / add size reduction protection?
fi

# Below is an example of a monthly sync backup.
# This  provides up to a month? of aged data to look back at.
DAY_OF_MONTH=$(date +%d)
if [ "$DAY_OF_MONTH" == "1" ]; then
    BU_TARGET="HomeDirMonthly"
    run_sync # run with current config vars
fi

# Below is an example of a weekly cycle tar backup.
# This  provides aged data to look back at, and is easy to copy to other locations.
# Unlike sync backups, does not need a target dir created, will make a file for each backup.
DAY_TO_RUN="Thu Sun"  # Sun Mon Tue Wed Thu Fri Sat Disable $DAY_OF_WEEK to always run for testing
# careful with spaces in if (unexpected token error)
if [[ "$DAY_TO_RUN" == *"$DAY_OF_WEEK"* ]]; then
    BU_TARGET="HomeDirWeekly"
    run_tar # run with current config vars
fi
