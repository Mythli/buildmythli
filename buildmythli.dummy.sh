#!/bin/bash
set -e
BaseDir=$(dirname $0)
source "$BaseDir/.libbuildmythli.sh"

CFXBold=$(tput bold)
CFXGreen=${CFXBold}$(tput setaf 2)
CFXDefault=$(tput sgr0)

if [[ -z "$@" ]]; then
	echo "Usage: install uninstall update"
	exit 0
fi

declare -A GenArgs=(
)

case "$1" in
	install)
		InstallBuild "$BaseDir"
	;;
	uninstall)
		
	;;
	update)
		echo -e "${CFXBold}Updating source...${CFXDefault}"
		Update "$BaseDir"
		echo -e "${CFXGreen}Source updated.${CFXDefault}"
		echo -e "${CFXBold}Generating makefiles...${CFXDefault}"
		GenMakeFiles "$BaseDir" $(declare -p GenArgs)
		echo -e "${CFXGreen}makefiles generated.${CFXDefault}"
		echo -e "${CFXBold}Compiling...${CFXDefault}"
		MakeBuild "$BaseDir"
		echo -e "${CFXGreen}Compiled.${CFXDefault}"
		echo -e "${CFXBold}Updating source...${CFXDefault}"
	;;
esac