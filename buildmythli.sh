#!/bin/bash
set -e
source "./libbuildmythli.sh"
BaseDir=$(GetBaseDir)

BUILDMYTHLI_INIT=0
BUILDMYTHLI_HELP=1
BUILDMYTHLI_VERSION=2
BUILDMYTHLI_TEST=3

CFXBold=$(tput bold)
CFXGreen=${CFXBold}$(tput setaf 2)
CFXDefault=$(tput sgr0)

function PrintHelp
{
	echo "Usage: buildmythli [OPTION]... [URL]... [DIRECTORY]..."
	echo ""
	echo "	-h --help 		display this help and exit"
	echo "	-v --version 		output version information and exit"
	echo "	-i --init 		init a repository and generate the buildmythli script"
	#echo "	   --init-type 		forces buildmythli to use this vcs rather than determining it"
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
	ln "$BaseDir"/libbuildmythli.sh "$dir"/.libbuildmythli.sh
	cp "$BaseDir"/buildmythli.dummy.sh "$dir"/buildmythli.sh
}

function InitRepository
{
	local url=$1
	local dir=$2
	
	echo "${CFXBold}Creating folder Structure in $dir...${CFXDefault}"
	CreateFolderStructure "$dir"
	
	echo "${CFXBold}Downloading source from $url...${CFXDefault}"
	Checkout "$url" "$dir" $type
	
	echo "${CFXBold}Writing buildmythli script to $dir/buildmythli.sh...${CFXDefault}"
	BuildMythliScript "$url" "$dir"
	
	echo "${CFXGreen}Repository initialized.${CFXDefault}"
}

function ExecuteMode
{
	local mode=$1
	local url=$2
	local dir=$3
	
	case $mode in
		BUILDMYTHLI_HELP)
			PrintHelp
		;;
		BUILDMYTHLI_VERSION)
			PrintVersion
		;;
		BUILDMYTHLI_INIT)
			InitRepository "$url" "$dir"
		;;
		BUILDMYTHLI_TEST)
			rm -Rf "$BaseDir/test"
			mkdir "$BaseDir/test"
			
			echo 'Git test...'
			$BaseDir/buildmythli.sh --init "https://github.com/Mythli/buildmythli.git" "/home/tobias/Develop/projects/buildmythli/test/git"
		;;
	esac
}

# Execute getopt
GetOptEscapeHelper=`getopt -o "hviu:d:" -l "help,version,init,init-type:,url:,dir:,test" \
      -n "buildmythli" -- "$@"`
eval set -- "$GetOptEscapeHelper"

Dir=""
Url=""
Mode=BUILDMYTHLI_HELP

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

if [ -z "$Url" ]; then
	Url=$1
fi

if [ -z "$Dir" ]; then
	Dir=$2
fi

ExecuteMode $Mode $Url $Dir