function [split, nsplit]=cosmo_strsplit(string, delim, varargin)
% splits a string based on another delimeter string
%
% split=cosmo_strsplit(string, delim, [pos1, delim2, pos2, delim2,...])
%
% Inputs:
%   string          input to be split
%   delim           delimiter string. delim can contain backslash-escaped 
%                   characters that are interpreted by sprintf; for 
%                   example '\t' represents a tab character, '\n' a 
%                   newline character, and '\\' a backslash.
%             character
%   pos             (optional) a single index indicating which split part 
%                   should be returned. If string is split in N elements,
%                   then a negative value for pos is equivalent to pos+1+N.
%                   If omitted a cell with all parts are returned.
%   delim*          (optional) subsequent delimeters applied after applying 
%                   pos. It requires that the preceding pos has a single
%                   value.
%
% Output:
%   split           when the last argument is non-positional, split is a 
%                   cell with the string split by delim. When there are N
%                   non-overlapping occurences of delim in string, then
%                   split has N+1 elements, and the string
%                   [delim split{1} delim split{2} ... split{N} delim] 
%                   is equal to string.
%                   If the last argument is positional, then split is
%                   a string with value split_{pos} where split_ is the
%                   result if pos where not the last arugment.
%   nsplit          the number of elements in split, if split is a cell; 
%                   or 0 otherwise
%
% Examples:
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','*')
%   >  {''A', 'AbbAbA', 'AbA', 'A', 'Ab'}
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A')
%   >  {'', 'bbAb','b','*Ab'
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A',2)
%   >  'bbAB'   % second element
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A',-1)
%   >  '*Ab'    % last element
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A',2,'A')
%   >  {'bb','b'}  % split second result of split by 'A*A' by 'A'
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A',2,'A',1)
%   >  'bb' 
%
% NNO Sep 2013
   

pat=regexptranslate('escape',sprintf(delim));
split=regexp(string,pat,'split');
nsplit=numel(split);

if nargin>2
    pos=varargin{1};
    if numel(pos)~=1, error('Need scalar position argument'); end
    
    if pos<0
        nsplit=numel(split);
        pos=pos+nsplit+1;
    end
    
    % select element indicated by index
    split=split{pos};
    nsplit=0;
    
    if nargin>3
        me=str2func(mfilename()); % make imune to renaming
        [split, nsplit]=me(split, varargin{2:end}); % use recursion
    end
end


