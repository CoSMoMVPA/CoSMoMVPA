function [arr, dim_labels]=cosmo_unflatten(ds)
% unflattens a dataset from 2 to (1+K) dimensions.
%
% [arr, dim_labels]=cosmo_unflatten(ds[, set_missing_to])
%
% Inputs:
%   ds                 dataset structure, with fields:
%      .samples        PxQ for P samples and Q features.
%      .a.dim.labels   1xK cell with string labels for each dimension.
%      .a.dim.values   1xK cell, with S_J values (J in 1:K) corresponding
%                      to the labels in each of the K dimensions.
%      .fa.(label)     for each label in a.dim.labels it contains the
%                      sub-indices for the K dimensions. It is required
%                      that for every dimension J in 1:K, all values in
%                      ds.fa.(a.dim.labels{J}) are in the range 1:S_K.
%   set_missing_to     value to set missing values to (default: 0)
%
% Returns:
%   arr                an unflattened array of size P x S_1 x ... x S_K.
%   dim_labels         the value of .a.dim.labels, provided for
%                      convenience.
%
% Notes:
%   - A typical use case is mapping an fMRI or MEEG dataset struct
%     back to a 3D or 4D array.
%   - This function is the inverse of cosmo_flatten.
%
% See also: cosmo_flatten, cosmo_map2fmri, cosmo_map2meeg
%
% NNO Sep 2013

nsamples=size(ds.samples,1);
dim_labels=ds.a.dim.labels;
dim_values=ds.a.dim.values;

% number of feature dimensions
ndim=numel(dim_labels);

% number of elements in each dimension
dim_sizes=zeros(1,ndim);

% space for indices in each dimension
sub_indices=cell(1,ndim);

% go over dimensions
for k=1:ndim
    dim_sizes(k)=numel(dim_values{k});
    sub_indices{k}=ds.fa.(dim_labels{k});
end

% allocate space for output - one cell per sample
arr_cell=cell(1,nsamples);

% convert sub indices to linear indices
if ndim==1
    lin_indices=sub_indices{1};
else
    lin_indices=sub2ind(dim_sizes,sub_indices{:});
end

% allocate space in 'ndim'-space for each sample,
% but with a first singleton dimension as that one
% is used for the samples
arr_dim=zeros([1, dim_sizes]);

% process each sample
for k=1:nsamples
    % make empty
    arr_dim(:)=0;

    % assign to proper location
    arr_dim(lin_indices)=ds.samples(k, :);

    % store result for this sample
    arr_cell{k}=arr_dim;
end

% combine all samples
arr=cat(1, arr_cell{:});
