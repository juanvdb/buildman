#!/bin/bash

infile=$1			#File name of current apt
oldrelease=$2		#distro release of current apt - typically in the filename, precise, natty, ...
newrelease=$3		#distro of new release

echo "Infile="$infile
echo "Old Release="$oldrelease
echo "New Release="$newrelease


outfile=${infile/$oldrelease/$newrelease}
echo "Outfile="$outfile

cp $infile $outfile

sed -i.save -e "s/$oldrelease/$newrelease/" $outfile

sed -i.save -e 's/deb/#deb/' $infile

exit 0;




