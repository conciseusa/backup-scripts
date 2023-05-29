
# This file is a combination of config info and code to run the backup jobs.
# A common use case is backing up a collection of shared directories on a NAS.
# And/or the target is a NAS that can handle a large amount of data.
# The jobs are broken up because the directories can get very large,
# or the frequency of the backups can vary. The location of the device,
# and the items are seperated so the device does not need to be repeated.
# The default below backs up the home dir to the tmp dir. Not super useful,
# but should run out of the box on most Linux systems as an example.

BU_SOURCE_BASE=$HOME
BU_TARGET_BASE="/tmp"

BU_SOURCE=""

# Below is an example of a ping pong backup. Use case is to have the
# backup bounce between the two backup drives each day.
# This  provides some protection against a drive failure and one day of
# rollback data without losing half the space if using a mirrored RAID.
DAY_OF_YEAR=$(date +"%-j")
if (( $DAY_OF_YEAR % 2 )); then
    # echo $DAY_OF_YEAR is odd
    BU_TARGET="HomeDirPing"
else
    # echo $DAY_OF_YEAR is even
    BU_TARGET="HomeDirPong"
fi
run_sync # always run with current config vars

# Below is an example of a weekly sync backup.
# This  provides up to a week of aged data to look back at.
DAY_OF_WEEK=$(date +%a)
if [[ "$DAY_OF_WEEK" == "Mon" ]]; then  # Sun, Mon, Tue, Wed, Thu, Fri, Sat
    BU_TARGET="HomeDirWeekly"
    run_sync # run with current config vars
fi

# Below is an example of a monthly sync backup.
# This  provides up to a month of aged data to look back at.
DAY_OF_MONTH=$(date +%d)
if [[ "$DAY_OF_MONTH" == "15" ]]; then
    BU_TARGET="HomeDirMonthly"
    run_sync # run with current config vars
fi

# Below is an example of a weekly tar backup.
# This  provides aged data to look back at, and is easy to copy to other locations.
DAY_OF_WEEK=$(date +%a)
DAY_TO_RUN="Thu"  # Sun, Mon, Tue, Wed, Thu, Fri, Sat
if [[ "$DAY_OF_WEEK" == "$DAY_TO_RUN"]]; then  # add || 1  to always run for testing
    BU_TARGET="HomeDirWeekly"
    TAR_OPTIONS="--exclude=*.git* --exclude=*.cache* --exclude=*Nobackup* --exclude=*Trash/files*"
    run_tar # run with current config vars
fi
