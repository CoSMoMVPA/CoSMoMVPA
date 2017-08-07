function [split, nsplit]=cosmo_strsplit(string, delim, varargin)
% splits a string based on another delimeter string
%
% [split,n]=cosmo_strsplit(string[,delim,][pos1, delim2, pos2, delim2,...])
%
% Inputs:
%   string          input to be split
%   delim           delimiter string. delim can contain backslash-escaped
%                   characters that are interpreted by sprintf; for
%                   example '\t', '\n' and '\\' represent a tab, newline
%                   and backslash character, respectively.
%                   If omitted or equal to [], then the string is split
%                   based on whitespaces occuring in string
%
%   pos             (optional) a single index indicating which split part
%                   should be returned. If string is split in N elements,
%                   then a negative value for pos is equivalent to pos+1+N
%                   (similar to Python). For example, pos=-1 means that the
%                   last element is returned, and pos=-2 means that the
%                   element before the last element is returned.
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
%   n               the number of elements in split, if split is a cell;
%                   0 otherwise
%
% Examples:
%   % split by '*'
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','*')
%   >      'A'    'AbbAbA'    'AbA'    'A'    'Ab'
%
%   % split by 'A*A'
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A')
%   >   ''    'bbAb'    'b'    '*Ab'
%
%   % take second element after split
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A',2)
%   >  bbAb
%
%   % get last element after split
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A',-1)
%   >  *Ab
%
%   % split twice, first on 'A*A', take second element, then on 'A'
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A',2,'A')
%   >     'bb'    'b'
%
%   % take first element after second split
%   cosmo_strsplit('A*AbbAbA*AbA*A*Ab','A*A',2,'A',1)
%   >  bb
%
%   % illustrate effect of not using a delimiter string
%   % (which causes the string to be split by whitespace) and using
%   % a space as delimiter
%   cosmo_strsplit(' CoSMoMVPA makes live...  easy!')
%   >    'CoSMoMVPA'    'makes'    'live...'    'easy!'
%   cosmo_strsplit(' CoSMoMVPA makes live...  easy!',' ')
%   >     ''    'CoSMoMVPA'    'makes'    'live...'    ''    'easy!'
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

if ~ischar(string)
    error('first argument must be a string');
end

if nargin<2 || (~ischar(delim) && isequal(delim,[]))
    % split by white-space
    split=regexp(string,'(\S)*','match');
elseif ischar(delim)
    pat=regexptranslate('escape',sprintf(delim));
    split=regexp(string,pat,'split');
else
    error('Second argument, if provided, must be a string');
end

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
