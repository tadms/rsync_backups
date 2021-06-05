#!/bin/bash

# Set globals
LINE=$(printf "%0.s-" {1..80})
LINE_BOLD=$(printf "%0.s#" {1..80})
LOG_FILE="/mnt/c/git/rsync_backups/rsync_backups.log"
DRYRUN_OPT="false"

# Directories to backup.  
# ["SOURCE/"]="DESTINATION"
declare -A DIRS=(
  ["/mnt/d/"]="/mnt/e"
  ["/mnt/x/"]="/mnt/y"
  ["/mnt/c/Users/Tyler/Reaper/"]="/mnt/d/Reaper"
)

function print_help {
local banner="
Usage
-----
  ./rsync_backups                    Run rsync_backups with defaults
  ./rsync_backups -l [file.log]      Set custom log file location
  ./rsync_backups -d                 Dry run mode
  ./rsync_backups -h                 Display this screen
"
echo "$banner"
}

function logger {
  local log_message=$1
  echo "$log_message" >> $LOG_FILE
}

function rotate_log {
  local max_size=5000
  local current_size="$(ls -s $LOG_FILE | cut -d" " -f1)"
  if [ $current_size -ge $max_size ]; then
    mv $LOG_FILE "${LOG_FILE}_$(date +%F)"
    touch $LOG_FILE
  fi
}

function opt_parse {
  while getopts ":hdl:" opt; do
    case $opt in
      h)
        print_help
        exit 0
        ;;
	  d)
        DRYRUN_OPT="true"
        ;;
      l)
        LOG_OPT="true"
        LOG_FILE=$OPTARG
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    esac
  done
}

function syncify {
  local src=$1
  local dest=$2
  
  logger
  logger $LINE
  logger "[$(date)] - STARTING BACKUP OF [$src]"
  logger $LINE
  
  if [ "$DRYRUN_OPT" == "true" ] ; then 
	echo "rsync -avh --delete --exclude={'System Volume Information','$RECYCLE.BIN','@NEW'} $src $dest"
  else
    rsync -avh --exclude={'System Volume Information','$RECYCLE.BIN','@NEW'} --delete $src $dest >> $LOG_FILE
  fi
}

function main {
  touch $LOG_FILE
  logger
  logger
  logger $LINE_BOLD
  logger "[$(date)] - STARTING DAILY BACKUPS "
  logger $LINE_BOLD
  
  if [ "$DRYRUN_OPT" == "true" ] ; then 
	echo "DRYRUN MODE"
  fi
  
  for dir in "${!DIRS[@]}" ; do
    local src_dir=$dir
    local dest_dir="${DIRS[$dir]}"
    syncify $src_dir $dest_dir
  done
  
  logger
  logger $LINE
  logger "Backups Completed!"
  logger $LINE
  
  rotate_log
}

opt_parse $@
main