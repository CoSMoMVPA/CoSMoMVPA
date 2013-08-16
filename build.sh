#!/bin/bash

targets=$1
p=`pwd`
pf=cosmo_mvpa
outputdir=${p}/scripts/doc/source/_static/

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
        cd scripts/doc
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
        matdir=cosmo_mvpa_basic
        extdir=${matdir}/external

        niftidir=`cd external/NIFTI* && pwd`
        srcdir=${p}/scripts/src

        if [ -e $matdir ]; then
            rm -rf $matdir
        fi

        mkdir $matdir
        mkdir $extdir

        niifiles="load_nii.m save_nii.m"
        for niifile in $niifiles; do 
            cp ${niftidir}/${niifile} $extdir
        done

        ls $extdir

        for f in `find $srcdir -name '*.m'`; do
            c=`grep '% >>' $f | wc -w`
            if [ $c -eq 0 ]; then
                cp ${f} ${matdir}/
            fi
        done

        zip -r ${pf}_scripts.zip $matdir

        rm -f ${p}/${matdir}/*.m
        rm -f ${p}/${matdir}

        mv ${pf}_scripts.zip $outputdir
        ls $outputdir

    ;;

    *)
        echo "Illegal target: $targets"
        exit 1
    ;;
esac
