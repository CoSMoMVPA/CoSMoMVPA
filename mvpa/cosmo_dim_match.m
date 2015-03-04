function msk=cosmo_dim_match(ds, dim_label, dim_values, varargin)
% return a mask indicating match of dataset dimensions with values
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
%   dim               If the last argument, it sets the dimension along
%                     which dim_label has to be found. If omitted it
%                     finds the dimension in the dataset
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
%     % no pruning, so the fdim.values are not changed. A subset fo
%     % features is selected
%     cosmo_disp(ds_sel.a.fdim.values{1});
%     > [ 1         2         3  ...  18        19        20 ]@1x20
%     cosmo_disp(ds_sel.fa.i)
%     > [ 5         6         7  ...  8         9        10 ]@1x1938
%
%     % For an MEEG dataset, get a selection of some channels
%     ds=cosmo_synthetic_dataset('type','meeg','size','huge');
%     cosmo_disp(ds.a.fdim.values{1},'edgeitems',2);
%     > { 'MEG0111'  'MEG0112'  ... 'MEG2642'  'MEG2643'   }@1x306
%     cosmo_disp(ds.fa.chan)
%     > [ 1         2         3  ...  304       305       306 ]@1x5202
%     %
%     % select channels
%     msk=cosmo_dim_match(ds,'chan',{'MEG1843','MEG2441'});
%     ds_sel=cosmo_slice(ds,msk,2);
%     %
%     % apply pruning, so that the .fa.chan goes from 1:nf, with nf the
%     % number of channels that were selected
%     ds_pruned=cosmo_dim_prune(ds_sel);
%     %
%     % show result
%     cosmo_disp(ds_pruned.a.fdim.values{1}); % 'chan' is first dimension
%     > { 'MEG1843'
%     >   'MEG2441' }
%     cosmo_disp(ds_pruned.fa.chan)
%     > [ 1         2         1  ...  2         1         2 ]@1x34
%     %
%     % For the same MEEG dataset, get a selection of time points between 0
%     % and .3 seconds. A function handle is used to select the timepoints
%     selector=@(x) 0<=x & x<=.3; % use element-wise logical-and
%     msk=cosmo_dim_match(ds,'time',selector);
%     ds_sel=cosmo_slice(ds,msk,2);
%     ds_pruned=cosmo_dim_prune(ds_sel);
%     %
%     % show result
%     cosmo_disp(ds_pruned.a.fdim.values{2}); % 'time' is second dimension
%     > [ 0      0.05       0.1  ...  0.2      0.25       0.3 ]@1x7
%     cosmo_disp(ds_pruned.fa.time)
%     > [ 1         1         1  ...  7         7         7 ]@1x2142
%     %
%     % For the same MEEG dataset, compute a conjunction mask of the
%     % channels and time points selected above
%     msk=cosmo_dim_match(ds,'chan',{'MEG1843','MEG2441'},'time',selector);
%     ds_sel=cosmo_slice(ds,msk,2);
%     ds_pruned=cosmo_dim_prune(ds_sel);
%     %
%     % show result
%     cosmo_disp(ds_pruned.a.fdim.values); % 'chan' and 'time'
%     > { { 'MEG1843'  'MEG2441' }
%     >   [ 0      0.05       0.1  ...  0.2      0.25       0.3 ]@1x7 }
%     cosmo_disp(ds_pruned.fa.chan)
%     > [ 1         2         1  ...  2         1         2 ]@1x14
%     cosmo_disp(ds_pruned.fa.time)
%     > [ 1         1         2  ...  6         7         7 ]@1x14
%
% Notes
%  - when haystack or needle are numeric vectors or cells of strings,
%    then this function behaves like cosmo_match (and does not consider
%    information in its first input argument ds).
%  - to remove dimension elements not included in the mask, use
%    cosmo_dim_prune. When the dataset is transformed back using
%    cosmo_map2{meeg,fmri,surface} it will not have these elements.
%    The only real use case is in MEEG datasets to remove time, channel, or
%    frequency elements; for fmri or surface datasets it is a bad idea to
%    use cosmo_dim_prune.
%
% See also: cosmo_match, cosmo_dim_prune
%
% NNO Oct 2013
    if ~isstruct(ds)
        error('expected a struct as input');
    end

    if ~isfield(ds,'neighbors')
        cosmo_check_dataset(ds);
    end

    dim=[];
    has_dim=nargin>3 && mod(nargin,2)==0;
    if has_dim
        dim=varargin{end};
        if ~isnumeric(dim) || (dim~=1 && dim~=2)
            error(['odd number of arguments; last (dim) argument '...
                    'must be 1 or 2']);
        end
    end

    if ischar(dim_label)
        [dim_label, dim_values]=match_single_dim(ds, dim_label, ...
                                                    dim_values, dim);
    end

    msk=cosmo_match(dim_label, dim_values);

    if nargin>3
        me=str2func(mfilename());
        msk_other=me(ds, varargin{:});

        if ~isequal(size(msk),size(msk_other))
            error('Mask size mismatch: %d x %d ~= %d x %d', ...
                    size(msk),size(msk_other))
        end

        % conjunction mask
        msk=msk & msk_other;
    end


function [dim_label, dim_values]=match_single_dim(ds, dim_label, ...
                                                            dim_values, dim)
    has_dim=~isempty(dim);

    % get value for needle and haystack
    [dim_, index, attr_name, dim_name]=cosmo_dim_find(ds, ...
                                                dim_label, true);
    if has_dim && dim_~=dim
        error('dim specified as %d, but found %s in dim %d',...
                dim, dim_label, dim_);
    else
        dim=dim_;
    end

    vs=ds.a.(dim_name).values{index};
    if isa(dim_values,'function_handle')
        if isnumeric(vs)
            match_mask=dim_values(vs);
        else
            match_mask=cellfun(dim_values,vs,'UniformOutput',true);
        end
    else
        match_mask=cosmo_match(vs,dim_values);
    end

    % set new value based on indices of the matching mask
    dim_values=find(match_mask);
    dim_label=ds.(attr_name).(ds.a.(dim_name).labels{index});

