#!/bin/bash 

# START 
# if paramater is a directory
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
else
  echo $1 doesn\'t exist or you do not have access to it
  exit 1
fi

echo

function loopDir {
# Number of subdirectories (not including . and ..)
dircount=$(ls -al $1|grep '^d'|tail -n +3| wc -l)
if [ "$dircount" -gt 0 ]
 then
 # for every subdirectory (excl. dot and dotdot)
 # print its name
 # cd to it
 # call function for that directory
 for dir in $(ls -al | grep '^d'|tail -n +3|awk '{ print $9; }')
 do
  if [ -d "$dir" ] && [ -r "$dir" ]
    then
    cd $dir
    regfile=$(($regfile+$(ls -l|grep '^[^d]'|wc -l)-1))
    regdir=$(($regdir+$(ls -l|grep '^d'|wc -l)))
    hidfile=$(($hidfile+$(ls -al| grep '^[^d]'|awk '{ print $9 }'|grep '^\.'|wc -l)))
    hiddir=$(($hiddir+$(ls -al| grep '^d'| awk '{ print $9; }'|grep -E '^\.'|wc -l)))
    loopDir
    cd ..
  else
    echo $PWD/$dir is not accessible or the name has a space
    exit 1 
  fi
done
fi
}
# call to function
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
fi