function ds_avg=cosmo_average_samples(ds, varargin)
% average subsets of samples by unique combinations of sample attributes
%
% ds_avg=cosmo_average_samples(ds, ...)
%
% Inputs:
%   ds              dataset struct with field:
%     .samples      NS x NF
%     .sa           with fields .targets and .chunks
%   'ratio', ratio  ratio (between 0 and 1) of samples to select for
%                   each average. Not compatible with 'count' (default: 1).
%   'count', c      number of samples to select for each average.
%                   Not compatible with 'ratio'.
%   'resamplings',s Maximum number of times each sample in ds is used for
%                   averaging. Not compatible with 'repeats' (default: 1)
%   'repeats', r    Number of times an average is computed for each unique
%                   combination of targets and chunks. Not compatible with
%                   'resamplings'
%   'seed', d       Use seed d for pseudo-random sampling (optional); d
%                   can be any integer between 1 and 2^32-1.
%                   If this option is omitted, then different calls to this
%                   function may (usually: will) return different results.
%   'split_by',fs   A cell with fieldnames by which the dataset is split
%                   prior to averaging each bin.
%                   Default: {'targets','chunks'}.
%
%
% Returns
%   ds_avg          dataset struct with field:
%      .samples     ('repeats'*unq) x NF, where
%                   unq is the number of unique combinations of values in
%                   sample attribute as indicated by 'split_by' (by
%                   default, data is split by 'targets' and 'chunks').
%                   Each sample is an average from samples that share the
%                   same values for these attributes. The number of times
%                   each sample is used to compute average values differs
%                   by one at most.
%      .sa          Based on averaged samples.
%      .fa,.a       Same as in ds (if present).
%
% Examples:
%     % generate simple dataset with 3 times (2 targets x 3 chunks)
%     ds=cosmo_synthetic_dataset('nreps',3);
%     size(ds.samples)
%     %|| [ 18 6 ]
%     cosmo_disp([ds.sa.targets ds.sa.chunks])
%     %|| [ 1         1
%     %||   2         1
%     %||   1         2
%     %||   :         :
%     %||   2         2
%     %||   1         3
%     %||   2         3 ]@18x2
%     % average each unique combination of chunks and targets
%     ds_avg=cosmo_average_samples(ds);
%     cosmo_disp([ds_avg.sa.targets ds_avg.sa.chunks]);
%     %|| [ 1         1
%     %||   1         2
%     %||   1         3
%     %||   2         1
%     %||   2         2
%     %||   2         3 ]
%     %
%     % for each unique target-chunk combination, select 50% of the samples
%     % randomly and average these; repeat the random selection process 4
%     % times. Each sample in 'ds' is used twice (=.5*4) as an element
%     % to compute an average. The output has 24 samples
%     ds_avg2=cosmo_average_samples(ds,'ratio',.5,'repeats',4);
%     cosmo_disp([ds_avg2.sa.targets ds_avg2.sa.chunks],'edgeitems',5);
%     %|| [ 1         1
%     %||   1         1
%     %||   1         1
%     %||   1         1
%     %||   1         2
%     %||   :         :
%     %||   2         2
%     %||   2         3
%     %||   2         3
%     %||   2         3
%     %||   2         3 ]@24x2
%
% Notes:
%  - this function averages feature-wise; the output has the same features
%    as the input.
%  - it can be used to average data from trials safely without circular
%    analysis issues.
%  - as a result the number of trials in each chunk and target is
%    identical, so balancing of partitions is not necessary for data from
%    this function.
%  - the default behaviour of this function computes a single average for
%    each unique combination of chunks and targets.
%  - if the number of samples differs for different combinations of chunks
%    and targets, then some samples may not be used to compute averages,
%    as the least number of samples across combinations is used to set
%  - As illustration, consider a dataset with the following number of
%    samples for each unique targets and chunks combiniation
%
%    .sa.chunks     .sa.targets         number of samples
%    ----------     -----------         -----------------
%       1               1                   12
%       1               2                   16
%       2               1                   15
%       2               2                   24
%
%    The least number of samples is 12, which determines how many averages
%    are computed. Different parameters result in a different number of
%    averages; some examples:
%
%       parameters                      number of output samples for each
%                                       combination of targets and chunks
%       ----------                      ---------------------------------
%       'count', 2                      6 averages from 2 samples [*]
%       'count', 3                      4 averages from 3 samples [*]
%       'ratio', .25                    4 averages from 3 samples [*]
%       'ratio', .5                     2 averages from 6 samples [*]
%       'ratio', .5, 'repeats', 3       6 averages from 6 samples
%       'ratio', .5, 'resamplings', 3   12 averages from 6 samples
%
%    [*]: not all samples in the input are used to compute averages from
%         the output.
%
%    Briefly, 'ratio' or 'count' determine, together with the least number
%    of samples, how many samples are averaged for each output sample.
%    'resamplings' and 'repeats' determine how many averages are taken,
%    based on how many samples are averaged for each output sample.
% -  To compute averages based on other sample attributes than 'targets'
%    and 'chunks', use the 'split_by' option
%
% See also: cosmo_balance_partitions
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % deal with input parameters

    defaults=struct();
    defaults.seed=[];
    defaults.split_by={'targets','chunks'};

    opt=cosmo_structjoin(defaults, varargin);
    split_idxs=get_split_indices(ds, opt);

    nsplits=numel(split_idxs);
    bin_counts=cellfun(@numel,split_idxs);

    [split_sample_ids,nrepeat]=get_split_sample_ids(bin_counts,opt);

    nfeatures=size(ds.samples,2);

    mu=zeros(nrepeat*nsplits,nfeatures);
    slice_ids=zeros(nrepeat*nsplits,1);

    row=0;
    for k=1:nsplits
        split_idx=split_idxs{k};
        split_ids=split_sample_ids{k};

        for j=1:nrepeat
            sample_ids=split_idx(split_ids(:,j));

            row=row+1;
            mu(row,:)=mean(ds.samples(sample_ids,:),1);
            slice_ids(row)=sample_ids(1);
        end
    end

    ds_avg=cosmo_slice(ds,slice_ids,1,false);
    ds_avg.samples=mu;


