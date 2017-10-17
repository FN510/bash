#!/bin/bash 
#
declare -A biggest
# if paramater is a directory and readable
# cd to it
if [ -d "$1" ] && [ -r "$1" ]
  then
  cd $1
  # number of regular files
  regfile=$(ls -l |grep '^-\|^l'|wc -l)
  #  number of regular directories
  regdir=$(ls -l |grep '^d'|wc -l)
  # number of hidden files
  hidfile=$(ls -al |grep '^-\|^l'|awk '{ print $9 }'|grep '^\.'|wc -l)
  # number of hidden directories
  hiddir=$(ls -al | grep '^d'| awk '{ print $9; }'|grep -E '^\.'|wc -l)
  # total number of files in directory
else
  echo $1 directory doesn\'t exist or you do not have access to it
  exit 1
fi

echo

function loopDir {
# Number of subdirectories (not including . and ..)
dircount=$(ls -al $1|grep '^d'|tail -n +3| wc -l)
if [ "$dircount" -gt 0 ]
 then
 # for every subdirectory (excl. dot and dotdot)
 # cd to it
 # get stats
 # call function for that directory
 for dir in $(ls -al | grep '^d'|tail -n +3|awk '{ print $9; }')
 do
  if [ -d "$dir" ] && [ -r "$dir" ]
    then
    cd $dir
    filecount=$(ls -al |grep '^-\|^l'|awk '{ print $9 }'|wc -l)
    # if there is a file in the directory
    if [ "$filecount" -gt 0 ]
      then
      # for the 5 biggest files
      for file in $(ls -Sal |grep '^-\|^l'|head -n 5|awk '{ print $9 }')
      do
        # assign its size to the array with path/to/file as its index
        biggest[$PWD/$file]="$(ls -l|grep $file|awk '{ print $5 }')"
      done
    fi
    # collect dir stats
    regfile=$(($regfile+$(ls -l |grep '^-\|^l'|wc -l)))
    regdir=$(($regdir+$(ls -l|grep '^d'|wc -l)))
    hidfile=$(($hidfile+$(ls -al|grep '^-\|^l'|awk '{ print $9 }'|grep '^\.'|wc -l)))
    hiddir=$(($hiddir+$(ls -al|grep '^d'|awk '{ print $9; }'|grep -E '^\.'|wc -l)))
    # do it for the subdirectories
    loopDir
    cd ..
  else
    echo $PWD/$dir is not accessible or the name has a space
    exit 1 
  fi
done
fi
}

loopDir

# Sum of files and directories
total=$((regfile+regdir+hidfile+hiddir))
if [ $hidfile -gt 0 ]
  then
  echo "Number of files: $regfile (+$hidfile hidden)"
  echo "Number of directories: $regdir (+$hiddir hidden)"
  echo Total number of files and directories: $total
else
  echo "Number of files: $regfile (no hidden files)"
  echo "Number of directories: $regdir (+$hiddir hidden)"
  echo Total number of files and directories: $total
  echo
fi
# Arrays to store the permissions of files and directories that are incorrect
declare -A wrongDirPerms
declare -A wrongFilePerms
cd
phtmlperm=$(ls -ld public_html|awk '{ print $1 }')
echo "Permissions for public_html: $phtmlperm"
# if permission of public_html is not 557
# add permission to wrong array with filepath as index
if [ "$phtmlperm" != "drwxr-xr-x" ]
  then
  wrongDirPerms[$PWD/public_html]=$(ls -l| grep public_html| awk '{ print $1 }')
  chmod 755 $PWD/public_html
fi
cd public_html

function setPerm {

  function checkfile {
    for file in $(ls -l|grep ^-|awk '{ print $9 }')
    do
      printf '%-40s %-10s\n\n' "$(echo $PWD/$file|sed 's#/dcs/15/u1519685/public_html/##g'):" "$(ls -l| grep $file| awk '{ print $1 }')"
  # if file is a shell script and does not have permissions "-rwxr-xr-x"
  if [[ $file =~ .\sh$ ]] && [ "$(ls -l| grep $file| awk '{ print $1 }')" != "-rwxr-xr-x" ]
    then
    wrongFilePerms[$PWD/$file]=$(ls -l| grep "$file"| awk '{ print $1 }')
    chmod 755 $PWD/$file
    # else if file is not a shell script and does not have permissions "-rw-r--r--"
  elif  ! [[ $file =~ .\sh$ ]] && [ "$(ls -l| grep $file| awk '{ print $1 }')" != "-rw-r--r--" ]
    then
    wrongFilePerms[$PWD/$file]=$(ls -l| grep "$file"| awk '{ print $1 }')
    chmod 644 $PWD/$file
  fi
done
}

checkfile

function checkdir {
  for dir in $(ls -l|grep ^d|awk '{ print $9 }')
  do
    if [ "$(ls -l| grep $dir| awk '{ print $1 }')" != "drwxr-xr-x" ]
      then
      wrongDirPerms[$PWD/$dir]=$(ls -l| grep "$dir"| awk '{ print $1 }')
      chmod 755 $PWD/$dir
    fi
    
    cd $dir
    checkfile
    checkdir
    cd ..
  done
}

checkdir
}
setPerm
# for each index (path to file with incorrect permission)
for filepath in ${!wrongDirPerms[@]}
do
  printf '%-60s %-10s \n%-30s\n\n' "Directory $(echo $filepath|sed 's#/dcs/15/u1519685/public_html/##g') had the wrong permissions:" "${wrongDirPerms[$filepath]}"   "It has been changed to: $(ls -ld $filepath| awk '{ print $1 }')"
  echo
  echo
done

for filepath in ${!wrongFilePerms[@]}
do
  printf '%-60s %-10s \n%-30s\n\n' "File $(echo $filepath|sed 's#/dcs/15/u1519685/public_html/##g') had the wrong permissions:" "${wrongFilePerms[$filepath]}" "It has been changed to: $(ls -l $filepath| awk '{ print $1 }')"
done