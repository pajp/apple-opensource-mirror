#!/bin/bash

for project in * ; do
    (
	echo -n $project
	cd $project
	versions=$(git tag|grep -v os-x-|tr "\n" " ")
	echo -n " versions:"
	for version in $versions ; do
	    inosversions=$(git tag --points-at $version|grep os-x-|tr "\n" " ")
	    echo -n " $version"
	    for osversion in $inosversions ; do
		echo -n " ($osversion)"
		xattr -w nu.dll.aosm.${osversion} `date +%s` ../../projects/${project}-${version}
	    done
	done
	echo ""
    )
done
