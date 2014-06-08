function ds=cosmo_flatten(arr, dim_labels, dim_values)
% flattens an arbitrary array to a dataset structure
%
% ds=cosmo_flatten(arr, dim_labels, dim_values)
%
% Inputs:
%   arr                input data array of size P x S_1 x ... x S_K, for P
%                      samples and prod(S_*) features.
%   dim_labels         1xK cell containing labels for each dimension but
%                      the first one.
%   dim_values         1xK cell with S_J values (J in 1:K) corresponding to
%                      the labels in each of the K dimensions.
% Output:
%   ds                 dataset structure, with fields:
%      .samples        PxQ data for P samples and Q features.
%      .a.dim.labels   1xK cell with the values in dim_labels
%      .a.dim.values   1xK cell with the values in dim_values. 
%      .fa.(label)     for each label in a.dim.labels it contains the
%                      sub-indices for the K dimensions. It is ensured
%                      that for every dimension J in 1:K, all values in
%                      ds.fa.(a.dim.labels{J}) are in the range 1:S_K.
%
% Notes:
%   - Intended use is for flattening fMRI or MEEG datasets
%   - This function is the inverse of cosmo_unflatten.
%
% See also: cosmo_unflatten, cosmo_fmri_dataset, cosmo_meeg_dataset
%
% NNO Sep 2013

ndim=numel(dim_labels);
if ndim ~= numel(dim_values), error('expected %d dimensions', ndim); end

% get array and sample sizes
arr_size=size(arr);
nsamples=arr_size(1);

% number of values in remaining dimensions
dim_sizes=arr_size(2:end);
nfeatures=prod(dim_sizes);

% sanity check
if numel(dim_sizes) ~= ndim
    error('expected %d feature dimensions, found %d', ...
                    ndim, numel(dim_sizes));
end

% allocate space for output
fa=struct();
for dim=1:ndim
    % set values for dim-th dimension
    dim_name=dim_labels{dim};

    values=dim_values{dim};
    nvalues=numel(values);
    
    % another sanity check
    if nvalues ~= dim_sizes(dim)
        error('expected %d values in dimension %d, found %d',...
                    nvalues, dim, dim_sizes(dim));
    end
    
    % set the indices
    indices=1:nvalues;

    % make an array lin_values that has size 1 in every dimension
    % except for the 'dim'-th one, where it has size 'nvalues'.
    singleton_size=ones(1,ndim);
    singleton_size(dim)=nvalues;
    lin_values=reshape(indices,singleton_size);

    % now the lin_values have to be tiled (using repmat). The number of
    % repeats is 'dim_sizes'('k') for all 'k' except for 'dim', where it is
    % 1 (as it has 'nvalues' in that dimension already).
    rep_size=dim_sizes;
    rep_size(dim)=1;

    rep_values=repmat(lin_values, rep_size);

    % store indices as a row vector.
    fa.(dim_name)=reshape(rep_values, 1, []);
end

% store results
ds.samples=reshape(arr, nsamples, nfeatures);
ds.a.dim.labels=dim_labels;
ds.a.dim.values=dim_values;
ds.fa=fa;

    
    
    
