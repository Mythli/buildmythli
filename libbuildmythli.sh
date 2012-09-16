#!/bin/bash
set -e
CHECKOUT_ARCHIVE=0
CHECKOUT_GIT=1
CHECKOUT_FOLDER=2
CHECKOUT_COPYFOLDER=3
CHECKOUT_SVN=3

GENTOOL_CMAKE=0
GENTOOL_AUTOTOOLS=1

function GetBaseDir {
	pathTo=$1
	if [ -z "$pathTo" ]; then
		pathTo='.'
	fi

    local parentDir=$(dirname "$pathTo")
    cd "$parentDir"
    local absolutePath="$(pwd)"/"$(basename $pathTo)"
    cd - >/dev/null
    echo ${absolutePath%/*}
}

function GetNumberOfCores {
	echo $(cat /proc/cpuinfo | grep processor | wc -l)
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
	local dir=$1
	local url=$2

	if [ -z "$url" ]; then
		if [ -n "$dir" ]; then
			echo $CHECKOUT_FOLDER
			return 0
		fi
	fi
	
	if [[ "$url" =~ ^.*((\.tar)|(\.gz))$ ]]; then
		echo $CHECKOUT_ARCHIVE
		return 0
	fi
	if [[ "$url" =~ ^.*\.git.*$ ]]; then
		echo $CHECKOUT_GIT
		return 0
	fi
	if [ -d "$url" ]; then
		echo $CHECKOUT_COPYFOLDER
		return 0
	fi
	if [[ "$url" =~ ^.*svn.*$ ]]; then
		echo $CHECKOUT_SVN
		return 0
	fi
	return 42
}

function LookupCheckoutType {
	local dir=$1

	if [ -d "$dir/src/.git" ]; then
		echo $CHECKOUT_GIT
		return 0
	fi
	if [ -d "$dir/src/.svn" ]; then
		echo $CHECKOUT_SVN
		return 0
	fi
	return 42
}

function LookupGenTool {
	local dir=$1

	if [ -e "$dir/src/CMakeLists.txt" ]; then
		echo $GENTOOL_CMAKE
		return 0
	fi
	
	local configurePath=$(FindConfigure "$dir")
	if [ -e $configurePath ]; then
		echo $GENTOOL_AUTOTOOLS
		return 0
	fi
	
	return 42
}

function MakeBuild {
	local dir=$1
	local buildDir=$2

	if [ -z $buildDir ]; then
		buildDir="$dir/build"
	fi
	(cd "$buildDir" && \
	make -j$(GetNumberOfCores) 2>&1 | tee "$dir/log/make.log")
}

function InstallBuild {
	local dir=$1
	local buildDir=$2
	if [ -z $buildDir ]; then
		buildDir="$dir/build"
	fi
	
	make --directory="$buildDir" install 2>&1 | tee "$dir/log/make.log"
}

function GenCMake {
	local dir=$1
	local genArgsStr=$2
	local argStr=""

	# check if serialized hashmap is defined and, is not empty
	if [[ "$genArgsStr" =~ ^.*\(.+\).*$ ]]; then
		# deserialize hashmap
		eval "declare -A genArgs="${genArgsStr#*=}
		# build cmake parameter string from hashmap
		for argName in "${!genArgs[@]}"; do
			local argValue=${genArgs["$argName"]}
			argStr="$argStr-D$argName=$argValue"
		done
	fi

	(cd "$dir/build" && \
	cmake "$dir/src $argStr" 2>&1 | tee "$dir/log/gen.log")
}

function GenAutoTools {
	local dir=$1
	local genArgsStr=$2
	local argStr=""

	# check if serialized hashmap is defined and, is not empty
	if [[ "$genArgsStr" =~ ^.*\(.+\).*$ ]]; then
		# deserialize hashmap
		eval "declare -A genArgs="${genArgsStr#*=}
	else
		declare -A genArgs=()
	fi

	# set default builddir if not specified
	if [ -z ${genArgs["--builddir"]} ]; then
		genArgs["builddir"]="$dir/build"
	fi

	# build autotools parameter string from hashmap
	for argName in "${!genArgs[@]}"; do
		local argValue=${genArgs["$argName"]}
		argStr="$argStr--$argName=$argValue"
	done

	(cd "$dir/src" && \
	$(FindConfigure "$dir") "$argStr" 2>&1 | tee "$dir/log/gen.log")
}

function UpdateGit {
  local dir=$1
  
  (cd "$dir/src" \
  git pull 2>&1 | tee -a "$dir/log/update.log")
}

function UpdateSvn {
	local dir=$1

	(cd "$dir/src" && \
	svn update  2>&1 | tee "$dir/log/gen.log")
}

function CheckoutSvn {
	local dir=$1
	local url=$2
	local branche=$3
	local repoUrl="$url/trunk";

	CreateFolderStructure "$dir"

	if [ $branche ]; then
		repoUrl="$url/branches/$branche"
	fi
	(cd $dir \
	svn checkout "$url/trunk" "$dir/src" 2>&1 | tee "$dir/log/init.log")
}

function CheckoutGit {
	local dir=$1
	local url=$2
	local branche=$3

	CreateFolderStructure "$dir"

	git clone "$url" "$dir/src" 2>&1 | tee "$dir/log/init.log"
	if [ $branche ]; then
		cd "$dir/src"
		git checkout $branche 2>&1 | tee "$dir/log/init.log"
	fi
}

function CheckoutArchive {
	local dir=$1
	local url=$2

	CreateFolderStructure "$dir"

	local fileName=$(mktemp)
	wget -O "$fileName" "$url" 2>&1 | tee "$dir/log/init.log"
	tar -vxzf "$fileName" -C "$dir/src" 2>&1 | tee -a "$dir/log/init.log"
	local archiveDirs=$(ls "$dir/src")
	for i in $archiveDirs; do
		(mv "$dir/src/$i/"* "$dir/src" && \
		rmdir "$dir/src/$i")
	done
	rm $fileName
}

function CheckoutFolder() (
    cd "$1"

    mkdir .CheckoutFolderTmp

    find -mindepth 1 -maxdepth 1 -not -name .CheckoutFolderTmp \
         -exec mv {} .CheckoutFolderTmp/{} \;

    mv .CheckoutFolderTmp src

    mkdir build log
)

function CheckoutCopyFolder {
	local dir=$1
	local url=$2

	CreateFolderStructure "$dir"
	cp -r "$url" "$dir/src"
}

function Checkout {
	local dir=$1
	local url=$2
	local branche=$3

	case $(ParseCheckoutType "$dir" "$url") in
		$CHECKOUT_ARCHIVE)
			echo $CHECKOUT_ARCHIVE
			CheckoutArchive "$dir" "$url"
			return 0
		;;
		$CHECKOUT_GIT)
			echo $CHECKOUT_GIT
			CheckoutGit "$dir" "$url" "$branche"
			return 0
		;;
		$CHECKOUT_FOLDER)
			echo $CHECKOUT_FOLDER
			CheckoutFolder "$dir"
			return 0
		;;
		$CHECKOUT_COPYFOLDER)
			echo $CHECKOUT_COPYFOLDER
			CheckoutCopyFolder "$dir" "$url"
			return 0
		;;
		$CHECKOUT_SVN)
			echo $CHECKOUT_SVN
			CheckoutSvn "$dir" "$url" "$branche";
			return 0
		;;
	esac
}

function Update {
	local dir=$1

	case $(LookupCheckoutType "$dir") in
		$CHECKOUT_GIT)
			echo $CHECKOUT_GIT
			UpdateGit $dir
			return 0
		;;
		$CHECKOUT_SVN)
			echo $CHECKOUT_SVN
			UpdateSvn $dir
			return 0
		;;
	esac
	return 42;
}

function GenMakeFiles {
	local dir=$1
	local genArgs=$2

	case $(LookupGenTool "$dir") in
		$GENTOOL_CMAKE)
			echo $GENTOOL_CMAKE
			GenCMake "$dir" "$genArgs"
			return 0
		;;
		$GENTOOL_AUTOTOOLS)
			echo $GENTOOL_AUTOTOOLS
			GenAutoTools "$dir" "$genArgs"
			return 0
		;;
	esac
	return 42;
}