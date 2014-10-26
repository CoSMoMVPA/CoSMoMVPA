function cosmo_publish_run_scripts(varargin)
% helper function to publish example scripts (for developers)
%
% cosmo_publish_build_html([force|fn])
%
% Inputs:
%   force        boolean; indicates whether to always rebuild the output
%                even if it already exists. If false (the default), then
%                only run_* scripts that are newer than the output are
%                published again. If true, all run_* scripts are published
%                (rebuilt)
%   fn           filename of matlab file to build
%
% Notes:
%  - this function is intended for developers (to build the website)
%  - it requires
%    * a Unix-like system
%    * a working installation of git
%    * CoSMoMVPA code present in a git repository
%
% NNO Sep 2014

    [force, srcpat]=process_input(varargin{:});

    % save original working directory
    pdir=pwd();
    c=onCleanup(@()cd(pdir));

    medir=fileparts(which(mfilename()));
    cd(medir);

    srcdir=fullfile(medir,'../examples/');
    trgdir=fullfile(medir,'..//doc/source/_static/publish/');

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

    if isempty(srcfns)
        error('No files found matching %s%s in %s',[srcpat srcext],srcdir);
    end

    nsrc=numel(srcfns);

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
        trgfn=fullfile(trgdir,[srcnm trgext]);
        if ~force && ~needs_update(srcfn,trgfn);
            update=false;
            fprintf('skipping %s%s\n',...
                        srcnm,srcext);
            output_pos=output_pos+1;
            outputs{output_pos}=srcnm;
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
            fprintf(' !! building failed\n');
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
    fprintf(fid,['<HTML><HEAD><TITLE>Index of matlab outputs</TITLE>'...
                    '</HEAD>\n<BODY>Matlab output<UL>\n']);

    for k=1:output_pos
        nm=outputs{k};
        fprintf(fid,'<LI><A HREF="%s%s">%s</A></LI>\n',nm,trgext,nm);
    end
    fprintf(fid,['</UL>Back to <A HREF="../../index.html">index</A>.'...
                    '</BODY></HTML>\n']);
    fprintf('Index written to %s\n', outputfn);



function [force, srcpat]=process_input(varargin)
    force=false;
    srcpat=[];
    n=numel(varargin);

    for k=1:n
        arg=varargin{k};
        if ischar(arg)
            if strcmp(arg,'-force')
                force=true;
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

function tf=needs_update(srcfn,trgfn)
    % helper function to see if html is out of date
    [unused,root,unused]=fileparts(srcfn);
    [unused,root_alt,unused]=fileparts(trgfn);
    assert(isequal(root,root_alt));

    t_trg=time_last_changed(trgfn);
    if isnan(t_trg)
        % does not exist, so needs update
        tf=true;
        return;
    end

    t_src=time_last_commit(srcfn);
    if isnan(t_src) || is_in_staging(srcfn) || is_untracked(srcfn)
        % does not exist, or in staging, or untracked
        t_src=time_last_changed(srcfn);
    end

    % needs update if source file date unknown, or newer than html
    tf=isnan(t_src) || t_trg<t_src;


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

    t=str2num(regexp(r,'(\d*)','match','once'));

    if isempty(t)
        t=NaN;
    end


function tf=is_in_staging(fn)
    in_staging_str=run_git('diff HEAD  --name-only | xargs basename');
    in_staging=cosmo_strsplit(in_staging_str,'\n');

    tf=cosmo_match({cosmo_strsplit(fn,filesep,-1)},in_staging);

