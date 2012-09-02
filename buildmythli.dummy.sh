#!/bin/bash
set -e
source "./.libbuildmythli.sh"
BaseDir=$(GetBaseDir)

CFXBold=$(tput bold)
CFXGreen=${CFXBold}$(tput setaf 2)
CFXDefault=$(tput sgr0)


if [[ -z "$@" ]]; then
	echo "Usage: install uninstall update"
	exit 0
fi

declare -A GenArgs=()

case "$1" in
	install)
		echo -e "${CFXBold}Installing build...${CFXDefault}"
		InstallBuild "$BaseDir"
		echo -e "${CFXGreen}Build installed.${CFXDefault}"
	;;
	uninstall)
		
	;;
	update)
		echo -e "${CFXBold}Updating source...${CFXDefault}"
		Update "$BaseDir"
		
		echo -e "${CFXBold}Generating makefiles...${CFXDefault}"
		GenMakeFiles "$BaseDir" $(declare -p GenArgs)
		
		echo -e "${CFXBold}Compiling...${CFXDefault}"
		MakeBuild "$BaseDir"
		
		echo -e "${CFXGreen}Update succesful.${CFXDefault}"
	;;
esac