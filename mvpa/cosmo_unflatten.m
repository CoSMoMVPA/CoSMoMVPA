function [arr, dim_labels, dim_values]=cosmo_unflatten(ds, dim, varargin)
% unflattens a dataset from 2 to (1+K) dimensions.
%
% [arr, dim_labels]=cosmo_unflatten(ds, [dim, ][,...])
%
% Inputs:
%   ds                 dataset structure, with fields:
%      .samples        PxQ for P samples and Q features.
%      .a.Xdim.labels  1xK cell with string labels for each dimension,
%                      with X='s' for samples (dim=1) or X='f' for features
%                      (dim=2).
%      .a.Xdim.values  1xK cell, with S_J values (J in 1:K) corresponding
%                      to the labels in each of the K dimensions.
%      .Xa.(label)     for each label in a.Xdim.labels it contains the
%                      sub-indices for the K dimensions. It is required
%                      that for every dimension J in 1:K, all values in
%                      ds.fa.(a.fdim.labels{J}) are in the range 1:S_K, and
%                      that every combination across labels is unique.
%   dim                dimension to be unflattened, either 1 (for samples)
%                      or 2 (for features; default)
%   'set_missing_to',s value to set missing values to (default: 0)
%   'matrix_labels',m  Allow labels in the cell string m to be matrices
%                      rather than vectors. Currently the only use case is
%                      the 'pos' attribute for MEEG source space data.
%
% Returns:
%   arr                S_1 x ... x S_K x Q array if (dim==1), or
%                      P x S_1 x ... x S_K array if (dim==2), where
%                      Q=prod(S_*) if dim==1 and P=prod(S_*) if dim==2
%   dim_labels         the value of .a.Xdim.labels
%   dim_values         the value of .a.Xdim.values
%
% Example:
%     % ds is an FMRI dataset with 6 samples, volumes are 3 x 2 x 5 voxels
%     ds=cosmo_synthetic_dataset('size','normal','type','fmri');
%     size(ds.samples)
%     > [ 6 30 ]
%     cosmo_disp(ds.a.fdim)
%     > .labels
%     >   { 'i'  'j'  'k' }
%     > .values
%     >   { [ 1 2 3 ]  [ 1 2 ]  [ 1 2 3 4 5 ] }
%     %
%     % flatten the dataset
%     [unfl,labels,values]=cosmo_unflatten(ds);
%     %
%     % the unflattened dataset is of size 6 x 3 x 2 x 5
%     size(unfl)
%     > [ 6 3 2 5 ]
%     cosmo_disp(labels)
%     > { 'i'  'j'  'k' }
%     cosmo_disp(values)
%     > { [ 1 2 3 ]  [ 1 2 ]  [ 1 2 3 4 5 ] }
%
%     % ds is a small dataset with 2 classes
%     ds=cosmo_synthetic_dataset();
%     %
%     % compute all (2x2) split-half correlation values
%     res=cosmo_correlation_measure(ds,'output','raw');
%     cosmo_disp(res)
%     > .samples
%     >   [  0.447
%     >     -0.538
%     >     -0.525
%     >      0.959 ]
%     > .sa
%     >   .half1
%     >     [ 1
%     >       2
%     >       1
%     >       2 ]
%     >   .half2
%     >     [ 1
%     >       1
%     >       2
%     >       2 ]
%     > .a
%     >   .sdim
%     >     .labels
%     >       { 'half1'  'half2' }
%     >     .values
%     >       { [ 1    [ 1
%     >           2 ]    2 ] }
%     %
%     % reshape the correlations into a square matrix
%     [unfl,labels,values]=cosmo_unflatten(res,1);
%     %
%     % yields a 2x2x1 matrix (matlab omits the last, singleton dimension)
%     cosmo_disp(unfl)
%     > [  0.447    -0.525
%     >   -0.538     0.959 ]
%     %
%     cosmo_disp(labels)
%     > { 'half1'  'half2' }
%     %
%     cosmo_disp(values)
%     > { [ 1    [ 1
%     >     2 ]    2 ] }
%
%
% Notes:
%   - A typical use case is mapping an fMRI or MEEG dataset struct
%     back to a 3D or 4D array.
%   - This function is the inverse of cosmo_flatten.
%
% See also: cosmo_flatten, cosmo_map2fmri, cosmo_map2meeg
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2 || isempty(dim), dim=2; end

    if ~(isnumeric(dim) && isscalar(dim))
        error('second argument must be numeric');
    end

    defaults=struct();
    defaults.set_missing_to=0;
    defaults.matrix_labels=cell(0);
    opt=cosmo_structjoin(defaults,varargin);

    switch dim
        case 1
            cosmo_isfield(ds,{'a.sdim','samples','sa'},true);
            do_transpose=true;
            a_dim=ds.a.sdim;
            attr=ds.sa;


        case 2
            cosmo_isfield(ds,{'a.fdim','samples','fa'},true);
            do_transpose=false;
            a_dim=ds.a.fdim;
            attr=ds.fa;

        otherwise
            error('dim must be 1 or 2');
    end

    samples=ds.samples;
    if do_transpose
        samples=samples';
        a_dim.values=cellfun(@transpose,a_dim.values,...
                                        'UniformOutput',false);
    end

    [arr, dim_labels,dim_values]=unflatten_features(samples, ...
                                        a_dim, attr, opt);

    if do_transpose
        arr=shiftdim(arr,1);
        dim_values=cellfun(@transpose,dim_values,'UniformOutput',false);
    end


