#!/bin/bash
set -e
BaseDir=$(dirname $0)
source "$BaseDir/libbuildmythli.sh"

BUILDMYTHLI_INIT=0
BUILDMYTHLI_HELP=1
BUILDMYTHLI_VERSION=2
BUILDMYTHLI_TEST=3

function PrintHelp
{
	echo "Usage: buildmythli [OPTION]... [URL]... [DIRECTORY]..."
	echo ""
	echo "	-h --help 		display this help and exit"
	echo "	-v --version 		output version information and exit"
	echo "	-i --init 		init a repository and generate the buildmythli script"
	echo "	   --init-type 		forces buildmythli to use this vcs rather than determining it"
	echo "	-u --url 		set the url for repository init"
	echo "	-d --dir --directory 		set the director into which the repository is checked out"
	echo ""
	echo "Report buildmythli bugs to buildmythli@projects.mythli.net"
	exit 0
}

function PrintVersion
{
	echo "buildmythli version 0.1"
	exit 0
}

function BuildMythliScript
{
}

function InitRepository
{
	local url=$1
	local dir=$2
	local type=$3
	
	echo 'Creating folder Structure...'
	CreateFolderStructure "$dir"
	echo 'Downloading source...'
	Checkout "$url" "$dir" $type
	echo 'Writing buildmythli script to file...'
	BuildMythliScript "$url" "$dir" $type
}

function ExecuteMode
{
	case $Mode in
		BUILDMYTHLI_HELP)
			PrintHelp
		;;
		BUILDMYTHLI_VERSION)
			PrintVersion
		;;
		BUILDMYTHLI_INIT)
			InitRepository "$Url" "$Dir"
		;;
		BUILDMYTHLI_TEST)
			rm -Rf "$BaseDir/test"
			mkdir "$BaseDir/test"
			
			echo 'Git test...'
			$BaseDir/buildmythli.sh --init --url=https://github.com/Mythli/buildmythli.git --dir=/home/tobias/Develop/projects/buildmythli/test/git
		;;
	esac
}

# Execute getopt
GetOptEscapeHelper=`getopt -o "hviu:d:" -l "help,version,init,init-type:,url:,dir:,test" \
      -n "buildmythli" -- "$@"`
eval set -- "$GetOptEscapeHelper"

Dir=""
Url=""
Mode=BUILDMYTHLI_INIT

while true;
do
	argName=$1
	argValue=$2
	
	case "$argName" in
		-h|--help)
			Mode=BUILDMYTHLI_HELP
			shift
		;;
		-v|--version)
			Mode=BUILDMYTHLI_VERSION
			shift
		;;
		-i|--init)
			Mode=BUILDMYTHLI_INIT
			shift
		;;
		--test)
			Mode=BUILDMYTHLI_TEST
			shift
		;;
		--init-type)
			shift
		;;
		-u|--url)
			Url=$argValue
			shift 2
		;;
		-d|--dir|--directory)
			Dir=$argValue
			shift 2
		;;
		--)
		shift
		break;;
	esac
done

ExecuteMode