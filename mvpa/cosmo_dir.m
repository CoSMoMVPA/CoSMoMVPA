function files=cosmo_dir(varargin)
% list files recursively in a directory
%
% files=cosmo_dir([directory][,file_pattern])
%
% Inputs:
%   directory      optional parent directory to look for files. If omitted
%                  the current directory is used.
%   file_pattern   optional pattern to match file names. The wildcards '*'
%                  (zero or more of any character) and '?' (any single
%                  character) can be used. If omitted, '*' is used, meaning
%                  that all files are listed.
% Output:
%   files          Px1 struct (if P files were found in the directory or
%                  recursively in any (sub^X)-directorie) with fields
%                  .name, .date, .bytes, .isdir, .datenum. Unlike the
%                  built-in 'dir' function, .name contains the path and
%                  filename.
%
% Notes:
%  - the output is similar to built-in 'dir', except that .name contains
%    the path of the files as well.
%  - to list files in a directory but not those in its subdirectories, use
%    the built-in 'dir' function.
%  - this function does not return '.' (current directory) or '..' (parent
%    directory.
%
% Examples:
%  % list recursively all files in the current directory
%  d=cosmo_dir();
%
%  % Assuming that the directory 'my_dir' exists, list recursively all
%  % files the directory contains
%  d=cosmo_dir('my_dir');
%
%  % Assuming that the directory 'my_file' does not exist, return
%  % either a struct with a single entry (if a file named 'my_file'
%  % exists), or an emtpy struct (if no such file exists)
%  d=cosmo_dir('my_file');%
%
%  % list recursively all files in the current directory for which the name
%  % ends with '.jpg'
%  d=cosmo_dir('*.jpg')
%
%  % list recursively all files in the directory 'my_dir' with extension
%  % '.jpg'
%  d=cosmo_dir('my_dir', '*.jpg')
%
%  % list recursively all files in my_dir that are two characters long,
%  % followed by the extension '.jpg'
%  d=cosmo_dir('my_dir', '??.jpg')
%
%  % list recursively all files in my_dir that start with 'a', followed by
%  % any character, followed by 'b', followed by any number of characters,
%  % followed by '.jpg'
%  d=cosmo_dir('my_dir', 'a?b*.jpg')
%
% See also: dir
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    [root_dir,file_pat]=process_arguments(varargin{:});

    file_re=['^' ... % start of the string
             regexptranslate('wildcard',file_pat) ...
             '$'];   % end of the string


    files=find_files_recursively(root_dir,file_re);

function [root_dir,file_pat]=process_arguments(varargin)
    narg=numel(varargin);
    if narg>2
        error('need at most two arguments');
    end

    if ~iscellstr(varargin)
        error('arguments must be strings');
    end

    root_dir='';
    file_pat='*';

    if narg>=1
        arg1=varargin{1};
        if isdir(arg1)
            root_dir=arg1;
            if narg>=2
                file_pat=varargin{2};
            end
        else
            if narg>=2
                error('Directory not found: ''%s''', arg1);
            end
            root_dir='';
            file_pat=arg1;
        end
    end


function res=find_files_recursively(root_dir,file_re)
    if isempty(root_dir)
        dir_arg={};
    else
        dir_arg={root_dir};
    end

    d=dir(dir_arg{:});
    n=numel(d);

    res_cell=cell(n,1);
    keep_msk=false(n,1);
    for k=1:n
        d_k=d(k);
        fn=d_k.name;

        % do not return current and parent directorys
        ignore_fn=strcmp(fn,'.') || strcmp(fn,'..');

        if ~ignore_fn
            path_fn=fullfile(root_dir, fn);

            if isdir(path_fn)
                % recursive call
                res=find_files_recursively(path_fn,file_re);

            elseif ~isempty(regexp(fn,file_re,'once'));
                % file matches the pattern
                d_k.name=path_fn;
                res=d_k;

            else
                % ignore file
                continue;
            end

            res_cell{k}=res;
            keep_msk(k)=true;
        end
    end

    if any(keep_msk)
        % at least one file found
        res_keep=res_cell(keep_msk);
        res=cat(1,res_keep{:});
    else
        % no files found, return empty struct
        if cosmo_wtf('is_octave')
            labels={'name','date','bytes','isdir',...
                        'datenum','statinfo'};
        else
            labels={'name','date','bytes','isdir',...
                        'datenum'};
        end
        n_labels=numel(labels);
        res=cell2struct(cell(n_labels,0),labels);
    end
