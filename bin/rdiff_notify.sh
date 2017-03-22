#! /bin/bash

# rdiffweb Backup Notifier
#	by Andy Forceno <andy@aurorabox.tech>

# Usage: 
# Executing rdiff_notify without arguments will push latest session stats for all repos
# To obtain session stats for one repo, execute: rdiff_notify repo_name
# Where `repo_name` is the folder name of the repo

# It is recommended to execute this script after each cron backup job, like so:
# rdiff-backup -v5 --exclude-filelist /home/user/.rdiff-backup/host-home-excludes --print-statistics andy@host::/home /media/backups/host/home && sudo /home/user/scripts/bin/rdiff_notify host > /dev/null 2>&1
# Upon successful backup of host's home directory, run rdiff_notify to push latest session statistics for host

# INFO: If the user executing rdiff_notify does not own the repos (backup destination dirs)
# then rdiff_notify must be run as root!

if [ -e "$HOME"/.config/shuttle-utils/shuttle-utils.conf ]; then
	source "$HOME"/.config/shuttle-utils/shuttle-utils.conf
else
	echo "SHuttle-utils: Error: No config file found!"
	exit 1
fi

repo="$1"
dir_1="/media/backups"
dir_2="/media/big-media"
# Include the full path to each backup repository (each repo must include an rdiff-backup-data directory)
# Feel free to use $dir_n variables, to reduce line length of the array
REPO_DIRS=("$dir_1/Aurorabox/root" "$dir_1/Aurorabox/home" "$dir_1/Nyx/root" "$dir_2/google_drive" "$dir_2/Downloads" "$dir_2/Music")

# If user doesn't specify a repo, parse all the repos and send the latest sessions stats for each
if [[ -z "$repo" ]]; then
	for ((i = 0; i < ${#REPO_DIRS[@]}; i++)); do
		# Get latest session statistics file
		session=$(ls -lth "${REPO_DIRS[$i]}"/rdiff-backup-data/session_statistics* | awk '{ print $9 }' | head -n1)
		# Get the backup directory name (required because the for loop reads the index numbers of each element)
		backup=$(echo "${REPO_DIRS[$i]}" | awk -F/ -OFS='\' '{ print $(NF-1) }')
	# Uncomment to obtain session stats via standard output
		# echo "--- Backup dir: $backup ---"
		# sudo cat "$session"
		# echo ""
		echo "$HOSTNAME: Pushing rdiff-backup session stats for: $backup"
	# Uncomment to receive sessions stats via mail
	       # sudo cat "$session" | mail -s "Latest backup stats for $backup" root@aurorabox
		sudo cat "$session" | shuttle -p -n "$device" "Latest backup stats for $backup" 
	# INFO: If you have many repos, consider increasing the sleep time 
		sleep 1s
	done
# If user specifies a repo, send session statistics for that repo only
else
	# Find $repo specified on cli in ${REPO_DIRS}
	for i in "${REPO_DIRS[@]}"; do
		# Get backup name
		backup+=($(echo "$i" | grep -iF "$repo"))
		# Get repo that user specified on command line
   		CL_REPO+=($(echo "$i" | grep -i "$repo"))
	done

	for i in "${CL_REPO[@]}"; do
		session=$(ls -lth "$i"/rdiff-backup-data/session_statistics* | awk '{ print $9 }' | head -n1)
	# INFO: Uncomment to receive session stats via email
		# sudo cat "$session" | mail -s "Latest backup stats for $i" root@aurorabox	
		sudo cat "$session" | shuttle -p -n "$device" "Latest backup stats for $backup" 
	done
fi
