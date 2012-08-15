#!/bin/bash
ScriptDir=`dirname $0`
source "$ScriptDir/libbuildmythli.sh"


rm -Rf "/home/tobias/Develop/projects/buildmythli/test"
InitRepository "https://github.com/Mythli/SqlDatabase.git" "/home/tobias/Develop/projects/buildmythli/test/git"
#InitRepository "http://nginx.org/download/nginx-1.2.3.tar.gz" "/home/tobias/Develop/projects/buildmythli/test/archive"
#InitRepository "http://cwowcms.googlecode.com/svn" "/home/tobias/Develop/projects/buildmythli/test/svn"

declare -A buildmythliArgs=( 
	["builddit"]="cow"
	["aa"]="test"
)

#InitRepository "svn://svn.lighttpd.net/xcache" "/home/tobias/Develop/projects/buildmythli/test/xcache"
#InitRepository "https://github.com/php/php-src.git" "/home/tobias/Develop/projects/buildmythli/test/php" "PHP-5.4.6"

#GenMakeFiles "/home/tobias/Develop/projects/buildmythli/test/archive" "$(declare -p buildmythliArgs)"