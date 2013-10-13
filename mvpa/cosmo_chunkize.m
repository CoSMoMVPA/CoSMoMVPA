function chunks=cosmo_chunkize(targets,nchunks)
% assigns chunks that are as balanced as possible based on targets.
% in most cases this should only be used for MEEG datasets.
%
% chunks=cosmo_chunkize(targets,nchunks)
%
% Inputs:
%   targets        Px1 vector with class labels, for P samples.
%                  It can also be a dataset struct with field .sa.targets
%   nchunks        scalar indicating how many chunks should be returned
% 
% Output:
%   chunks         Px1 chunk labels, all in the range 1:nchunks. For each 
%                  target value in 'targets', the number of samples 
%                  associated with each chunk is as balanced as possible
%                  (i.e., does not differ by more than one).
%                  If the input was a dataset struct, then the output is
%                  the same dataset struct but with the field .sa.chunks
%                  set.
%
% Note:
%  - This function should only be used for MEEG datasets, or other datasets
%    where each trial can be assumed to be 'independant' of other trials.
%    Usage for fMRI datasets is not recommended, unless you really know
%    what you are doing.
%
% NNO Oct 2013

is_ds=isstruct(targets);
if is_ds
    ds=targets;
    cosmo_check_dataset(ds);
    if ~isfield(ds,'sa') || ~isfield(ds.sa,'targets')
        error('Missing field .sa.targets');
    end
    targets=ds.sa.targets;
end

unq=unique(targets);
nclasses=numel(unq);

nsamples=numel(targets);
chunks=zeros(nsamples,1);

for k=1:nclasses
    target=unq(k);
    msk=target==targets;
    
    n=sum(msk);
    chunks(msk)=mod((1:n)-1,nchunks)+1;
end

if is_ds
    % return a dataset
    ds.sa.chunks=chunks;
    chunks=ds;
end