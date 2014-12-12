function cosmo_publish_run_scripts(varargin)
% helper function to publish example scripts (for developers)
%
% cosmo_publish_build_html([force|fn])
%
% Inputs:
%   fn           filename of matlab file to publish (in the examples
%                directory)
%   '-force'     force rebuild, even if an output file is newer than the
%                corresponding output file
%   '-dry'       dry run: show which files would be published
%
% Notes:
%  - if no filename is given, then all files are rebuilt if necessary
%  - this function is intended for developers (to build the website)
%  - whether an output file is out of date is first determined using
%    git: if git shows no changes to the last commit of the input file
%    then it is assumed it is not out of date. If the input file has
%    been changed since the last commit (or never been comitted), then
%    the modification date is used to determine whether it is out of date.
%  - requirements
%    * a Unix-like system
%    * a working installation of git
%    * CoSMoMVPA code present in a git repository
%
% NNO Sep 2014

    [force, srcpat, dryrun]=process_input(varargin{:});

    % save original working directory
    pdir=pwd();
    cleaner1=onCleanup(@()cd(pdir));

    % run from CoSMoMVPA directory
    medir=fileparts(which(mfilename()));
    cd(medir);

    % set paths, relative to the location of this function
    srcdir=fullfile(medir,'../examples/');
    trgdir=fullfile(medir,'..//doc/source/_static/publish/');

    srcext='.m';
    trgext='.html';

    summaryfn='index.html';

    if ~exist(trgdir,'file');
        mkdir(trgdir);
    end

    srcfns=dir(fullfile(srcdir,[srcpat srcext]));
    nsrc=numel(srcfns);
    if nsrc==0
        error('No files found matching %s%s in %s',[srcpat srcext],srcdir);
    end

    outputs=cell(nsrc,1);

    p=path();
    has_pwd=~isempty(strfind(p,medir));
    if ~has_pwd
        addpath(medir)
        cleaner2=onCleanup(@()rmpath(medir));
    end

    total_time_took=0;

    output_pos=0;
    for k=1:nsrc
        cd(medir);
        srcfn=fullfile(srcdir,srcfns(k).name);
        [srcpth,srcnm,unused]=fileparts(srcfn);
        trgfn=fullfile(trgdir,[srcnm trgext]);

        [needs_update,build_msg]=target_needs_update(srcfn,trgfn);
        if force
            build_msg=sprintf('update forced: %s',srcfn);
        end

        fprintf(build_msg);

        do_update=needs_update || force;

        if do_update
            fprintf('\n   building ... ');
            cd(srcpth);
            is_built=false;
            clock_start=clock();
            try
                publish(srcnm, struct('outputDir',trgdir,'catchError',false));
                is_built=true;
            catch me
                if exist(trgfn,'file')
                    delete(trgfn);
                end

                warning('Unable to build %s%s: %s',srcnm,srcext,...
                                                me.message);
                fprintf('%s\n', me.getReport);
            end
            clock_end=clock();
            time_took=etime(clock_end,clock_start);
            total_time_took=total_time_took+time_took;

            cd(medir);

            if is_built
                outcome_msg=' done';
            else
                outcome_msg=' !! failed';
            end

            status_msg=sprintf('%s (%.1f sec)', outcome_msg,time_took);
        else
            status_msg='';
        end

        fprintf('%s\n', status_msg);

        output_pos=output_pos+1;
        outputs{output_pos}=srcnm;
    end

    fprintf('Processed %d files (%.1f sec)\n',output_pos,total_time_took);

    outputfn=fullfile(trgdir, summaryfn);
    fid=fopen(outputfn,'w');
    cleaner3=onCleanup(@()fclose(fid));
    fprintf(fid,['<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"'...
            '>\n']);
    fprintf(fid,['<HTML><HEAD><TITLE>Index of matlab outputs</TITLE>'...
                    '</HEAD>\n<BODY>Matlab output<UL>\n']);

    for k=1:output_pos
        nm=outputs{k};
        fprintf(fid,'<LI><A HREF="%s%s">%s</A></LI>\n',nm,trgext,nm);
    end
    fprintf(fid,['</UL>Back to <A HREF="../../index.html">index</A>.'...
                    '</BODY></HTML>\n']);
    fprintf('Index written to %s\n', outputfn);



function [force, srcpat, dryrun]=process_input(varargin)
    force=false;
    srcpat=[];
    dryrun=false;
    n=numel(varargin);

    for k=1:n
        arg=varargin{k};
        if ischar(arg)
            if strcmp(arg,'-force')
                force=true;
            elseif strcmp(arg,'-dry')
                dryrun=true;
            elseif ~isempty(srcpat)
                error('multiple inputs found, this is not supported');
            else
                srcpat=arg;
            end
        else
            error('Illegal argument at position %d - expected string', k);
        end
    end


    if isequal(srcpat,[])
        srcpat='*_*';
    end

function [tf,msg]=target_needs_update(srcfn,trgfn)
    % helper function to see if html is out of date
    [unused,root,srcext]=fileparts(srcfn);
    [unused,root_alt,trgext]=fileparts(trgfn);
    assert(isequal(root,root_alt));

    srcname=[root,srcext];
    trgname=[root,trgext];
    t_trg=time_last_changed(trgfn);
    if isnan(t_trg)
        % does not exist, so needs update
        tf=true;
        msg=sprintf('not found: %s', trgname);
        return;
    end

    if is_in_staging(srcfn) || is_untracked(srcfn)
        % changes since last commit, see when changes were made
        t_src=time_last_changed(srcfn);
        tf=isnan(t_src) || t_trg<t_src;
        msg=sprintf('modified: %s', srcname);
    else
        % no changes since last commit, see when last commit was made
        t_src=time_last_commit(srcfn);
        tf=isnan(t_src) || t_trg<t_src;
        msg=sprintf('recent commit: %s',srcname);
    end

    if ~tf
        msg=sprintf('up to date: %s',trgname);
    end

function t=time_last_changed(fn)
    d=dir(fn);
    if isempty(d)
        t=NaN;
        return
    end
    assert(numel(d)==1);
    t=(d.datenum-datenum(1970,1,1))*86400;

function r=run_git(args)
    prefix='export TERM=ansi; git ';
    cmd=[prefix args];

    [e,r]=unix(cmd);

    if e
        fprintf(2,'Unable to run git, or an error was produced\n');
        error(r);
    end

function tf=is_untracked(srcfn)
    untracked=run_git('ls-files . --exclude-standard --others');
    tf=cosmo_match({srcfn},untracked);


function t=time_last_commit(srcfn)
    cmd=sprintf('log -n 1 --pretty=format:%%ct -- %s',srcfn);
    r=run_git(cmd);

    t=str2double(regexp(r,'(\d*)','match','once'));

    if isempty(t)
        t=NaN;
    end
    assert(numel(t)==1);

function tf=is_in_staging(fn)
    in_staging_str=run_git('diff HEAD  --name-only | xargs basename');
    in_staging=cosmo_strsplit(in_staging_str,'\n');

    basefn=cosmo_strsplit(fn,filesep,-1);
    tf=cosmo_match({basefn},in_staging);

