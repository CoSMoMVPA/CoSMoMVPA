function cosmo_publish_build_html(force)
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
% Notes to developers: 
% - for this function to function properly, it is required that 
%   comso_get_data_path returns an absolute path. This is because this 
%   function makes copies of the run_* scripts in a temporary directory 
%   with lines containing '% >@@>' or '% <@@<' removed, and scripts are run 
%   from that directory. When cosmo_get_data_path does not return an
%   absolute path then it may be unable to find the comso example data.
% - this function should be run from the cosmo root directory.
    
    
    pdir=pwd();
    medir=fileparts(which(mfilename()));
    if ~strcmpi(pdir, medir)
        error('The function %s should be run from its root directory (%s)',...
                mfilename(), medir)
    end
    srcdir=fullfile(pdir,'../examples/');
    trgdir=fullfile(pdir,'..//doc/source/_static/publish/');
    
    if isunix()
        tmpdir='/tmp';
    else
        error('Not implemented: temporary directory on non-unix platforms');
    end
    
    srcpat='run_*';
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
    
    outputs=cell(0);
    
    p=path();
    has_pwd=~isempty(findstr(pdir,p));
    if ~has_pwd
        addpath(pdir)
    end
    
    addpath(pdir);
    for k=1:nsrc
        cd(pdir);
        update=true;
        srcfn=fullfile(srcdir,srcfns(k).name);
        [p,srcnm,ext]=fileparts(srcfn);
        for j=1:ntrg
            [p,trgnm,ext]=fileparts(trgfns(j).name);
            if ~force && strcmp(srcnm, trgnm) && ...
                        srcfns(k).datenum < trgfns(j).datenum
                update=false;
                fprintf('skipping %s%s (%s%s)\n',...
                            trgnm,trgext,srcnm,srcext);
                outputs{end+1}=srcnm;
                break;
            end
        end
        
        if ~update
            continue;
        end
        
        fprintf('building: %s ...', srcnm);
        tmpfn=fullfile(tmpdir,srcfns(k).name);
        remove_annotation(srcfn, tmpfn);
        cd(tmpdir);
        is_built=false;
        try
            p=publish(srcnm, struct('outputDir',trgdir,'catchError',false));
            is_built=true;
        catch me
            fnout=fullfile(trgdir,[srcnm trgext]);
            if exist(fnout,'file')
                delete(fnout);
            end
            
            warning('Unable to build %s%s: %s', srcnm, srcext, me.message);
            fprintf('%s\n', me.getReport);
        end
        cd(pdir);
            
        if ~is_built
            continue
        end
        fprintf(' done\n');
        
        outputs{end+1}=srcnm;
    end
           
    if ~has_pwd
        rmpath(pdir);
    end
    
    outputfn=fullfile(trgdir, summaryfn);
    fid=fopen(outputfn,'w');
    fprintf(fid,['<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"'...
            '>\n']);
    fprintf(fid,'<HTML><HEAD><TITLE>Index of matlab outputs</TITLE></HEAD>\n');
    fprintf(fid,'<BODY>Matlab output<UL>\n');
    
    n=numel(outputs);
    for k=1:n
        nm=outputs{k};
        fprintf(fid,'<LI><A HREF="%s%s">%s</A></LI>\n',nm,trgext,nm);
    end
    fprintf(fid,'</UL>Back to <A HREF="../../index.html">index</A>.</BODY></HTML>\n');
    fclose(fid);
        
    fprintf('Index written to %s\n', outputfn); 
    
    
    function remove_annotation(srcfn,trgfn)
    
    if strcmpi(srcfn,trgfn)
        error('source and target are the same: %s', srcfn);
    end
    
    fid=fopen(srcfn);
    wid=fopen(trgfn,'w');
    
    while true
        line=fgetl(fid);
        if ~ischar(line)
            break
        end
        
        if startswith(line,'% >@@>') || startswith(line,'% <@@<')
            continue
        end
        
        fprintf(wid,'%s\n',line);
    end
    
    fclose(fid);
    fclose(wid);
    
        
    function s=startswith(haystack, needle)
    
    t=strtrim(haystack);
    n=numel(needle);
    if numel(t) < n
        s=false;
        return;
    end
    
    s=~isempty(strfind(t(1:n), needle));
        
    
    
    
    