function ds_avg=cosmo_average_samples(ds, varargin)
% average subsets of samples by unique combinations of chunks and targets
%
% ds_avg=cosmo_averaging_measure(ds, 'ratio', ratio, ['nrep',nrep])
%
% Inputs:
%   ds              dataset struct with field:
%     .samples      NS x NF
%     .sa           with fields .targets and .chunks
%   'ratio', ratio  ratio (between 0 and 1) of samples to select for
%                   each average. If >=1 then it indicates how many samples
%                   to select for each average.
%   'nrep', nrep    number of repeated sampling operations for each
%                   combination of targets and chunks (default: 1).
%
% Returns
%   ds_avg          dataset struct with field:
%      .samples     ('nrep'*ntargets*nchunks) x NF, where
%                   ntargets and nchunks are the number of unique targets
%                   and chunks, respectively. Each sample is an average
%                   from samples that share the same values for
%                   .sa.{chunks,targets}. The number of times each sample
%                   is used to compute average values differs by one at
%                   most.
%      .sa          Based on averaged samples.
%      .fa,.a       Same as in ds (if present).
%
% Examples:
%     % generate simple dataset with 3 times (2 targets x 3 chunks)
%     ds=cosmo_synthetic_dataset('nreps',3);
%     size(ds.samples)
%     > [ 18 6 ]
%     cosmo_disp([ds.sa.targets ds.sa.chunks])
%     > [ 1         1
%     >   2         1
%     >   1         2
%     >   :         :
%     >   2         2
%     >   1         3
%     >   2         3 ]@18x2
%     %
%     % for each unique target-chunk combination, select 60% of the samples
%     % randomly and average these. The output has 6 samples.
%     ds_avg=cosmo_average_samples(ds,'ratio',.6);
%     cosmo_disp([ds_avg.sa.targets ds_avg.sa.chunks]);
%     > [ 1         1
%     >   1         2
%     >   1         3
%     >   2         1
%     >   2         2
%     >   2         3 ]
%     % for each unique target-chunk combination, select 50% of the samples
%     % randomly and average these; repeat the random selection process 4
%     % times. Each sample in 'ds' is used twice (=.5*4) as an element
%     % to compute an average. The output has 24 samples
%     ds_avg2=cosmo_average_samples(ds,'ratio',.5,'nrep',4);
%     cosmo_disp([ds_avg2.sa.targets ds_avg2.sa.chunks]);
%     > [ 1         1
%     >   1         2
%     >   1         3
%     >   :         :
%     >   2         1
%     >   2         2
%     >   2         3 ]@24x2
%
% Notes:
%  - this function averages feature-wise; the output has the same features
%    as the input.
%  - it can be used to average data from trials safely without circular
%    analysis issues.
%  - as a result the number of trials in each chunk and target is
%    identical, so balancing of partitions is not necessary for data from
%    this function.
%
% See also: cosmo_balance_partitions
%
% NNO Jan 2014

    % deal with input parameters
    defaults.nrep=1;
    defaults.seed=[];

    params=cosmo_structjoin(defaults, varargin);
    if ~isfield(params,'ratio'), error('Need argument ''ratio'''); end

    ratio=params.ratio;
    nrep=params.nrep;
    averager=@(x)mean(x,1); % to average samples

    % split by unique target-chunk combinations
    ds_splits=cosmo_split(ds,{'targets','chunks'});

    % allocate space for output
    nsplits=numel(ds_splits);
    res=cell(nsplits,nrep);

    for k=1:nsplits
        ds_split=ds_splits{k};
        n=size(ds_split.samples,1);

        if ratio<1
            % specified ratio
            nselect=round(n*ratio);
        else
            nselect=ratio;
        end

        % check validity of ratio
        if nselect==0
            error('split %d - select zero samples?', k);
        elseif nselect>n
            error('split %d - only %d < %d samples', k, n, nselect);
        end

        % generate 'nset' random permutations of 1:n and concatenate these.
        % this ensures that the numbers of times specific samples are
        % selected differ by 1 at most.

        rp=repeated_randperm(n,nrep,params.seed);

        % select random indices
        for j=1:nrep
            rp_idxs=(j-1)*nselect+(1:nselect);
            idxs=rp(rp_idxs);
            ds_split_sel=cosmo_slice(ds_split,idxs);
            res{k,j}=cosmo_fx(ds_split_sel,averager,[]);
        end
    end

    % join results
    ds_avg=cosmo_stack(res);


function rp=repeated_randperm(nelem,nrep,seed)
    n=nelem*nrep;
    if isempty(seed)
        rp_elems=cosmo_rand(1,n);
    else
        rp_elems=cosmo_rand(1,n,'seed',seed);
    end

    rp=zeros(1,n);
    for k=1:nrep
        idxs=(k-1)*nelem+(1:nelem);
        rp_elem=rp_elems(idxs);
        [foo,i]=sort(rp_elem);
        rp(idxs)=i;
    end






