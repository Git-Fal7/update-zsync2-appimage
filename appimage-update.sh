#!/bin/bash

if [ ! -f "$1" ]; then
 exit
fi

_grab=`cat $1 | grep -a "zsync"`
_num=1

for i in {1..10}
 do
  if [ $i = 10 ]; then
   echo '"gh-releases-zsync" string not found.'
   exit
  fi
  _spl=`echo ${_grab} | cut -d'|' -f ${i}`
  if [[ ${_spl: -17} == *gh-releases-zsync ]]; then
   _num=${i}
   break
  fi
 done

_check=`echo ${_grab} | cut -d'|' -f ${_num}`

echo ${_check: -17}

echo AUTHOR = `echo ${_grab} | cut -d'|' -f $((${_num} + 1))`
AUTHOR=`echo ${_grab} | cut -d'|' -f $((${_num} + 1))`
echo REPO = `echo ${_grab} | cut -d'|' -f $((${_num} + 2))`
REPO=`echo ${_grab} | cut -d'|' -f $((${_num} + 2))`
echo TAG = `echo ${_grab} | cut -d'|' -f $((${_num} + 3))`
TAG=`echo ${_grab} | cut -d'|' -f $((${_num} + 3))`

namefile=`echo ${finalurl} | rev | cut -d'/' -f 1| rev`

request=`curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${AUTHOR}/${REPO}/releases`

#reset
_num=0

# try to get the latest appimage & zsync releases
for n in {0..20}
 do
  if ! [[ `echo ${request} | jq ".[${n}].assets[].name" | grep '\.AppImage"'` == "" ]] && ! [[ `echo ${request} | jq ".[${n}].assets[].name" | grep '\.zsync"'` == "" ]]; then
   _num=${n}
   _s="true"
   break
  fi
  if [ $n == 20 ]; then
   echo "appimage and/or zsync files dont exist"
   exit
  fi
 done

url=`echo ${request} | jq ".[${_num}].assets[].browser_download_url" | grep '\.zsync"$' | cut -b 2- | rev | cut -b 2- | rev`

echo ${url}

cp $1 ./

wget ${url}

namefile=`echo ${url} | rev | cut -d'/' -f 1| rev`

_name=`cat ./${namefile} | grep -a "Filename" | cut -d' ' -f 2`
_oname=`echo $1 | rev | cut -d'/' -f 1 | rev`

if ! [ ${_oname} == ${_name} ]; then
  echo "not the same name, renaming"
  mv ./${_oname} ./${_name}
  _oname=${_name}
fi

./zsync2 ${url}
chmod +x ./${_oname}

#remove comment if you want to replace your original appimage
#mv ./${_name} $1

rm -rf ./${namefile}
rm -rf ./${_oname}.zs-old 
