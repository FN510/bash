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
  filecount=$(ls -al |grep '^-\|^l'|awk '{ print $9 }'|wc -l)
  if [ "$filecount" -gt 0 ]
    then
      # for the 5 biggest files
      for file in $(ls -Sal |grep '^-\|^l'|head -n 5|awk '{ print $9 }')
      do
        # assign its size to the array with path/to/file as its index
        biggest[$1/$file]="$(ls -lh|grep $file|awk '{ print $5 }')"
      done
    fi
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
echo "The five biggest files are:"
echo
# for size in array (biggest first)
for filepath in $(echo ${!biggest[@]})
do 
  # long list files, path and size column
  ls -l --block-size=KB $filepath| sed 's#/dcs/15/u1519685#~#g'| awk '{ printf "%-60s %-4s\n", $9, $5 }'
# sort by 2nd column(filesize), numerical, reverse(descending size) | top 5
done | sort -k2 -n -r| head -n 5