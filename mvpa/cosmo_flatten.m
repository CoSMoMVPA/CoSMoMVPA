function ds=cosmo_flatten(arr, dim_labels, dim_values, dim)
% flattens an arbitrary array to a dataset structure
%
% ds=cosmo_flatten(arr, dim_labels, dim_values)
%
% Inputs:
%   arr                S_1 x ... x S_K x Q input array if (dim==1), or
%                      P x S_1 x ... x S_K input array if (dim==2)
%   dim_labels         1xK cell containing labels for each dimension but
%                      the first one.
%   dim_values         1xK cell with S_J values (J in 1:K) corresponding to
%                      the labels in each of the K dimensions.
%   dim                dimension along which to flatten, either 1 (samples)
%                      or 2 (features; default)
% Output:
%   ds                 dataset structure, with fields:
%      .samples        PxQ data for P samples and Q features.
%      .a.dim.labels   1xK cell with the values in dim_labels
%      .a.dim.values   1xK cell with the values in dim_values.
%      .fa.(label)     for each label in a.dim.labels it contains the
%      .samples        PxQ data for P samples and Q features, where
%                      Q=prod(S_*) if dim==1 and P=prod(S_*) if dim==2
%      .a.Xdim.labels  1xK cell with the values in dim_labels (X=='s' if
%                      dim==1, and 'f' if dim==2); the M-th element must
%                      have S_M values.
%      .a.Xdim.values  1xK cell with the values in dim_values; the M-th
%                      element must have S_M values.
%      .Xa.(label)     for each label in a.Xdim.labels it contains the
%                      sub-indices for the K dimensions. It is ensured
%                      that for every dimension J in 1:K, all values in
%                      ds.fa.(a.dim.labels{J}) are in the range 1:S_K.
%
% Examples:
%     % typical usage: flatten features in 2x3x5 array, 1 sample
%     data=reshape(1:30, [1 2,3,5]);
%     ds=cosmo_flatten(data,{'i','j','k'},{1:2,1:3,{'a','b','c','d','e'}});
%     cosmo_disp(ds)
%     > .samples
%     >   [ 1         2         3  ...  28        29        30 ]@1x30
%     > .fa
%     >   .i
%     >     [ 1 2 1  ...  2 1 2 ]@1x30
%     >   .j
%     >     [ 1 1 2  ...  2 3 3 ]@1x30
%     >   .k
%     >     [ 1 1 1  ...  5 5 5 ]@1x30
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'i'  'j'  'k' }
%     >     .values
%     >       { [ 1 2 ]  [ 1 2 3 ]  { 'a'  'b'  'c'  'd'  'e' } }
%
%     % flatten samples in 1x1x2x3 array, 5 features
%     data=reshape(1:30, [1,1,2,3,5]);
%     ds=cosmo_flatten(data,{'i','j','k','m'},{1,'a',1:2,1:3},1);
%     cosmo_disp(ds);
%     > .samples
%     >   [ 1         7        13        19        25
%     >     2         8        14        20        26
%     >     3         9        15        21        27
%     >     4        10        16        22        28
%     >     5        11        17        23        29
%     >     6        12        18        24        30 ]
%     > .sa
%     >   .i
%     >     [ 1 1 1 1 1 1 ]
%     >   .j
%     >     [ 1 1 1 1 1 1 ]
%     >   .k
%     >     [ 1 2 1 2 1 2 ]
%     >   .m
%     >     [ 1 1 2 2 3 3 ]
%     > .a
%     >   .sdim
%     >     .labels
%     >       { 'i'  'j'  'k'  'm' }
%     >     .values
%     >       { [ 1 ]  'a'  [ 1 2 ]  [ 1 2 3 ] }
%     >
%
%
% Notes:
%   - Intended use is for flattening fMRI or MEEG datasets
%   - This function is the inverse of cosmo_unflatten.
%
% See also: cosmo_unflatten, cosmo_fmri_dataset, cosmo_meeg_dataset
%
% NNO Sep 2013

    if nargin<4, dim=2; end

    switch dim
        case 1
            transpose=true;
            attr_name='sa';
            dim_name='sdim';
        case 2
            transpose=false;
            attr_name='fa';
            dim_name='fdim';
        otherwise
            error('illegal dim: must be 1 or 2');
    end

    if transpose
        % switch samples and features
        ndim=numel(dim_labels);
        arr=shiftdim(arr,ndim);
    end

    [samples,attr]=flatten_features(arr, dim_labels, dim_values);

    if transpose
        samples=samples';
    end

    ds=struct();
    ds.samples=samples;
    ds.(attr_name)=attr;
    ds.a.(dim_name).labels=dim_labels;
    ds.a.(dim_name).values=dim_values;


function [samples, attr]=flatten_features(arr, dim_labels, dim_values)
    % helper function to flatten features

    ndim=numel(dim_labels);
    if ndim ~= numel(dim_values)
        error('expected %d dimensions, found %d',ndim,numel(dim_values));
    elseif numel(size(arr))>(ndim+1)
        error('Array has %d dimensions, expected <= %d',...
                                        numel(size(arr)),ndim+1);
    end


    % allocate space for output
    attr=struct();

    % number of values in remaining dimensions
    % (supports the case that arr is of size [...,1]
    dim_sizes=cellfun(@numel,dim_values);

    for dim=1:ndim
        if dim_sizes(dim) ~= size(arr,dim+1)
            error('Array has %d values on dimension %d, expected %d',...
                    size(arr,dim+1), dim+1, dim_sizes(dim));
        end

        % set values for dim-th dimension
        dim_name=dim_labels{dim};

        values=dim_values{dim};
        nvalues=numel(values);

        % set the indices
        indices=1:nvalues;

        % make an array lin_values that has size 1 in every dimension
        % except for the 'dim'-th one, where it has size 'nvalues'.
        singleton_size=ones(1,ndim);
        singleton_size(dim)=nvalues;
        if ndim==1
            % reshape only works with >=2 dimensions
            lin_values=indices;
        else
            lin_values=reshape(indices,singleton_size);
        end

        % now the lin_values have to be tiled (using repmat). The number of
        % repeats is 'dim_sizes'('k') for all 'k' except for 'dim',
        % where it is 1 (as it has 'nvalues' in that dimension already).
        rep_size=dim_sizes;
        rep_size(dim)=1;

        rep_values=repmat(lin_values, rep_size);

        % store indices as a row vector.
        attr.(dim_name)=reshape(rep_values, 1, []);
    end

    % get array and sample sizes
    nsamples=size(arr,1);
    nfeatures=prod(dim_sizes);

    samples=reshape(arr, nsamples, nfeatures);



