#!/bin/bash

CHECKOUT_ARCHIVE=0
CHECKOUT_GIT=1
CHECKOUT_SVN=2

GENTOOL_CMAKE=0
GENTOOL_AUTOTOOLS=1

function GetNumberOfCores {
	echo `cat /proc/cpuinfo | grep processor | wc -l`
}

function CreateFolderStructure {
	local dir=$1
	
	mkdir -p "$dir/"{build,log,src}
}

function FindConfigure {
	local dir=$1
	
	local configureBinarys=(
		"configure"
		"configure.sh"
	)
	for binaryName in ${configureBinarys[@]}
	do
		if [ -e "$dir/src/$binaryName" ]; then
			echo "$dir/src/$binaryName"
			return 0
		fi
	done
	return 42
}

function ParseCheckoutType {
	local url=$1
	
	if [[ "$url" =~ ^.*((\.tar)|(\.gz))$ ]]; then
		echo "$CHECKOUT_ARCHIVE"
		return 0
	fi
	if [[ "$url" =~ ^.*\.git.*$ ]]; then
		echo "$CHECKOUT_GIT"
		return 0
	fi
	if [[ "$url" =~ ^.*svn.*$ ]]; then
		echo "$CHECKOUT_SVN"
		return 0
	fi
	return 42
}

function LookupCheckoutType {
	local dir=$1
	
	if [ -d "$dir/src/.git" ]; then
		echo "$CHECKOUT_GIT"
		return 0
	fi
	if [ -d "$dir/src/.svn" ]; then
		echo "$CHECKOUT_SVN"
		return 0
	fi
	return 42
}

function LookupGenTool {
	local dir=$1
	
	if [ -e "$dir/CMakeLists.txt" ]; then
		return 0
		echo "$GENTOOL_CMAKE"
	fi
	
	local configurePath=$(FindConfigure "$dir")
	if [ -n $configurePath ]; then
		echo "$GENTOOL_AUTOTOOLS"
		return 0
	fi
	
	return 42
}

function MakeBuild {
	local dir=$1
	local BuildDir=$2
	
	if [ -z $BuildDir ]; then
		BuildDir="$dir/build"
	fi
	make $1 -j$(GetNumberOfCores) 2>&1 | tee "$BuildDir/log/make.log"
}

#function InstallBuild {
#	local Dir=$1
#	local BuildDir=$2
#	
#	
#}

function GenCMake {
	local dir=$1
	local genArgsStr=$2
	
	local argStr=""
	if [ "$genArgsStr" ]; then
		eval "declare -A GenArgs="${genArgsStr#*=}
		for argName in "${!GenArgs[@]}"; do
			local argValue=${GenArgs["$argName"]}
			argStr="$argStr -D$argName=$argValue"
		done
	fi
	
	cd "$dir/build"
	cmake "$dir/src" "$argStr" 2>&1 | tee "$dir/log/gen.log"
	
	return 42
}

function GenAutoTools {
	local dir=$1
	local genArgsStr=$2
	
	local argStr="--builddir=$dir/build"
	if [ "$genArgsStr" ]; then
		eval "declare -A GenArgs="${genArgsStr#*=}
		for argName in "${!GenArgs[@]}"; do
			local argValue=${GenArgs["$argName"]}
			argStr="$argStr --$argName=$argValue"
		done
	fi
		
	cd "$dir/src"
	$(FindConfigure "$dir") "$argStr" 2>&1 | tee "$dir/log/gen.log"
	return 42
}

function UpdateGit {
  local dir=$1
  
  cd "$dir/src"
  git pull 2>&1 | tee -a "$dir/log/update.log"
}

function UpdateSvn {
	local dir = $1
	
	cd "$dir/src"
	svn update  2>&1 | tee "$dir/log/gen.log"
}

function CheckoutSvn {
	local url=$1
	local dir=$2
	local branche=$3
	
	local repoUrl="$url/trunk";
	if [ $branche ]; then
		repoUrl="$url/branches/$branche"
	fi
	cd $dir
	svn checkout "$url/trunk" "$dir/src" 2>&1 | tee "$dir/log/init.log"
}

function CheckoutGit {
	local url=$1
	local dir=$2
	local branche=$3
	
	git clone "$url" "$dir/src" 2>&1 | tee "$dir/log/init.log"
	if [ $branche ]; then
		cd "$dir/src"
		git checkout $branche 2>&1 | tee "$dir/log/init.log"
	fi
}

function CheckoutArchive {
	local url=$1
	local dir=$2
		
	local fileName=$(mktemp)
	wget -O "$fileName" "$url" 2>&1 | tee "$dir/log/init.log"
	tar -vxzf "$fileName" -C "$dir/src" 2>&1 | tee -a "$dir/log/init.log"
	local archiveDirs=$( ls "$dir/src")
	for i in $archiveDirs; do
		mv "$dir/src/$i/"* "$dir/src"
		rmdir "$dir/src/$i"
	done
	rm $fileName
}

function Checkout {
	local url=$1
	local dir=$2
	local branche=$3
	
	case $(ParseCheckoutType "$url") in
		"0")
		CheckoutArchive "$url" "$dir" ;;
		"1")
		CheckoutGit "$url" "$dir" "$branche" ;;
		"2")
		CheckoutSvn "$url" "$dir" "$branche" ;;
	esac
}

function Update {
	local dir = $1
	
	case $(LookupCheckoutType "$dir") in
		"0")
		UpdateGit $dir ;;
		"1")
		UpdateSvn $dir ;;
	esac
	return 42
}

function GenMakeFiles {
	local dir=$1
	local GenArgs=$2
	
	case $(LookupGenTool "$dir") in
		"0")
		GenCMake "$dir" "$GenArgs" ;;
		"1")
		GenAutoTools "$dir" "$GenArgs" ;;
	esac
	return 42
}