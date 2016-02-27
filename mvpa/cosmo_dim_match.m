function msk=cosmo_dim_match(ds, varargin)
% return a mask indicating match of dataset dimensions with values
%
% msk=cosmo_match(ds, dim_label, dim_values1[...]
%
% Inputs:
%   ds                dataset struct or neighborhood struct
%   haystack*         numeric vector, or cell with strings, or string.
%                     A string is interpreted as the name of a feature
%                     dimension (e.g. 'i','j' or 'k' in fmri datasets;
%                     'chan', 'time', or 'freq' in MEEG datasets), and its
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
%                     finds the dimension in the dataset.
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
%     % no pruning, so the fdim.values are not changed. A subset of
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
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    [dim_labels, dim_values, expected_dim]=process_input(ds, varargin{:});

    ndim=numel(dim_labels);
    for k=1:ndim
        dim_label=dim_labels{k};
        dim_value=dim_values{k};
        [haystack, needle, found_dim]=match_single_dim(ds, dim_label, ...
                                                           dim_value);

        if ~isempty(expected_dim) && expected_dim~=found_dim
            error(['label ''%s'' was expected in dimension %d, '...
                                'was found in %d'],...
                            dim_label, expected_dim, found_dim);
        end

        dim_msk=cosmo_match(haystack, needle);

        if k==1
            msk_length=numel(haystack);
            assert_mask_of_proper_length(msk_length, ds, found_dim);

            msk=dim_msk;
        else
            if ~isequal(size(msk),size(dim_msk))
                error('size mismatch for dimension label ''%s''',...
                        dim_label);
            end
            msk=msk & dim_msk;
            expected_dim=found_dim;
        end
    end


function assert_mask_of_proper_length(msk_length, ds, dim)
    % since the calling function ensures the size is properly set,
    % the size should be fine; this function should never throw an error
    if isfield(ds,'neighbors')
        assert(numel(ds.neighbors)==msk_length);
    else
        assert(size(ds.samples,dim)==msk_length);
    end


function [dim_labels, dim_values, dim]=process_input(ds, varargin)
% get dimension labels and values
% if the number of arguments in varargin is odd, then the last element is
% the dimension along which dim_labels and dim_values are to be found;
% otherwise it is set to empty
    if ~isstruct(ds)
        error('first argument must be a struct');
    end

    is_neighborhood=isfield(ds,'neighbors');
    if is_neighborhood
        cosmo_check_neighborhood(ds);
    else
        cosmo_check_dataset(ds);
    end

    narg=numel(varargin);
    ndim=floor(narg/2);
    dim_labels=varargin(1:2:(ndim*2));
    dim_values=varargin(2:2:(ndim*2));
    for k=1:ndim
        dim_label=dim_labels{k};

        if ~ischar(dim_label)
            error('argument %d must be a string', k*2);
        end

        dim_value=dim_values{k};

        if ~isvector(dim_value)
            error('argument %d must be a vector', k*2+1);
        end

        if ~(ischar(dim_value) || ...
                    iscellstr(dim_value) || ...
                    isnumeric(dim_value) || ...
                    isa(dim_value,'function_handle'))
            error(['argument %d must be a string, cell string, '...
                        'numeric vector, or function handle']);
        end
    end

    if mod(narg,2)==1
        dim=varargin{end};
    else
        dim=[];
    end


function [haystack, needle, found_dim]=match_single_dim(ds, haystack, ...
                                                          needle)

    % get value for needle and haystack
    [found_dim, index, attr_name, dim_name]=cosmo_dim_find(ds, ...
                                                haystack, true);

    vs=ds.a.(dim_name).values{index};
    if isa(needle,'function_handle')
        match_mask=needle(vs);
    else
        match_mask=cosmo_match(vs,needle);
    end

    % set new value based on indices of the matching mask
    needle=find(match_mask);
    haystack=ds.(attr_name).(ds.a.(dim_name).labels{index});

