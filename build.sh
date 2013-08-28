#!/bin/bash

targets=$1
p=`pwd`
pf=cosmo_mvpa
outputdir=${p}/doc/source/_static/

set -e



if [ "$targets" = "" ]; then
    echo "Usage: $0 [ all | data | matlab | doc ]"
    exit 1
fi

if [ $targets = "all" ]; then
    targets="matlab data doc"
fi

if [ `echo $targets | wc -w` -gt 1 ]; then
    for target in $targets; do
        $0 $target
    done
    exit 0
fi

case $targets in 
    doc)
        # build with sphinx 
        cd doc
        make html
    ;;

    data)
        # zip the data
        cd $p
        zip -r ${pf}_data.zip data
        mv ${pf}_data.zip $outputdir
        ls $outputdir
    ;;

    matlab)
        # zip matlab stuff
        matdir=mvpa
        extdir=external

        zip -r ${pf}_scripts.zip $matdir $extdir

        #rm -f ${p}/${matdir}/*.m
        #rm -f ${p}/${extdir}/*.m
        #rmdir ${p}/${extdir}
        #rmdir ${p}/${matdir}

        mv ${pf}_scripts.zip $outputdir
        ls $outputdir

    ;;

    *)
        echo "Illegal target: $targets"
        exit 1
    ;;
esac
