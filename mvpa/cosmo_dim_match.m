function msk=cosmo_dim_match(ds, dim_label, dim_values, varargin)
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
%                     respective values (from ds.a.fdim.values{dim}, where
%                     dim is the dimension corresponding to haystack) as
%                     indexed by ds.fa.(haystack) are used as haystack.
%   needle*           numeric vector, or cell with strings. A string is
%                     also allowed and interpreted as {needle}.
%                     A function handle is also allowed, in which case the
%                     value use for needle is the function applied to
%                     the corresponding value in ds.a.fdim.values.
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
%
%     % in an fMRI dataset, get all features with the first voxel dimension
%     % between 5 and 10, inclusive
%     ds=cosmo_synthetic_dataset('type','fmri','size','huge');
%     cosmo_disp(ds.a.fdim.values{1});
%     > [ 1         2         3  ...  18        19        20 ]@1x20
%     cosmo_disp(ds.fa.i)
%     > [ 1         2         3  ...  18        19        20 ]@1x6460
%     msk=cosmo_dim_match(ds,'i',5:10);
%     ds_sel=cosmo_slice(ds,msk,2);
%     ds_pruned=cosmo_dim_prune(ds_sel);
%     cosmo_disp(ds_pruned.a.fdim.values{1});
%     > [ 5         6         7         8         9        10 ]
%     cosmo_disp(ds_pruned.fa.i)
%     > [ 1         2         3  ...  4         5         6 ]@1x1938
%
%     % For an MEEG dataset, get a selection of some channels
%     ds=cosmo_synthetic_dataset('type','meeg','size','huge');
%     cosmo_disp(ds.a.fdim.values{1});
%     > { 'MEG0111'
%     >   'MEG0112'
%     >   'MEG0113'
%     >      :
%     >   'MEG2641'
%     >   'MEG2642'
%     >   'MEG2643' }@306x1
%     cosmo_disp(ds.fa.chan)
%     > [ 1         2         3  ...  304       305       306 ]@1x5202
%     %
%     % select channels
%     msk=cosmo_dim_match(ds,'chan',{'MEG1843','MEG2441'});
%     ds_sel=cosmo_slice(ds,msk,2);
%     ds_pruned=cosmo_dim_prune(ds_sel);
%     %
%     % show result
%     cosmo_disp(ds_pruned.a.fdim.values{1}); % 'chan' is first dimension
%     > { 'MEG1843'
%     >   'MEG2441' }
%     cosmo_disp(ds_pruned.fa.chan)
%     > [ 1         2         1  ...  2         1         2 ]@1x34
%
%     % For an MEEG dataset, get a selection of time points between 0 and
%     % .3 seconds. A function handle is used to select these timepoints
%     ds=cosmo_synthetic_dataset('type','meeg','size','huge');
%     %
%     % select time points
%     selector=@(x) 0<=x & x<=.3;
%     msk=cosmo_dim_match(ds,'time',selector);
%     ds_sel=cosmo_slice(ds,msk,2);
%     ds_pruned=cosmo_dim_prune(ds_sel);
%     %
%     % show result
%     cosmo_disp(ds_pruned.a.fdim.values{2}); % 'time' is second dimension
%     > [ 0      0.05       0.1  ...  0.2      0.25       0.3 ]@1x7
%     cosmo_disp(ds_pruned.fa.time)
%     > [ 1         1         1  ...  7         7         7 ]@1x2142


%   % in an fmri dataset, get mask for first spatial dimension 'i' with
%   % values in between 5 and 10 (inclusive)
%
%   msk=cosmo_dim_match(ds,'i',5:10);
%
%   - get features mask for a few MEEG channels
%     msk=cosmo_dim_match(ds,'chan',{'PO7','O6'});
%
%   - get features mask for features 50 ms before stimulus onset:
%     msk=cosmo_dim_match(ds,'time',@(x) x<.05);
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
        cosmo_isfield(ds,{'a.fdim.labels','a.fdim.values'},true);

        dim=cosmo_match(ds.a.fdim.labels,dim_label);

        if isempty(dim)
            error('Unknown dimension %s in ds.a.fdim.labels', dim_label);
        end

        vs=ds.a.fdim.values{dim};
        if isa(dim_values,'function_handle')
            if isnumeric(vs)
                match_mask=dim_values(vs);
            else
                match_mask=cellfun(dim_values,vs,'UniformOutput',true);
            end
        else
            match_mask=cosmo_match(ds.a.fdim.values{dim},dim_values);
        end

        % set new value based on indices of the matching mask
        dim_values=find(match_mask);
        dim_label=ds.fa.(ds.a.fdim.labels{dim});
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
