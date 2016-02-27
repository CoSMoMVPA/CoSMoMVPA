function is_ok=cosmo_publish_run_scripts(varargin)
% helper function to publish example scripts (for developers)
%
% cosmo_publish_build_html([force|fn])
%
% Inputs:
%   fn           filename of matlab file to publish (in the examples
%                directory)
%   '-force'     force rebuild, even if an output file is newer than the
%                corresponding output file
%   '-dry'       dry run: do not build any files, but show the output that
%                would be shown.
%   '-o', d      write output in directory d. By default d is
%                'doc/source/_static/publish/' relative to the CoSMoMVPA
%                root directory.
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
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % ensure 'publish' function is available
    cosmo_check_external('!publish',true);

    [srcfn_cell,opt]=process_input(varargin{:});
    trgdir=get_output_dir(opt);

    trgext=['.' opt.format];
    summaryfn=['index.' opt.format];

    orig_path=path();
    path_resetter=onCleanup(@()path(orig_path));

    if ~isdir(trgdir) && ~opt.dryrun;
        mkdir_recursively(trgdir);
    end

    nsrc=numel(srcfn_cell);
    outputs=cell(nsrc,1);

    total_time_took=0;
    output_pos=0;
    is_ok=true;

    for k=1:nsrc
        srcfn=srcfn_cell{k};
        [srcpth,srcnm]=fileparts(srcfn);

        if k==1
            addpath(srcpth);
        end

        trgfn=fullfile(trgdir,[srcnm trgext]);

        [needs_update,build_msg]=target_needs_update(srcfn,trgfn);
        if opt.force
            build_msg=sprintf('update forced: %s',srcfn);
        end

        fprintf(build_msg);

        do_update=needs_update || opt.force;

        if do_update
            fprintf('\n   building ... ');
            clock_start=clock();

            if opt.dryrun
                fprintf('<dry run>');
                is_built=true;
            else
                is_built=publish_helper(srcfn,trgfn);
            end

            clock_end=clock();
            time_took=etime(clock_end,clock_start);
            total_time_took=total_time_took+time_took;

            if is_built
                outcome_msg=' done';
            else
                outcome_msg=' !! failed';
                is_ok=false;
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

    if ~opt.dryrun
        write_index(outputfn,opt)
    end

function write_index(index_outputfn,opt)
    [outputdir,outputnm]=fileparts(index_outputfn);
    inputdir=fullfile(get_root_dir(),'examples');

    d=dir(fullfile(inputdir,'*.m'));


    fid=fopen(index_outputfn,'w');
    cleaner3=onCleanup(@()fclose(fid));
    fprintf(fid,['<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"'...
            '>\n']);
    fprintf(fid,['<HTML><HEAD><TITLE>Index of matlab outputs'...
                    '</TITLE></HEAD>\n<BODY>Matlab output<UL>\n']);

    for k=1:numel(d)
        [unused,nm]=fileparts(d(k).name);
        outputfn=sprintf('%s.%s',nm,opt.format);
        if exist(fullfile(outputdir,outputfn),'file')
            fprintf(fid,'<LI><A HREF="%s">%s</A></LI>\n',outputfn,nm);
        end
    end

    fprintf(fid,['</UL>Back to <A HREF="../../%s.html">index'...
                    '</A>.</BODY></HTML>\n'],outputnm);

    fprintf('Index written to %s\n', index_outputfn);


function trgdir=get_output_dir(opt)
    trgdir=opt.output_dir;
    if isempty(trgdir)
        trgdir=fullfile(get_root_dir(),'doc/source/_static/publish/');
    end

function d=get_root_dir()
    d=fileparts(fileparts(mfilename('fullpath')));

function is_built=publish_helper(srcfn,trgfn)
    is_built=false;
    try
        publish_wrapper(srcfn,trgfn);
        is_built=true;
    catch
        me=lasterror();

        if exist(trgfn,'file')
            delete(trgfn);
        end

        msg=sprintf('Unable to build %s: %s\n',srcfn,...
                                        me.message);

        s=me.stack;
        for j=1:numel(s)
            msg=sprintf('%s\n  %s:%s', msg, s(j).file, s(j).line);
        end

        cosmo_warning('%s',msg);
    end

function publish_wrapper(srcfn,trgfn)
    [srcdir,srcnm]=fileparts(srcfn);
    trgdir=fileparts(trgfn);

    orig_pwd=pwd();
    pwd_resetter=onCleanup(@()cd(orig_pwd));

    addpath(srcdir);
    cd(trgdir);
    if cosmo_wtf('is_matlab')
        args={struct('outputDir',trgdir,'catchError',false)};
        post_command=@do_nothing;
    else
        args={'format','html','imageFormat','jpg'};
        post_command=@()close('all');
    end

    publish(srcnm,args{:});
    post_command();


function do_nothing()
    % empty because do nothing


function [srcfn_cell,opt]=process_input(varargin)
    % set defaults
    srcpat='';

    opt=struct();
    opt.force=false;
    opt.dryrun=false;
    opt.format='html'; % currently not changeable
    opt.output_dir='';

    % process arguments
    n=numel(varargin);

    k=0;
    while k<n
        k=k+1;
        arg=varargin{k};
        if ischar(arg)
            if strcmp(arg,'-force')
                opt.force=true;
            elseif strcmp(arg,'-dry')
                opt.dryrun=true;
            elseif strcmp(arg,'-o')
                if k==n
                    error('Missing argument after %s',arg);
                end
                k=k+1;
                opt.output_dir=varargin{k};

            elseif ~isempty(srcpat)
                error('multiple inputs found, this is not supported');
            else
                srcpat=arg;
            end
        else
            error('Illegal argument at position %d - expected string', k);
        end
    end

    srcfn_cell=get_srcfn_cell(srcpat);

function srcfn_cell=get_srcfn_cell(srcpat)
    if isdir(srcpat)
        p=srcpat;
        nms={'run_*','demo_*'};
        e='.m';
    else
        [p,nm,e]=fileparts(srcpat);
        if isempty(p)
            p=fullfile(get_root_dir(),'examples');
        end

        if isempty(nm)
            nm='*';
        end

        if isempty(e)
            e='.m';
        end

        nms={nm};
    end

    ds=cellfun(@(nm)dir(fullfile(p,[nm e])),nms,'UniformOutput',false);
    d=cat(1,ds{:});
    n=numel(d);
    if n==0
        error('No input files found');
    end
    srcfn_cell=cellfun(@(fn)fullfile(p,fn),{d.name},'UniformOutput',false);



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

function mkdir_recursively(trgdir)
    parent=fileparts(trgdir);
    if ~isdir(parent)
        mkdir_recursively(parent);
    end
    mkdir(trgdir);

