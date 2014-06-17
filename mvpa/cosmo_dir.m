function files=cosmo_dir(directory,file_pattern)
% list files recursively in a directory, optionally matching a pattern
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
%  >> d=cosmo_dir()
%
%  % list recursively all files in my_dir
%  >> d=cosmo_dir('my_dir')
%
%  % list recursively all files in the current directory with extension 
%  % '.jpg'
%  >> d=cosmo_dir('my_d)
% 
%  % list recursively all files in my_dir with extension '.jpg'
%  >> d=cosmo_dir('my_dir', '*.jpg')
% 
%  % list recursively all files in my_dir that are two characters long,
%  % followed by the extension '.jpg'
%  >> d=cosmo_dir('my_dir', '??.jpg')
%
%  % list recursively all files in my_dir that start with 'a', followed by
%  % any character, followed by 'b', followed by any number of characters,
%  % followed by '.jpg'
%  >> d=cosmo_dir('my_dir', 'a?b*.jpg')
%
% See also: dir
%
% NNO Apr 2014

if nargin<1
    % use current directory
    directory='.';
end

if nargin<2 || isempty(file_pattern)
    % list all files
    file_pattern='*';
end

if ~isdir(directory)
    file_pattern=directory;
    directory='.';
end

me=[]; % in case of recursion, this is set to a handle of this function

% translate to regular expression
% (the '^' and '$' characters indicate the beginning and end of the string)
reg_pattern=['^' regexptranslate('wildcard',file_pattern) '$'];

% get file separator
sep=filesep();

% list of all files in directory
d=dir(directory);

% allocate space for result
n=numel(d);
files=cell(1,n);

pos=0; % last position where a result was stored
for k=1:n
    name=d(k).name;
    full_path=fullfile(directory,name);
    if isdir(full_path)
        if any(cosmo_match({'.','..'},name));
            % ignore current and parent directory
            continue
        end
      
        if isempty(me)
            % prepare first recursive call; make immune to function rename
            me=str2func(mfilename()); 
        end
        
        % get all files in this directory through recursion
        r=me(full_path,file_pattern);
        
        if ~isempty(r)
            % store result
            pos=pos+1;
            files{pos}=r;
        end
    elseif ~isempty(regexp(name,reg_pattern,'once'))
        % filename matches pattern, store result
        pos=pos+1;
        d(k).name=fullfile(directory,d(k).name);
        d(k).name;
        files{pos}=d(k);
    end
end

% only keep the entries that have data
files=files(1:pos);

% combine the structs
files=cat(1,files{:});