function ds=cosmo_flatten(arr, dim_labels, dim_values, dim, varargin)
% flattens an arbitrary array to a dataset structure
%
% ds=cosmo_flatten(arr, dim_labels, dim_values, dim[, ...])
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
%   'matrix_labels',m  Allow labels in the cell string m to be matrices
%                      rather than vectors. Currently the only use case is
%                      the 'pos' attribute for MEEG source space data.
%
% Output:
%   ds                 dataset structure, with fields:
%      .samples        PxQ data for P samples and Q features.
%      .a.dim.labels   Kx1 cell with the values in dim_labels
%      .a.dim.values   Kx1 cell with the values in dim_values. The i-th
%                      element has S_i elements along dimension dim
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
%     ds=cosmo_flatten(data,{'i','j','k','m'},{1,'a',(1:2)',(1:3)'},1);
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
%     >     [ 1
%     >       1
%     >       1
%     >       1
%     >       1
%     >       1 ]
%     >   .j
%     >     [ 1
%     >       1
%     >       1
%     >       1
%     >       1
%     >       1 ]
%     >   .k
%     >     [ 1
%     >       2
%     >       1
%     >       2
%     >       1
%     >       2 ]
%     >   .m
%     >     [ 1
%     >       1
%     >       2
%     >       2
%     >       3
%     >       3 ]
%     > .a
%     >   .sdim
%     >     .labels
%     >       { 'i'  'j'  'k'  'm' }
%     >     .values
%     >       { [ 1 ]  'a'  [ 1    [ 1
%     >                       2 ]    2
%     >                              3 ] }
%
%
% Notes:
%   - Intended use is for flattening fMRI or MEEG datasets
%   - This function is the inverse of cosmo_unflatten.
%
% See also: cosmo_unflatten, cosmo_fmri_dataset, cosmo_meeg_dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults.matrix_labels=cell(0);
    opt=cosmo_structjoin(defaults,varargin{:});

    if nargin<4, dim=2; end

    switch dim
        case 1
            do_transpose=true;
            attr_name='sa';
            dim_name='sdim';
        case 2
            do_transpose=false;
            attr_name='fa';
            dim_name='fdim';
        otherwise
            error('illegal dim: must be 1 or 2');
    end

    if do_transpose
        % switch samples and features
        ndim=numel(dim_labels);
        nfeatures=size(arr,ndim+1);
        if nfeatures==1
            arr=reshape(arr,[1 size(arr)]);
        else
            arr=shiftdim(arr,ndim);
        end
        dim_values=cellfun(@transpose,dim_values,'UniformOutput',false);
    end

    [samples,dim_values,attr]=flatten_features(arr, dim_labels, ...
                                            dim_values, opt);

    if do_transpose
        samples=samples';
        attr=transpose_attr(attr);
        dim_values=cellfun(@transpose,dim_values,'UniformOutput',false);
    end

    ds=struct();
    ds.samples=samples;
    ds.(attr_name)=attr;
    ds.a.(dim_name).labels=dim_labels;
    ds.a.(dim_name).values=dim_values;

function attr=transpose_attr(attr)
    keys=fieldnames(attr);
    for k=1:numel(keys)
        key=keys{k};
        value=attr.(key);
        attr.(key)=value';
    end

function [samples,dim_values,attr]=flatten_features(arr, dim_labels, ...
                                                        dim_values, opt)
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
    [dim_sizes,dim_values]=get_dim_sizes(arr,dim_labels,dim_values,opt);

    for dim=1:ndim
        % set values for dim-th dimension
        dim_label=dim_labels{dim};
        dim_value=dim_values{dim};

        nvalues=size(dim_value,2);

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

        rep_values=repmat(lin_values, rep_size(:)');

        % store indices as a row vector.
        attr.(dim_label)=reshape(rep_values, 1, []);
    end

    % get array and sample sizes
    nsamples=size(arr,1);
    nfeatures=prod(dim_sizes);

    samples=reshape(arr, nsamples, nfeatures);


function [dim_sizes, dim_values]=get_dim_sizes(arr,dim_labels,dim_values,opt)
    ndim=numel(dim_values);
    dim_sizes=zeros(1,ndim);

    for dim=1:ndim
        dim_label=dim_labels{dim};
        dim_value=dim_values{dim};

        if cosmo_match({dim_label},opt.matrix_labels)
            dim_size=size(dim_value,2);
        else
            if ~isvector(dim_value)
                error(['Label ''%s'' (dimension %d) must be a vector, '...
                        'because it was not specified as a matrix '...
                        'dimension in the ''matrix_fields'' option'],...
                        dim_label, dim);
            end
            dim_size=numel(dim_value);
            dim_values{dim}=dim_value(:)'; % make it a row vector
        end


        if dim_size ~= size(arr,dim+1)
            error(['Label ''%s'' (dimension %d) has %d values, ',...
                        'expected %d based on the array input'],...
                    dim_label, dim, dim_size, size(arr,dim+1));
        end

        dim_sizes(dim)=dim_size;
    end

