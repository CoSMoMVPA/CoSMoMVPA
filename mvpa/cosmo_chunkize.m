function ds_chunks=cosmo_chunkize(ds_targets,nchunks)
% assigns chunks that are as balanced as possible based on targets.
% in most cases this should only be used for MEEG datasets.
%
% ds_chunks=cosmo_chunkize(ds_targets,nchunks)
%
% Inputs:
%   ds_targets     A dataset struct with Px1 numeric field .sa.targets
%                  indicating the class labels for P samples.
%                  Alternatively it can be an Px1 vector with class labels.
%   nchunks        scalar indicating how many different chunks should be
%                  assigned.
%
% Output:
%   ds_chunks      If the input was a dataset struct, then the output is
%                  the same dataset struct but with the field .sa.chunks
%                  set to a Px1 vector with chunk labels, all in the range
%                  1:nchunks. If the input was a vector, then the output is
%                  a vector as well with these values.
%                  For each target value in 'targets', the number of
%                  samples  associated with each chunk is as balanced as
%                  possible (i.e., does not differ by more than one).
%
%
% Note:
%  - This function should only be used for MEEG datasets, or other datasets
%    where each trial can be assumed to be 'independant' of other trials.
%  - When this function is used prior to classification using partitioning
%    (with cosmo_nchoosek_partitioner or cosmo_nfold_paritioner),
%    it is recommended to apply cosmo_balance_partitions to
%    that partitioning
%  - Usage for fMRI datasets is not recommended, unless you really know
%    what you are doing. Rather, for fMRI datasets usually the chunks are
%    assigned manually so that each run has a different chunk value.
%
%
% Example:
%  - % ds is a dataset struct with field .sa.targets (class labels of each
%    % sample). Assign chunks randomly in the range 1:5.
%  >> ds=cosmo_chunkize(ds, 5);
%
%
% NNO Oct 2013

is_ds=isstruct(ds_targets);
if is_ds
    ds=ds_targets;
    cosmo_check_dataset(ds);
    if ~isfield(ds,'sa') || ~isfield(ds.sa,'targets')
        error('Missing field .sa.targets');
    end
    ds_targets=ds.sa.targets;
end

unq=unique(ds_targets);
nclasses=numel(unq);

nsamples=numel(ds_targets);
ds_chunks=zeros(nsamples,1);

for k=1:nclasses
    target=unq(k);
    msk=target==ds_targets;

    n=sum(msk);
    ds_chunks(msk)=mod((1:n)-1,nchunks)+1;
end

if is_ds
    % return a dataset
    ds.sa.chunks=ds_chunks;
    ds_chunks=ds;
end