function split_idxs=get_split_indices(ds, opt)
    persistent cached_sa;
    persistent cached_opt;
    persistent cached_split_idxs;

    if ~(isstruct(ds) && ...
            isfield(ds,'samples') && ...
            isfield(ds,'sa'))
        error(['First argument must be a dataset struct field fields '...
                    'samples and sa']);
    end

    if ~(isequal(cached_opt,opt) && ...
                    isequal(cached_sa,ds.sa))
        split_by=opt.split_by;
        if ~iscellstr(split_by)
            error('''split_by''  must be a cell with strings');
        end

        n_dim=numel(split_by);
        if n_dim==0
            cached_split_idxs={(1:size(ds.samples,1))'};
        else
            values=cell(n_dim,1);
            for k=1:numel(split_by)
                key=split_by{k};
                if ~isfield(ds.sa,key)
                    error('Missing field ''%s'' in .sa', key);
                end
                values{k}=ds.sa.(key);
            end
            cached_split_idxs=cosmo_index_unique(values);
        end


        cached_sa=ds.sa;
        cached_opt=opt;
    end

    split_idxs=cached_split_idxs;


function [idx, value]=get_mutually_exclusive_param(opt, names, ...
                                        default_idx, default_value)
    idx=[];
    value=[];

    n=numel(names);

    for k=1:n
        key=names{k};
        if isfield(opt,key)
            value=opt.(key);
            if ~isempty(value)
                if isempty(idx)
                    idx=k;
                else
                    error(['The options ''%s'' and ''%s'' are mutually '...
                            'exclusive '], key, names{idx});
                end
            end
        end
    end

    if isempty(idx)
        idx=default_idx;
        value=default_value;
    end


function [nselect,nrepeat]=get_selection_params(bin_counts,opt)
    [idx,value]=get_mutually_exclusive_param(opt,{'ratio','count'},1,1);

    switch idx
        case 1
            % ratio
            nselect=round(value*min(bin_counts));
        case 2
            % count
            nselect=value;

    end

    ensure_in_range('Number of elements to select',nselect,...
                                            1,min(bin_counts));


    repeat_labels={'resamplings','repeats'};
    [idx2,value2]=get_mutually_exclusive_param(opt,repeat_labels,1,1);
    switch idx2
        case 1
            nrepeat=floor(value2*min(bin_counts./nselect));
        case 2
            nrepeat=value2;
    end

    ensure_in_range('Number of repeats',...
                            nrepeat,1,Inf);

function ensure_in_range(label, val, min_val, max_val)
    postfix=[];
    while true
        if ~isscalar(val) || ~isnumeric(val)
            postfix='must be numeric scalar';
            break;
        end

        if round(val)~=val
            postfix='must be an integer';
        end

        if val<min_val
            postfix=sprintf('cannot be less than %d', min_val);
            break;
        end

        if val>max_val
            postfix=sprintf('cannot be greater than %d', max_val);
            break;
        end

        break;
    end

    if ~isempty(postfix)
        msg=[label ' ' postfix];
        error(msg);
    end


function [sample_ids,nrepeat]=get_split_sample_ids(bin_counts,opt)
    [nselect,nrepeat]=get_selection_params(bin_counts,opt);

    % number of saples for each unique chunks-targets combination
    nsplits=numel(bin_counts);

    % allocate space for output
    sample_ids=cell(nsplits,1);

    % select samples randomly, but in a manner so that each one is used
    % approximately equally often
    for k=1:nsplits
        bin_count=bin_counts(k);
        sample_ids{k}=cosmo_sample_unique(nselect,bin_count,nrepeat,opt);
    end

