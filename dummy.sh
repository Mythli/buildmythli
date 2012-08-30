#!/bin/bash
set -e
BaseDir=$(dirname $0)
source "$BaseDir/libbuildmythli.sh"

case "$1" in
	install)
	;;
	uninstall)
	;;
	update)
	;;
esac
