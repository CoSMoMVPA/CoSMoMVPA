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

    cleandoc)
        cd doc
        make clean
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

        seldir=cosmo_mvpa_basic
        if [ ! -e $seldir ]; then
            mkdir $seldir
        else
            rm $seldir *
        fi

        for i in `find $matdir -name '*.m'`; do
            if [ `cat $i | grep '% >>' | wc -l` -eq 0 ]; then
                cp $i ${seldir}/
                echo "Adding $i"
            fi
        done

        zip -r ${pf}_scripts.zip $seldir $extdir

        #rm -f ${p}/${matdir}/*.m
        #rm -f ${p}/${extdir}/*.m
        #rmdir ${p}/${extdir}
        #rmdir ${p}/${matdir}

        mv ${pf}_scripts.zip $outputdir
        rm ${seldir}/*.m
        rmdir $seldir

        ls $outputdir

    ;;

    website)
        case $USER in
            nick)
                host=db  # hostname for scp
            ;;
            *)
                echo "Unsupported user $USER"
                exit 1
            ;;
        esac 
        webdir=doc/build/html/
        scp -r ${webdir}/* ${host}:~/web/
    ;;

    wb)
        # hidden option: build and push
        for i in cleandoc website; do
            $0 $i || exit 1
        done
    ;;

    *)
        echo "Illegal target: $targets"
        exit 1
    ;;
esac
