#!/bin/bash

BUILDMYTHLI_CHECKOUT=0
BUILDMYTHLI_HELP=1
BUILDMYTHLI_VERSION=2

function PrintHelp
{
	echo "Usage: buildmythli [OPTION]... [URL]... [DIRECTORY]..."
	echo ""
	echo "	-h --help 		display this help and exit"
	echo "	-v --version 		output version information and exit"
	echo "	-c --checkout 		checkout a repository and generate the buildmythli script"
	echo "	   --checkout-type 	forces buildmythli to use this vcs rather than determining it"
	echo "	-u --url 		set the url for repository checkouts"
	echo "	-d --directory 		set the director into which the repository is checked out"
	echo ""
	echo "Report buildmythli bugs to build@mythli.net"
	exit 0
}

function PrintVersion
{
	echo "buildmythli version 0.1"
	exit 0
}

function CheckoutRepository
{
	echo ""
}

# Execute getopt
GetOptEscapeHelper=`getopt -o "hvcud" -l "help,version,checkout,url,dir:" \
      -n "buildmythli" -- "$@"`
eval set -- "$GetOptEscapeHelper"

Dir=""
Url=""
Mode=MODE_CHECKOUT

while true;
do
	argName=$1
	argValue=$2
	
	case "$argName" in
		-h|--help)
			Mode=MODE_HELP
			shift
		;;
		-v|--version)
			Mode=MODE_VERSION
			shift
		;;
		--checkout-type)
			
		;;
		-u|--url)
			Url=$argValue
			shift 2
		;;
		-d|--directory)
			Dir=$argValue
			shift 2
		;;
		--)
		shift
		break;;
	esac
done

case $Mode in
	BUILDMYTHLI_HELP)
		PrintHelp
	;;
	BUILDMYTHLI_VERSION)
		PrintVersion
	;;
	BUILDMYTHLI_CHECKOUT)
		
		CheckoutRepository "$Url" "$Dir"
	;;
esac
