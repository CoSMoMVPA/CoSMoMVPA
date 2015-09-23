function chunks=cosmo_chunkize(ds,nchunks)
% assigns chunks that are as balanced as possible based on targets.
%
% chunks=cosmo_chunkize(ds_targets,nchunks)
%
% Inputs:
%   ds             A dataset struct with fields:
%    .sa.targets   Px1 targets with class labels for P samples
%    .sa.chunks    Px1 initial chunks for P samples; different values mean
%                  that the corresponding data can be assumed to be
%                  independent
%   nchunks        scalar indicating how many different chunks should be
%                  assigned.
%
% Output:
%   chunks         Px1 chunks assigned, in the range 1:nchunks. It is
%                  required that N=numel(unique(ds.sa.targets)) is greater
%                  than or equal to nchunks.
%
%
% Example:
%     % ds is an MEEG dataset with 48 samples
%     ds=cosmo_synthetic_dataset('type','timelock','nreps',8);
%     %
%     % with no chunks set, this function gives an error
%     ds.sa=rmfield(ds.sa,'chunks');
%     cosmo_chunkize(ds)
%     > error('dataset has no field .sa.chunks. ...');
%     %
%     % set chunks so that all samples are assumed to be independent
%     ds.sa.chunks=(1:size(ds.samples,1))';
%     %
%     % show initial dataset targets and chunks
%     cosmo_disp([ds.sa.targets ds.sa.chunks])
%     > [ 1         1
%     >   2         2
%     >   1         3
%     >   :         :
%     >   2        46
%     >   1        47
%     >   2        48 ]@48x2
%     %
%     % Re-assign chunks pseudo-randomly in the range 1:4.
%     % samples (rows) with the same chunk original chunk value
%     % will still have the same chunk value (but the reverse is not
%     % necessarily true)
%     ds.sa.chunks=cosmo_chunkize(ds,4);
%     %
%     % sanity check
%     cosmo_check_dataset(ds);
%     % Show result
%     cosmo_disp([ds.sa.targets ds.sa.chunks])
%     > [ 1         1
%     >   2         2
%     >   1         3
%     >   :         :
%     >   2         2
%     >   1         3
%     >   2         4 ]@48x2
%
% Notes:
%  - This function is indended for MEEG datasets, or other datasets
%    where each trial can be assumed to be 'independant' of other trials.
%  - To indicate independence between all trials in a dataset ds, use:
%      ds.sa.chunks=(1:size(ds.samples,1))';
%    prior to using this function
%  - When this function is used prior to classification using partitioning
%    (with cosmo_nchoosek_partitioner or cosmo_nfold_paritioner),
%    it is recommended to apply cosmo_balance_partitions to
%    that partitioning
%  - Usage for fMRI datasets is not recommended, unless you really know
%    what you are doing. Rather, for fMRI datasets usually the chunks are
%    assigned manually so that each run has a different chunk value.
%
% NNO Oct 2013

    check_input(ds);

    nsamples=size(ds.samples,1);

    [idxs_ct,unq_ct]=cosmo_index_unique(...
                                        [ds.sa.chunks ds.sa.targets]);

    [idxs_c,unq_c]=cosmo_index_unique(unq_ct(:,1));
    [unused,unq_t]=cosmo_index_unique(unq_ct(:,2));

    nunq_c=numel(unq_c);
    nunq_t=numel(unq_t);
    nunq_ct=size(unq_ct,1);

    if nunq_c*nunq_t<nunq_ct
        error(['Balance mismatch: there are %d unique chunks and '...
                '%d unique targets, but the number of unique '...
                'combinations is more than that, only %d'],...
                nunq_c,nunq_t,nunq_ct);
    end

    if nchunks>nunq_c
        error('Cannot make %d chunks, only %d are present',...
                    nchunks,nunq_c);
    end

    chunks=zeros(nsamples,1);

    for k=1:nunq_c
        rows=cat(1,idxs_ct{idxs_c{k}});
        chunks(rows)=mod(k-1,nchunks)+1;
    end


function check_input(ds)
    cosmo_check_dataset(ds);

    if ~cosmo_isfield(ds,'sa.chunks')
        error(['dataset has no field .sa.chunks. The chunks are '...
               'required for this function; they should indicate (in)'...
               '-dependence between trials, so that samples with '...
               'different chunk values can be assumed independent.\n'...
               'If you do not know how to set the .sa.chunks, consider '...
               'the following:\n'...
               '- for an fmri dataset, each samples'' '...
               '  chunk can be set to its run number\n'...
               '- for an meeg dataset, if each trial can be assumed '...
               'to be independent, the chunks can be set to (1:N),'...
               'where N is the number of samples'...
               '(i.e. N=size(ds.samples,1) for a dataset struct ds']);
    end

    if ~cosmo_isfield(ds,'sa.targets')
        error(['dataset has not fields .sa.targets; this is required '...
                'to balance it. Normally, .sa.targets should indicate '...
                'the condition of interest, so that samples with '...
                'different target values are in different conditions. '...
                'If all samples are in the same condition, then '...
                '.sa.targets can be a column vector with ones']);
    end


