#!/bin/bash

CONFIG_FILE="buildmaster/config"
source "$CONFIG_FILE"

if [ $? -ne 0 ]
then
	echo "configuration file $CONFIG_FILE couldn't be sourced"
	exit 1
fi

if [ -z "$HAIKUPORTER" ]
then
	echo "HAIKUPORTER environment variable not set"
	exit 1
fi

if [ -z "$PACKAGE_REPO" ]
then
	echo "PACKAGE_REPO environment variable not set"
	exit 1
fi

if [ -z "$REPO_DIR" ]
then
	echo "REPO_DIR environment variable not set"
	exit 1
fi

if [ ! -d "$REPO_DIR" ]
then
	echo "repository directory $REPO_DIR does not exist"
	exit 1
fi

if [ -z "$PACKAGES_DIR" ]
then
	PACKAGES_DIR="$(pwd)/packages"
fi

if [ -z "$REPO_PACKAGES_DIR" ]
then
	REPO_PACKAGES_DIR="$REPO_DIR/packages"
fi


if [ ! -d "$REPO_PACKAGES_DIR" ]
then
	echo "creating repo packages dir"
	mkdir "$REPO_PACKAGES_DIR"
else
	echo "clearing all packages from repo packages dir"
	rm "$REPO_PACKAGES_DIR"/*.hpkg
fi

echo "finding newset package versions"
for PACKAGE in $("$HAIKUPORTER" --no-package-obsoletion --list-packages \
		--print-filenames 2> /dev/null)
do
	PACKAGE="$PACKAGES_DIR/$PACKAGE"
	if [ -f "$PACKAGE" -a ! -L "$PACKAGE" ]
	then
		echo "linking package $PACKAGE into repo packages dir"
		ln -s "$PACKAGE" "$REPO_PACKAGES_DIR"
	fi
done

echo "creating repository"
"$PACKAGE_REPO" create -v "$REPO_DIR/repo.info" "$REPO_PACKAGES_DIR"/*.hpkg

echo "hashing repository file"
sha256sum "$REPO_DIR/repo" > "$REPO_DIR/repo.sha256"

if [ $? -ne 0 ]
then
	echo "repo creation failed"
	exit 3
fi
