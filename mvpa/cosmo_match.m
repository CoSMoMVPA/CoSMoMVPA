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
%                     respective values (from ds.a.dim.values{dim}, where
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
%   - % simple character comparison
%     cosmo_match({'a','b','c'},{'b','c','d','e','b'})
%     > [false true true]
%   - % swap the order of inputs
%     cosmo_match({'b','c','d','e','b'},{'a','b','c'})
%     > [true true false false true]
%
%   - % in an fMRI dataset, get mask for features with with first spatial
%     % dimension indices 5 or 7.
%     msk=cosmo_match(ds.fa.i,[5 7]);
%
%   - % get mask for chunk values 1 and 4
%     msk=cosmo_match(ds.sa.chunks,[1 4]);
%
%   - % get mask for chunk values 1 and 4, and target values 1, 3 or 6.
%     msk=cosmo_match(ds.sa.chunks, [1 4], ds.sa.targets, [1 3 6]);
%
%   - % get feature mask for the fourth channel in an MEEG dataset
%     msk=cosmo_match(ds.fa.chan,4)
%
% Notes:
%   - the output of this function can be used with cosmo_slice
%     to select features or samples of interest
%   - to select feature dimension values in an fmri or meeg dataset 
%     (e.g., channel selection), see cosmo_feature_dim_match
%
% See also: cosmo_slice, cosmo_stack, cosmo_feature_dim_match
%
% NNO Sep 2013


    if nargin<2
        error('Need at least two input arguments')
    elseif mod(nargin,2) ~= 0
        error('Need an even number of input arguments');
    end
    
    % if needle is a string s, convert to cell {s}
    needle=just_convert_str2cell(needle);

    if isnumeric(haystack) && isnumeric(needle) && numel(needle)==1
        % optimization for most standard case: vector and scalar
        check_vec(haystack);
        msk=needle==haystack;
    elseif isa(needle,'function_handle')
        if iscell(haystack)
            msk=cellfun(needle,haystack,'UniformOutput',true);
        else
            msk=needle(haystack);
        end
    else
        tp=get_type(needle, haystack);
        nrows=check_vec(needle);
        ncols=check_vec(haystack);

        switch tp
            case 'numeric'
                matches=bsxfun(@eq, needle(:), haystack(:)');

            case 'cell_with_strings'
                matches=false(nrows,ncols);
                max_nchar_haystack=max(cellfun(@numel,haystack));
                for k=1:nrows
                    needlek=needle{k};
                    nchar=max(numel(needlek),max_nchar_haystack);
                    if nchar>0
                        match_indices=strncmp(needlek,haystack,nchar);
                        matches(k,match_indices)=true;
                    end
                end
        end
        msk=reshape(sum(matches,1)>0,size(haystack));
    end

    if nargin>2
        me=str2func(mfilename()); % immune to renaming
        other_msk=me(varargin{:});  % use recursion

        % check the size is the same
        if numel(msk) ~= numel(other_msk)
            error('Cannot make conjunction: masks have %d ~= %d elements',...
                    numel(msk), numel(other_msk));
        end

        % conjunction
        msk=msk & other_msk;
    end

function c=just_convert_str2cell(x)
    % only if x is a string, it is converted to char. otherwise x is returned
    if ischar(x)
        c={x};
    else
        c=x;
    end

function n=check_vec(x)
    % checks whether it's a vector, and if so, returns the number of elements
    sz=size(x);
    if numel(sz) ~= 2 || sum(sz>1)>1
        error('Input argument is not a vector');
    end
    n=numel(x);
        
function tp=get_type(needle, haystack)
    % returns a string indicating the type of needle and haystack. If needle
    % and haystack have different types an error is thrown

    types=struct();
    types.numeric=@isnumeric;
    types.cell_with_strings=@(x) iscell(x) && all(cellfun(@ischar,x));

    fns=fieldnames(types);
    for k=1:numel(fns)
        fn=fns{k};
        check_func=types.(fn);

        if check_func(needle) 
            if check_func(haystack)
                tp=fn; % matching type found
                return
            else
                error('second argument type %s but first is not',fn);
            end
        end
    end

    error('Unsupported type; type not one of %s.', cosmo_strjoin(fns,', '));