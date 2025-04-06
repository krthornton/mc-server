#!/usr/bin/env bash

# check for dependencies
REQUIRED_JAVA="openjdk-21-jre-headless"
if ! dpkg -l $REQUIRED_JAVA 1>/dev/null 2>&1; then
	echo "Insufficient java version installed. Please install $REQUIRED_JAVA."
	exit 1
fi

# determine minecraft version
echo -n "Please enter the version of Minecraft for which you wish to install a server: "
read MC_VERSION
VERSION_REGEX="^[0-9]+\.[0-9]+(\.[0-9]+)?$"
if ! echo "$MC_VERSION" | grep -E $VERSION_REGEX 1>/dev/null 2>&1; then
	echo "Invalid Minecraft version entered: $MC_VERSION."
	exit 1
fi

echo "Installation complete."
