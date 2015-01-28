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
%                   each average. Not compatible with 'ratio'
%   'count', c      number of samples to select for each average.
%                   Not compatible with 'ratio'.
%   'repeats', r    number of repeated sampling operations for each
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
%     ds_avg2=cosmo_average_samples(ds,'ratio',.5,'repeats',4);
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

    opt=cosmo_structjoin(defaults, varargin);
    averager=@(x)mean(x,1); % to average samples

    % split by unique target-chunk combinations
    ds_splits=cosmo_split(ds,{'targets','chunks'});
    nsplits=numel(ds_splits);
    split_counts=cellfun(@(x)size(x.samples,1),ds_splits);

    split_sample_ids=get_split_sample_ids(split_counts,opt);
    nrepeat=size(split_sample_ids,2);
    assert(size(split_sample_ids,1)==nsplits);

    % allocate space for output

    res=cell(nsplits,nrepeat);

    for k=1:nsplits
        ds_split=ds_splits{k};

        for j=1:nrepeat
            sample_ids=split_sample_ids{k,j};
            ds_split_sel=cosmo_slice(ds_split,sample_ids);
            res{k,j}=cosmo_fx(ds_split_sel,averager,[]);
        end
    end

    % join results
    ds_avg=cosmo_stack(res);


function [nselect,nrepeat]=get_selection_params(split_counts,opt)
    if isfield(opt,'count') && ~isempty(opt.count)
        if isfield(opt,'ratio') && ~isempty(opt.ratio)
            error(['''count'' and ''ratio'' options are mutually '...
                        'exclusive']);
        end
        nselect=opt.count*ones(size(split_counts));
    elseif isfield(opt,'ratio') && ~isempty(opt.ratio)
        nselect=round(opt.ratio*split_counts);
    else
        nselect=split_counts;
    end

    wrong_nselect_mask=any(nselect<=0 | nselect>split_counts);
    if any(wrong_nselect_mask)
        wrong_pos=find(wrong_nselect_mask,1);
        error('cannot select %d samples, as only %d are present',...
                nselect(wrong_pos), split_counts(wrong_pos));
    end

    if isfield(opt,'repeats') && ~isempty(opt.repeats)
        nrepeat=opt.repeats;
    else
        nrepeat=1;
    end


function sample_ids=get_split_sample_ids(split_counts,opt)
    [nselect,nrepeat]=get_selection_params(split_counts,opt);

    nsplits=numel(split_counts);
    nsamples=sum(split_counts);

    if isfield(opt,'seed') && ~isempty(opt.seed)
        rp=cosmo_rand(nsamples, nrepeat, 'seed', opt.seed);
    else
        rp=cosmo_rand(nsamples, nrepeat);
    end

    sample_ids=cell(nsplits, nrepeat);

    row_first=1;

    for k=1:nsplits
        row_last=row_first+split_counts(k)-1;

        for r=1:nrepeat
            [unused,i]=sort(rp(row_first:row_last,r));
            sample_ids{k,r}=i(1:nselect(k));
        end

        row_first=row_last+1;
    end

