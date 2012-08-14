#!/bin/bash

set -e

function TryInitRepoSvn {
	local Url=$1
	local Dir=$2
	local Branche=$3
	
	local repoUrl="$Url/trunk";
	if [[ "$Url" =~ ^.*svn.*$ ]]; then
		if [ $Branche ]; then
			repoUrl="$Url/branches/$Branche"
		fi
		cd $Dir
		svn checkout "$Url/trunk" "$Dir/src"
		return 0
	fi
	return 42
}

function TryInitRepoGit {
	local Url=$1
	local Dir=$2
	local Branche=$3
	
	if [[ "$Url" =~ ^.*\.git.*$ ]]; then
		git clone "$Url" "$Dir/src" 2>&1 | tee "$Dir/log/init.log"
		if [ $Branche ]; then 
			echo "lutscher"
			git checkout $Branche 2>&1 | tee "$Dir/log/init.log"
		fi
		return 0
	fi
	return 42
}

function TryInitRepoArchive {
	local Url=$1
	local Dir=$2
	
	if [[ "$Url" =~ ^.*((\.tar)|(\.gz))$ ]]; then
		local fileName=$(mktemp)
		wget -O "$fileName" "$Url" 2>&1 | tee "$Dir/log/init.log"
		tar -vxzf "$fileName" -C "$Dir/src" 2>&1 | tee -a "$Dir/log/init.log"
		local archiveDirs=$( ls "$Dir/src")
		for i in $archiveDirs; do
			mv "$Dir/src/$i/"* "$Dir/src"
			rmdir $Dir/src/$i
		done
		rm $fileName
		return 0
	fi
	return 42
}

function GetNumberOfCores {
	return cores=`cat /proc/cpuinfo | grep processor | wc -l`
}

function MakeBuild {
	local Dir=$1
	local BuildDir = $2
	local cores=GetNumberOfCores
	echo "cd $BuildDir & make $1 -j$cores" &1 | tee -a "$Dir/log/build.log"
}

function TryCompileCMake {
	local Dir=$1
}

#31520

function TryCompileAutoTools {
	local Dir=$1
	
	local declare -a arguments=("${!2}")
	local configureBinarys = { "configure", "configure.sh"}
	local configured = 0
	(local ifs=$IFS
	local IFS=" "
	local argumentsStr="${arguments[*]}"
	IFS=$ifs)
		
	for i in "${configureBinarys}"
	do
		local binary = $Dir/src/$configureBinarys[i]
		if [ -e "$binary" ]; then
			echo "$binary $argumentsStr" &1 | tee -a  "$Dir/log/configure.log"
			configured = 1
		fi
	done
	
	MakeBuild $Dir "$Dir/build"
	
	if [ $configured ]; then return 0; else return -1; fi
}

function TryUpdateMake {
	local Dir=$1
}

function TryUpdateGit {
  local Dir=$1
  
  #if [ -d "$Dir" ]; then
    
  #fi
}

function TryUpdateSvn {
	local Dir = $1
}

function Compile {
	local Dir = $1
}

function Update {
	local Dir = $1
}

function CreateFolderStructure {
	local Dir=$1
	
	mkdir -p $Dir/{build,log,src}
}

function InitRepository {
	local Url=$1
	local Dir=$2
	local Branche=$3
  
	CreateFolderStructure $Dir
	if TryInitRepoGit "$Url" "$Dir" "$Branche"; then return 0; fi
	if TryInitRepoArchive "$Url" "$Dir"; then return 0; fi
	if TryInitRepoSvn "$Url" "$Dir" "$Branche"; then return 0; fi
	
	return 42;
}

rm -Rf "/home/tobias/Develop/projects/compile/test"
#InitRepository "https://github.com/Mythli/SqlDatabase.git" "/home/tobias/Develop/projects/compile/test/git"
#InitRepository "http://nginx.org/download/nginx-1.2.3.tar.gz" "/home/tobias/Develop/projects/compile/test/archive"
InitRepository "http://cwowcms.googlecode.com/svn" "/home/tobias/Develop/projects/compile/test/svn"