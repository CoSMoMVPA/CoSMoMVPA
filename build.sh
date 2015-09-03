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
        #scp -r ${webdir}/* ${host}:~/web/
        rsync -vcru ${webdir}/* ${host}:~/web/
    ;;

    xx)
        # hidden option: build and push to the website
        # Only intended for use by Nick Oosterhof
        for i in cleandoc website; do
            $0 $i || exit 1
        done

        documentation_files="doc/build AUTHOR copyright README.rst"
        zip -qr CoSMoMVPA_documentation_html.zip ${documentation_files}
        tar -zcf CoSMoMVPA_documentation_html.tar.gz ${documentation_files}
        rsync -vcru --remove-source-files CoSMoMVPA_documentation_html.* \
                                            db:~/web/_static/ || exit 1
    ;;

    *)
        echo "Illegal target: $targets"
        exit 1
    ;;
esac
