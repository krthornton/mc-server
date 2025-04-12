#!/usr/bin/env bash

# check for dependencies
if ! dpkg -l borgmatic 1>/dev/null 2>&1; then
	echo "Dependency 'borgmatic' is not installed. Please install it manually."
	exit 1
fi

# create directory structure
sudo mkdir -p /mc-server/backups/local-repo
sudo chown -R root:root /mc-server/backups
sudo chmod -R 770 /mc-server/backups
sudo mkdir -p /etc/borgmatic.d

# determine if remote repo will be used for backup
read -p "Would you like to also backup to a remote borg repo?" USE_REMOTE
if [[ $USE_REMOTE == [yY] ]]; then
	echo "Please provide the SSH URI for the desired remote borg repo below. If you do not wish to backup to a remote repo, leave the input empty."
	echo -n "Remote Borg Repo: "
	read REMOTE_REPO
	if ! [[ -z "$REMOTE_REPO" ]] && ! [[ "$REMOTE_REPO" =~ ^ssh:// ]]; then
		echo "Invalid remote repo URL provided. Aborting."
		exit 1
	fi

	echo "Please provide the encryption password for the remote repo in the next prompt."
	systemd-ask-password -n | sudo systemd-creds encrypt - /etc/credstore.encrypted/borgmatic.pw
	echo "Password stored securely using systemd-creds."
fi

# install borgmatic configuration
REMOTE_CONFIG=""
if ! [[ -z "$REMOTE_REPO" ]]; then
	REMOTE_CONFIG=$(cat << EOF
  - path: "$REMOTE_REPO"
    label: remote

encryption_passcommand: systemd-creds decrypt /etc/credstore.encrypted/borgmatic.pw -

EOF
	)
fi
echo "Installing borgmatic config file /etc/borgmatic.d/mc-server.yaml ..."
sudo bash -c "cat > /etc/borgmatic.d/mc-server.yaml" << EOF
source_directories:
  - /mc-server/data

repositories:
  - path: /mc-server/backups/local-repo
    label: local
$REMOTE_CONFIG

archive_name_format: data-{now}

before_everything:
  - systemctl stop mc-server.service
after_everything:
  - systemctl start mc-server.service

keep_daily: 7
keep_weekly: 4
keep_monthly: 12
keep_yearly: 1
EOF
sudo chmod 660 /etc/borgmatic.d/mc-server.yaml

# validate borgmatic config
echo "Validating borgmatic config..."
if ! sudo borgmatic config validate 1>/dev/null; then
	echo "Borgmatic config validation failed."
	exit 1
fi

# create local borg repo
echo "Initializing local borg repo..."
sudo borgmatic init --repository /mc-server/backups/local-repo --encryption none

echo "Backup configuration complete."
