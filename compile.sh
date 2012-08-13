#!/bin/bash

function TryInitRepoSvn {
	local Dir=$1
}

function TryInitRepoGit {
	local Url=$1
	local Dir=$2
	local Branche=$3
	set -e
	
	git clone "$Url" "$Dir" 2>&1 | tee "$Dir/log/init.log"
	return 0
}

function TryInitRepoArchive {
	local Url=$1
	local Dir=$2
	set -e
	
	local fileName=$(mktemp)
	wget -O "$fileName" "$Url" 2>&1 | tee "$Dir/log/init.log"
	tar -vxzf "$fileName" -C "$Dir/src" 2>&1 | tee -a "$Dir/log/init.log"
	for i in $( ls "$Dir/src" ); do
		mv "$Dir/src/$i/"* "$Dir/src"
		rmdir $Dir/src/$i
	done
	rm $fileName
	return 0
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
  
	CreateFolderStructure $Dir
	if TryInitRepoArchive $Url $Dir; then return 0; fi
	if TryInitRepoGit $Url $Dir; then return 0; fi
	#TryInitRepoGit $1 $2
	#TryInitRepoSvn $1 $2
	
	return -1;
}

InitRepository "http://nginx.org/download/nginx-1.2.3.tar.gz" "/home/tobias/Develop/projects/compile/test"