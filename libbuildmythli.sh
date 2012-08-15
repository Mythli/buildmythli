#!/bin/bash

set -e

function GetNumberOfCores {
	echo `cat /proc/cpuinfo | grep processor | wc -l`
}

function CreateFolderStructure {
	local Dir=$1
	
	mkdir -p "$Dir/"{build,log,src}
}

function FindConfigure {
	local Dir=$1
	
	local configureBinarys=(
		"configure"
		"configure.sh"
	)
	for binaryName in ${configureBinarys[@]}
	do
		if [ -e "$Dir/src/$binaryName" ]; then
			echo "$Dir/src/$binaryName"
			return 0
		fi
	done
	return 42
}

function ParseCheckoutType {
	local $Url=$1
	
	if [[ "$Url" =~ ^.*((\.tar)|(\.gz))$ ]]; then
		echo "0"
		return 0
	fi
	if [[ "$Url" =~ ^.*\.git.*$ ]]; then
		echo "1"
		return 0
	fi
	if [[ "$Url" =~ ^.*svn.*$ ]]; then
		echo "2"
		return 0
	fi
	return 42
}

function LookupCheckoutType {
	local Dir=$1
	
	if [ -d "$Dir/src/.git" ]; then
		echo "1"
		return 0
	fi
	if [ -d "$Dir/src/.svn" ]; then
		echo "2"
		return 0
	fi
	return 42
}

function LookupGenTool {
	local Dir=$1
	
	if [ -e "$Dir/CMakeLists.txt" ]; then
		return 0
		echo "0"
	fi
	
	local configurePath=$(FindConfigure "$Dir")
	if [ -n $configurePath ]; then
		echo "1"
		return 0
	fi
	
	return 42
}

function MakeBuild {
	local Dir=$1
	local BuildDir=$2
	cd $BuildDir
	make $1 -j$(GetNumberOfCores) 2>&1 | tee "$Dir/log/make.log"
}

function GenCMake {
	local Dir=$1
	local GenArgsStr=$2
	
	local argStr=""
	if [ "$GenArgsStr" ]; then
		eval "declare -A GenArgs="${GenArgsStr#*=}
		for argName in "${!GenArgs[@]}"; do
			local argValue=${GenArgs["$argName"]}
			argStr="$argStr -D$argName=$argValue"
		done
	fi
	
	cd "$Dir/build"
	cmake "$Dir/src" "$argStr" 2>&1 | tee "$Dir/log/gen.log"
	
	return 42
}

function GenAutoTools {
	local Dir=$1
	local GenArgsStr=$2
	
	local argStr="--builddir=$Dir/build"
	if [ "$GenArgsStr" ]; then
		eval "declare -A GenArgs="${GenArgsStr#*=}
		for argName in "${!GenArgs[@]}"; do
			local argValue=${GenArgs["$argName"]}
			argStr="$argStr --$argName=$argValue"
		done
	fi
		
	cd "$Dir/src"
	#echo $Dir
	echo $(FindConfigure $Dir)
	echo "$(FindConfigure $Dir) $argStr" 2>&1 | tee "$Dir/log/gen.log"
	return 42
}

function UpdateGit {
  local Dir=$1
  
  cd "$Dir/src"
  git pull 2>&1 | tee -a "$Dir/log/update.log"
}

function UpdateSvn {
	local Dir = $1
	
	cd "$Dir/src"
	svn update  2>&1 | tee "$Dir/log/gen.log"
}

function CheckoutSvn {
	local Url=$1
	local Dir=$2
	local Branche=$3
	
	local repoUrl="$Url/trunk";
	if [ $Branche ]; then
		repoUrl="$Url/branches/$Branche"
	fi
	cd $Dir
	svn checkout "$Url/trunk" "$Dir/src" 2>&1 | tee "$Dir/log/init.log"
}

function CheckoutGit {
	local Url=$1
	local Dir=$2
	local Branche=$3
	
	git clone "$Url" "$Dir/src" 2>&1 | tee "$Dir/log/init.log"
	if [ $Branche ]; then
		cd "$Dir/src"
		git checkout $Branche 2>&1 | tee "$Dir/log/init.log"
	fi
}

function CheckoutArchive {
	local Url=$1
	local Dir=$2
		
	local fileName=$(mktemp)
	wget -O "$fileName" "$Url" 2>&1 | tee "$Dir/log/init.log"
	tar -vxzf "$fileName" -C "$Dir/src" 2>&1 | tee -a "$Dir/log/init.log"
	local archiveDirs=$( ls "$Dir/src")
	for i in $archiveDirs; do
		mv "$Dir/src/$i/"* "$Dir/src"
		rmdir $Dir/src/$i
	done
	rm $fileName
}

function Checkout {
	local Url=$1
	local Dir=$2
	local Branche=$3
	
	case $(ParseCheckoutType "$Url") in
		"0")
		CheckoutArchive "$Url" "$Dir" ;;
		"1")
		CheckoutGit "$Url" "$Dir" "$Branche" ;;
		"2")
		CheckoutSvn "$Url" "$Dir" "$Branche" ;;
	esac
}

function Update {
	local Dir = $1
	
	case $(LookupCheckoutType "$Dir") in
		"0")
		UpdateGit $Dir ;;
		"1")
		UpdateSvn $Dir ;;
	esac
	return 42
}

function GenMakeFiles {
	local Dir=$1
	local GenArgs=$2
	
	case $(LookupGenTool "$Dir") in
		"0")
		GenCMake "$Dir" "$GenArgs" ;;
		"1")
		GenAutoTools "$Dir" "$GenArgs" ;;
	esac
	return 42
}

function InitRepository {
	local Url=$1
	local Dir=$2
	local Branche=$3
  
	CreateFolderStructure "$Dir"
	Checkout $Url $Dir $Branche
}

#rm -Rf "/home/tobias/Develop/projects/compile/test"
#InitRepository "https://github.com/Mythli/SqlDatabase.git" "/home/tobias/Develop/projects/compile/test/git"
#InitRepository "http://nginx.org/download/nginx-1.2.3.tar.gz" "/home/tobias/Develop/projects/compile/test/archive"
#InitRepository "http://cwowcms.googlecode.com/svn" "/home/tobias/Develop/projects/compile/test/svn"

declare -A compileArgs=( 
	["builddit"]="cow"
	["aa"]="test"
)

#InitRepository "svn://svn.lighttpd.net/xcache" "/home/tobias/Develop/projects/compile/test/xcache"
#InitRepository "https://github.com/php/php-src.git" "/home/tobias/Develop/projects/compile/test/php" "PHP-5.4.6"

GenMakeFiles "/home/tobias/Develop/projects/compile/test/archive" "$(declare -p compileArgs)"