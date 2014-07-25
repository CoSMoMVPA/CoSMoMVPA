function msk=cosmo_feature_dim_match(ds, dim_label, dim_values, varargin)
% returns a mask indicating matching occurences in two arrays or cells
% relative to the second array using a dataset
%
% msk=cosmo_match(ds, haystack1, needle1[, needle2, haystack2, ...])
%
% Inputs:
%   ds                dataset struct or neighborhood struct
%   haystack*         numeric vector, or cell with strings. A string is
%                     also allowed and interpreted as the name of a feature
%                     dimension ('i','j' or 'k' in fmri datasets; 'chan',
%                     'time', or 'freq' in MEEG datasets), and its 
%                     respective values (from ds.a.dim.values{dim}, where
%                     dim is the dimension corresponding to haystack) as
%                     indexed by ds.fa.(haystack) are used as haystack.
%   needle*           numeric vector, or cell with strings. A string is
%                     also allowed and interpreted as {needle}. 
%                     A function handle is also allowed, in which case the
%                     value use for needle is the function applied to 
%                     the corresponding value in ds.a.dim.values.
%   
% Output:
%   msk               boolean array of the same size as haystack, with
%                     true where the value in haystack is equal to at least
%                     one value in needle. If multiple needle/haystack
%                     pairs are provided, then the haystack inputs should 
%                     have the same number of elements, and msk contains 
%                     the intersection of the individual masks. 
%
% Examples:
%   - % in an fmri dataset, get mask for first spatial dimension 'i' with 
%     % values in between 5 and 10 (inclusive)
%     msk=cosmo_feature_dim_match(ds,'i',5:10);
%
%   - get features mask for a few MEEG channels
%     msk=cosmo_feature_dim_match(ds,'chan',{'PO7','O6'});
%
%   - get features mask for features 50 ms before stimulus onset:
%     msk=cosmo_feature_dim_match(ds,'time',@(x) x<.05);
%
% Notes
%  - when haystack or needle are numeric vectors or cells of strings,
%    then this function behaves like cosmo_match (and does not consider
%    information in its first input argument ds).  
%
% See also: cosmo_match
%
% NNO Oct 2013
    if ~isstruct(ds)
        error('expected a struct as input');
    end
       
    if ~isfield(ds,'neighbors')
        cosmo_check_dataset(ds);
    end

    if ischar(dim_label)
        % get value for needle and haystack
        if ~isfield(ds,'a') || ~isfield(ds.a,'dim')
            error('no field .a.dim');
        end

        dim=cosmo_match(ds.a.dim.labels,dim_label);

        if isempty(dim)
            error('Unknown dimension %s in ds.a.dim.labels', dim_label);
        end

        vs=ds.a.dim.values{dim};
        if isa(dim_values,'function_handle')
            if isnumeric(vs)
                match_mask=dim_values(vs);
            else
                match_mask=cellfun(dim_values,vs,'UniformOutput',true);
            end
        else
            match_mask=cosmo_match(ds.a.dim.values{dim},dim_values);
        end

        % set new value based on indices of the matching mask
        dim_values=find(match_mask);
        dim_label=ds.fa.(ds.a.dim.labels{dim});
    end

    msk=cosmo_match(dim_label, dim_values);

    if nargin>3
        if mod(nargin,2)~=1
            error('Number of input arguments should be odd')
        end
        me=str2func(mfilename());
        msk_other=me(ds, varargin{:});

        if ~isequal(size(msk),size(msk_other))
            error('Mask size mismatch: %d x %d ~= %d x %d', ...
                    size(msk),size(msk_other))
        end

        msk=msk & msk_other;
    end
