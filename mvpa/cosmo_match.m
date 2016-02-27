function msk=cosmo_match(haystack, needle, varargin)
% returns a mask indicating matching occurences in two arrays or cells
% relative to the second array
%
% msk=cosmo_match(haystack1, needle1[, needle2, haystack2, ...])
%
% Inputs:
%   haystack*         numeric vector, or cell with strings. A string is
%                     also allowed and interpreted as the name of a feature
%                     dimension ('i','j' or 'k' in fmri datasets; 'chan',
%                     'time', or 'freq' in MEEG datasets), and its
%                     respective values (from ds.a.fdim.values{dim}, where
%                     dim is the dimension corresponding to haystack) as
%                     indexed by ds.fa.(haystack) are used as haystack.
%   needle*           numeric vector, or cell with strings. A string is
%                     also allowed and interpreted as {needle}.
%
% Output:
%   msk               boolean array of the same size as haystack, with
%                     true where the value in haystack is equal to at least
%                     one value in needle. If multiple needle/haystack
%                     pairs are provided, then the haystack inputs should
%                     have the same number of elements, and msk contains
%                     the intersection of the individual masks.
%
% Examples
%     % simple character comparison
%     cosmo_match({'a','b','c'},{'b','c','d','e','b'})
%     > [false true true]
%     % swap the order of inputs
%     cosmo_match({'b','c','d','e','b'},{'a','b','c'})
%     > [true true false false true]
%
%     % in an fMRI dataset, get mask for features with with first spatial
%     % dimension indices 5 or 7.
%     msk=cosmo_match(ds.fa.i,[5 7]);
%
%     % get mask for chunk values 1 and 4
%     msk=cosmo_match(ds.sa.chunks,[1 4]);
%
%     % get mask for chunk values 1 and 4, and target values 1, 3 or 6.
%     msk=cosmo_match(ds.sa.chunks, [1 4], ds.sa.targets, [1 3 6]);
%
%     % get feature mask for the fourth channel in an MEEG dataset
%     msk=cosmo_match(ds.fa.chan,4)
%
% Notes:
%   - the output of this function can be used with cosmo_slice
%     to select features or samples of interest
%   - to select feature dimension values in an fmri or meeg dataset
%     (e.g., channel selection), see cosmo_dim_match
%
% See also: cosmo_slice, cosmo_stack, cosmo_dim_match
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2
        error('Need at least two input arguments');
    elseif mod(nargin,2) ~= 0
        error('Need an even number of input arguments');
    end

    if ischar(needle)
        needle={needle};
    end

    msk=match(needle,haystack);

    for argpos=1:2:(nargin-2);
        other_msk=match(varargin{argpos+[1,0]});

        % check the size is the same
        if numel(msk) ~= numel(other_msk)
            error('Illegal conjunction: masks have %d ~= %d elements',...
                    numel(msk), numel(other_msk));
        end

        % conjunction
        msk=msk & other_msk;
    end

function msk=match(needle,haystack)
    % wrapper function that calls match_{scalar,functio_handle,vectors}
    if isnumeric(haystack) && isnumeric(needle) && numel(needle)==1
        % optimization for most standard case: vector and scalar
        msk=match_numeric_scalar(needle,haystack);
    elseif ~iscell(needle) && ~ischar(needle) && ~isnumeric(needle) && ...
                                            isa(needle,'function_handle')
        % function handle
        msk=match_function_handle(needle, haystack);
    else
        msk=match_vectors(needle, haystack);
    end


function msk=match_numeric_scalar(needle,haystack)
    % needle is a numeric scalar
    check_vec_or_empty(haystack);
    msk=needle==haystack;

function msk=match_function_handle(func, data)
    check_vec_or_empty(data);
    if iscell(data)
        msk=cellfun(func,data,'UniformOutput',true);
    else
        msk=func(data);
    end

    if ~islogical(msk)
        error('function %s should return boolean array',func2str(func));
    end

function msk=match_vectors(needle, haystack)
    nrows=check_vec_or_empty(needle);
    ncols=check_vec_or_empty(haystack);

    if isnumeric(needle) && isnumeric(haystack)
        matches=bsxfun(@eq, needle(:), haystack(:)');
    elseif iscell(needle) && iscell(haystack)
        matches=false(nrows,ncols);

        for k=1:ncols
            if ~ischar(haystack{k})
                error('cell must contain strings');
            end
        end

        for k=1:nrows
            needlek=needle{k};
            if ~ischar(needlek)
                error('cell must contain strings');
            end
            match_indices=strcmp(needlek,haystack);
            matches(k, match_indices)=true;
        end
    else
        error(['Illegal inputs %s and %s: need numeric arrays or '...
                'cell with strings'],class(needle),class(haystack));
    end

    if isempty(matches)
        msk=false(size(haystack));
    else
        msk=reshape(sum(matches,1)>0,size(haystack));
    end

function n=check_vec_or_empty(x)
    % this function returns the number of elements of the input
    % it returns true if x is a vector or if x is empty
    n=numel(x);
    if n>0 && ~isvector(x)
        error('Input argument is not a vector');
    end


