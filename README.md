# Minecraft Server Installation Script

## Overview
This repo contains two installation scripts:
1. `install-server.sh` -- for installing the base Minecraft server.
2. `install-backups.sh` -- for installing a backup system using borgmatic.

## Dependencies
- `openjdk-21-jre-headless`
- `jq`
- `borgmatic`

## Server Installation
Executing the `install-server.sh` script with no args will install the latest build of the Paper Minecraft server available.
The script will install a new user called "minecraft", with no home directory and no default shell (so it cannot be logged into).
The script will create a new directory at the root of the system: `/mc-server`. In this new directory it will create a `data` dir for storing the data of the server, as well as the `server.jar` executable, and a `driver.sh` script.
The script will also install a systemd unit file for managing the server. Once installation is complete, the server can be stopped and started using the standard systemctl commands `stop` and `start` respectively, e.g., `sudo systemctl start mc-server.service`.

If you wish to install a specific version other than the latest, simply provide the Minecraft version number as an argument to the script, e.g., `./install-server.sh 1.21.4`.

The `install-server.sh` script can be run without cloning the repo by downloading the latest file from GitHub directly and piping it to bash:
```bash
curl -fsSL https://raw.githubusercontent.com/krthornton/mc-server/refs/heads/master/install-server.sh | bash
```

## Backup Installation
Executing the `install-backups.sh` script will install a simple backup system for the Minecraft server using borgmatic. This system will be comprmised of two repos, one local and one remote, for storing mirrored backups of the Minecraft server.

Upon execution, the script will prompt the user whether they wish to utilize a remote borg repo in addition to a local repo for storing backups.
If the user answers yes, the script will prompt from both the SSH URI to the repo, e.g., `ssh://asdf.repo.borgbase.com/./repo`, and an encryption password for the remote repo.
The script will then generate a config file, store it in `/etc/borgmatic.d/mc-server.yaml`, and validate it.
Lastly, the script will initialize a local borg repo for backups (unencrypted).

Similarly to the server install script, the `install-backups.sh` script can be run without cloning the repo by downloading the latest file from GitHub directly and piping it to bash:
```bash
curl -fsSL https://raw.githubusercontent.com/krthornton/mc-server/refs/heads/master/install-backups.sh | bash
```

## Backup Restoration
Existing backups can be listed from the local repo by running the following:
```bash
sudo borgmatic list --repository /mc-server/backups/local-repo
```

You can restore from a given backup by running something like the following:
```bash
sudo borgmatic restore --repository /mc-server/backups/local-repo --archive data-2025-01-27T15:42:57
```
