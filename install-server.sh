#!/usr/bin/env bash

# stop running server (if exists)
if systemctl is-active --quiet mc-server.service 1>/dev/null; then
	echo -e "The installed Minecraft server is still running. Please manually stop it before installing.\nAborting installation."
	exit 1
fi

# check for dependencies
REQUIRED_JAVA="openjdk-21-jre-headless"
if ! dpkg -l $REQUIRED_JAVA 1>/dev/null 2>&1; then
	echo "Dependency '$REQUIRED_JAVA' is not installed. Please install it manually."
	exit 1
fi
if ! dpkg -l jq 1>/dev/null 2>&1; then
	echo "Dependency 'jq' not installed. Please install it manually."
	exit 1
fi

# determine minecraft version
VERSION_REGEX="^[0-9]+\.[0-9]+(\.[0-9]+)?$"
if ! [[ -z "$1" ]]; then
	# user provided version number as arg - validate and use it
	if ! echo "$1" | grep -E $VERSION_REGEX 1>/dev/null 2>&1; then
		echo "Invalid Minecraft version entered: $1."
		exit 1
	else
		echo "Using version provided via arg: $1"
		MC_VERSION=$1
	fi
else
	# determine latest version available
	echo "Fetching latest version number from Paper-MC API..."
	MC_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]')
	echo "Using latest version available from Paper-MC API: $MC_VERSION"
fi

# determine latest build number for requested minecraft version
LATEST_BUILD=$(curl -s https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}/builds | jq '.builds | map(select(.channel == "default") | .build) | .[-1]')

if [ "$LATEST_BUILD" != "null" ]; then
    echo "Latest stable build for $MC_VERSION is $LATEST_BUILD"
else
    echo "No stable build for version $MC_VERSION found :("
    exit 1
fi

# retrieve the latest server jar for build number
JAR_NAME=paper-${MC_VERSION}-${LATEST_BUILD}.jar
PAPERMC_URL="https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}/builds/${LATEST_BUILD}/downloads/${JAR_NAME}"
if ! [ -f "/tmp/$JAR_NAME" ]; then
	echo "Downloading /tmp/$JAR_NAME..."
	curl -o "/tmp/$JAR_NAME" $PAPERMC_URL
	echo "Download completed."
else
	echo "Using cached /tmp/$JAR_NAME"
fi

# create minecraft user
if ! id -u minecraft 1>/dev/null 2>&1; then
	echo "Creating minecraft user..."
	sudo useradd -M --shell /bin/false minecraft
else
	echo "User minecraft already exists."
fi

# setup directory structure
echo "Setting up server directory structure..."
sudo mkdir -p /mc-server/data
sudo chmod o+w /mc-server
sudo chown -R minecraft:minecraft /mc-server/data
sudo chmod -R 770 /mc-server/data

# install systemd unit file
echo "Installing sytemd unit file to /etc/systemd/system/mc-server.service..."
sudo bash -c "cat > /etc/systemd/system/mc-server.service" << EOF
[Unit]
Description=Minecraft Server
Wants=network-online.target
After=network-online.target

[Service]
User=minecraft
WorkingDirectory=/mc-server/data
ExecStart=/usr/bin/java -Xmx6G -jar /mc-server/server.jar nogui --world-container /mc-server/data/worlds
TimeoutStopSec=60
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF
echo "Reloading systemd..."
sudo systemctl daemon-reload

# install server JAR file
echo "Installing server jar file..."
sudo cp "/tmp/$JAR_NAME" /mc-server/server.jar
sudo chown root:root /mc-server/server.jar
sudo chmod 644 /mc-server/server.jar

echo "Minecraft server installation complete."
echo "Run 'systemctl start mc-server' to start the server."
