function cosmo_publish_run_scripts(force)
% helper function to publish the run_* scripts of cosmo. Intended for
% developers only.
%
% cosmo_publish_build_html([force])
%
% Inputs:
%   force        boolean; indicates whether to always rebuild the output
%                even if it already exists. If false (the default), then
%                only run_* scripts that are newer than the output are
%                published again. If true, all run_* scripts are published
%                (rebuilt)
%
%

    % save original working directory
    pdir=pwd();
    c=onCleanup(@()cd(pdir));

    medir=fileparts(which(mfilename()));
    cd(medir);

    srcdir=fullfile(medir,'../examples/');
    trgdir=fullfile(medir,'..//doc/source/_static/publish/');

    srcpat='*_*';
    srcext='.m';
    trgext='.html';

    summaryfn='index.html';

    if nargin<1
        force=false;
    end

    if ~exist(trgdir,'file');
        mkdir(trgdir);
    end

    srcfns=dir(fullfile(srcdir,[srcpat srcext]));
    trgfns=dir(fullfile(trgdir,[srcpat trgext]));

    nsrc=numel(srcfns);
    ntrg=numel(trgfns);

    outputs=cell(nsrc,1);

    p=path();
    has_pwd=~isempty(strfind(p,medir));
    if ~has_pwd
        addpath(medir)
    end

    output_pos=0;
    for k=1:nsrc
        cd(medir);
        update=true;
        srcfn=fullfile(srcdir,srcfns(k).name);
        [srcpth,srcnm,unused]=fileparts(srcfn);
        for j=1:ntrg
            [unused,trgnm,unused]=fileparts(trgfns(j).name);
            if ~force && strcmp(srcnm, trgnm) && ...
                        srcfns(k).datenum < trgfns(j).datenum
                update=false;
                fprintf('skipping %s%s (%s%s)\n',...
                            trgnm,trgext,srcnm,srcext);
                output_pos=output_pos+1;
                outputs{output_pos}=srcnm;
                break;
            end
        end

        if ~update
            continue;
        end

        fprintf('building: %s ...', srcnm);
        cd(srcpth);
        is_built=false;
        try
            publish(srcnm, struct('outputDir',trgdir,'catchError',false));
            is_built=true;
        catch me
            fnout=fullfile(trgdir,[srcnm trgext]);
            if exist(fnout,'file')
                delete(fnout);
            end

            warning('Unable to build %s%s: %s', srcnm, srcext, me.message);
            fprintf('%s\n', me.getReport);
        end
        cd(medir);

        if ~is_built
            continue
        end
        fprintf(' done\n');

        output_pos=output_pos+1;
        outputs{output_pos}=srcnm;
    end

    if ~has_pwd
        rmpath(medir);
    end

    outputfn=fullfile(trgdir, summaryfn);
    fid=fopen(outputfn,'w');
    c_=onCleanup(@()fclose(fid));
    fprintf(fid,['<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"'...
            '>\n']);
    fprintf(fid,'<HTML><HEAD><TITLE>Index of matlab outputs</TITLE></HEAD>\n');
    fprintf(fid,'<BODY>Matlab output<UL>\n');

    for k=1:output_pos
        nm=outputs{k};
        fprintf(fid,'<LI><A HREF="%s%s">%s</A></LI>\n',nm,trgext,nm);
    end
    fprintf(fid,'</UL>Back to <A HREF="../../index.html">index</A>.</BODY></HTML>\n');
    fprintf('Index written to %s\n', outputfn);