function [arr, dim_labels, dim_values]=unflatten_features(samples, ...
                                        a_dim, attr, opt)
    nsamples=size(samples,1);
    dim_labels=a_dim.labels;
    dim_values=a_dim.values;

    % number of feature dimensions
    ndim=numel(dim_labels);

    % get sub indices for each feature dimension
    sub_indices=cellfun(@(x)attr.(x), dim_labels, 'UniformOutput', false);

    % get dimension values
    [dim_sizes, dim_values]=get_dim_sizes(dim_values, dim_labels, opt);

    max_indices=cellfun(@max,sub_indices);
    too_small_dim=find(max_indices(:)>dim_sizes(:),1);
    if ~isempty(too_small_dim)
        error(['dimension with label %s has %d dimension labels,'...
                'but attribute indexes up to %d'],...
                dim_labels{too_small_dim}, dim_sizes(too_small_dim),...
                max_indices(too_small_dim));
    end

    % allocate space for output - one cell per sample
    arr_cell=cell(1,nsamples);

    % convert sub indices to linear indices
    if ndim==1
        lin_indices=sub_indices{1};
    else
        lin_indices=sub2ind(dim_sizes,sub_indices{:});
    end

    unq_lin_indices=unique(lin_indices);

    if numel(lin_indices)~=numel(unq_lin_indices)
        h=histc(lin_indices,unq_lin_indices);
        duplicate=unq_lin_indices(find(h>1,1));
        duplicate_pos=find(lin_indices==duplicate,2);

        error('Duplicate features at #%d and #%d', duplicate_pos);
    end

    % allocate space in 'ndim'-space for each sample,
    % but with a first singleton dimension as that one
    % is used for the samples
    arr_dim=zeros([1, dim_sizes]);

    % process each sample
    for k=1:nsamples
        % make empty
        arr_dim(:)=opt.set_missing_to;

        % assign to proper location
        arr_dim(lin_indices)=samples(k, :);

        % store result for this sample
        arr_cell{k}=arr_dim;
    end

    % combine all samples
    arr=cat(1, arr_cell{:});


function [dim_sizes, dim_values]=get_dim_sizes(dim_values, dim_labels, opt)
    ndim=numel(dim_labels);
    if numel(dim_values)~=ndim
        error(['size mismatch between number of dimension values (%d)'...
                    'and dimension labels (%d)'],...
                    numel(dim_values), ndim);
    end
    % number of elements in each dimension
    dim_sizes=zeros(1,ndim);

    % go over dimensions
    for dim=1:ndim
        dim_label=dim_labels{dim};
        dim_value=dim_values{dim};
        if cosmo_match({dim_label},opt.matrix_labels)
            dim_size=size(dim_value,2);
        else
            if ~isvector(dim_value)
                error(['Label ''%s'' (dimension %d) must be a vector, '...
                        'because it was not specified as a matrix '...
                        'dimension in the ''matrix_labels'' option'],...
                        dim_label, dim);
            end
            dim_size=numel(dim_value);
            dim_values{dim}=dim_value(:)'; % make it a row vector
        end

        dim_sizes(dim)=dim_size;
    end


