#!/bin/bash
set -e
source "./.libbuildmythli.sh"
BaseDir=$(GetBaseDir)

CFXBold=$(tput bold)
CFXGreen=${CFXBold}$(tput setaf 2)
CFXDefault=$(tput sgr0)


if [[ -z "$@" ]]; then
	echo "Usage: compile update install uninstall upgrade"
	exit 0
fi

declare -A GenArgs=()

function BuildMythli
{
	case "$1" in 
		'compile')
			echo -e "${CFXBold}Generating makefiles...${CFXDefault}"
			GenMakeFiles "$BaseDir" $(declare -p GenArgs)
			
			echo -e "${CFXBold}Compiling...${CFXDefault}"
			MakeBuild "$BaseDir"
			
			echo -e "${CFXGreen}Update succesful.${CFXDefault}"
		;;
		'update')
			echo -e "${CFXBold}Updating source...${CFXDefault}"
			Update "$BaseDir"
		;;
		'install')
			echo -e "${CFXBold}Installing build...${CFXDefault}"
			InstallBuild "$BaseDir"
			echo -e "${CFXGreen}Build installed.${CFXDefault}"
		;;
		'uninstall')
			
		;;
		'upgrade')
			BuildMythli "update"
			BuildMythli "compile"
			BuildMythli "install"
		;;
	esac
}

BuildMythli $1