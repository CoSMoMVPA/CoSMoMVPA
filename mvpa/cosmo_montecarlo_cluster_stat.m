function ds_z=cosmo_montecarlo_cluster_stat(ds,nbrhood,varargin)
% compute random-effect cluster statistics corrected for multiple comparisons
%
% ds_z=cosmo_montecarlo_cluster_stat(ds,nh,varargin)
%
% Inputs:
%   ds                  dataset struct
%   nbrhood             neighborhood structure, typically from
%                       cosmo_cluster_neighborhood
%   'niter',niter       number of null iterations. More null
%                       iterations leads to a more precise estimate of the
%                       cluster statistics, but also takes longer. Except
%                       for testing scenarios, this value should usually be
%                       at least 1000, but 10,000 or more is recommended
%                       for publication-quality analyses.
%   'h0_mean'           mean under the null hypothesis
%                       Required if and only if a one-sample t-test is
%                       performed, i.e. all values in ds.sa.targets are the
%                       same and all values in ds.sa.chunks are different
%                       - If ds contains correlation differences, then
%                         h0_mean=0 is a typical value
%                       - If ds contains classification accuracies, then
%                         h0_mean=1/C, with C the number of classes
%                         (conditions), is a typical value (assuming that
%                         the partitioning scheme is balanced)
%   'cluster_stat',s    (optional) statistic for clusters, one of 'tfce'
%                       'max', 'maxsum', 'maxsize'. Default: 'tfce'
%                       (Threshold-Free Cluster Enhancement; see
%                       References)
%   'dh',dh             (optional) Threshold step (only if cluster_stat is
%                       'tfce'). The default value of dh=0.1 should be fine
%                       in most (if not all) cases.
%   'p_uncorrected'     (optional) Uncorrected (feature-wise) p-value (only
%                       if cluster_stat is not 'tfce')
%   'null', null_data   (optional) 1xP cell with null datasets, for example
%                       from cosmo_randomize_targets. Each dataset in
%                       null_data{i} must have the same size as ds, but
%                       must contain null data. For example, if a
%                       one-sample t-test across participants is used to
%                       test classification  accuracies against chance
%                       level (with the 'h0_mean' option), then each
%                       dataset null{i} should contain classification
%                       accuracies for each participant that were computed
%                       using randomized values for .sa.targets.
%                       If this option is provided, then null data is
%                       sampled from null_data. According to Stelzer et al
%                       (see References), about 100 null datasets per
%                       participant are sufficient for good estimates of
%                       data under the null hypothesis
%                       If this option is not provided, null data is based
%                       on the contents of ds, which is less precise (more
%                       conservative, in other words has less power)
%   'progress',p        Show progress every p steps (default: 10). Use
%                       p=false to not show progress.
%   'seed',s            Use seed s for pseudo-random number generation. If
%                       this option is provided, then this function behaves
%                       deterministically. If this option is omitted (the
%                       default), then repeated calls with the same input
%                       may lead to slightly different results.
%
% Output:
%   ds_z                Dataset struct with (two-tailed) z-scores for each
%                       feature corrected for multiple comparisons.
%                       The type of feature-wise statistic (one-sample
%                       t-test, two-sample t-test, one-way ANOVA, or
%                       repeated-measures ANOVA) depends on the contents of
%                       ds.sa.targets and ds.sa.chunks (see Notes).
%                       For example, at alpha=0.05, these can be
%                       interpreted as:
%                       - For a one-tailed test:
%                           z < -1.6449   statistic is below expected mean
%                          |z|<  1.6449   statistic is not significant
%                           z >  1.6449   statistic is above expected mean
%                       - For a two-tailed test:
%                           z < -1.9600  statistic is below expected mean
%                          |z|<  1.9600  statistic is not significant
%                           z >  1.9600  statistic is above expected mean
%                       where |z| denotes the absolute value of z.
%                       Use normcdf to convert the z-scores to p-values.
%
% Example:
%     % Generate tiny synthetic dataset representing 6 subjects, one
%     % condition, 6 voxels
%     ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',6);
%     %
%     % Define clustering neighborhood
%     nh=cosmo_cluster_neighborhood(ds,'progress',false);
%     %
%     % Set options for monte carlo based clustering statistic
%     opt=struct();
%     opt.cluster_stat='tfce';  % Threshold-Free Cluster Enhancement;
%                               % this is a (very reasonable) default
%     opt.niter=50;             % this is way too small except for testing;
%                               % should usually be >=1000;
%                               % better is >=10,000
%     opt.h0_mean=0;            % test against mean of zero
%     opt.seed=1;               % should usually not be used, unless exact
%                               % replication of results is required
%                               %  replication
%     opt.progress=false;       % do not show progress
%                               % (only for in this example)
%     %
%     % Apply cluster-based correction
%     z_ds=cosmo_montecarlo_cluster_stat(ds,nh,opt);
%     %
%     % Show z-scores of each feature corrected for multiple comparisons;
%     % One feature has abs(z_ds.samples)>1.96, indicating it
%     % survives correction for multiple comparisons
%     cosmo_disp(z_ds.samples)
%     > [ 1.41    -0.553      2.05    0.0753      1.75    0.0502 ]
%
%
% Notes:
%   - In the input dataset, ds.sa.targets should indicate the condition (or
%     class), whereas ds.sa.chunks should indicate (in)dependency of
%     measurements. In a second-level (group) analysis, ds.sa.chunks should
%     be set so that different subjects have different values in
%     ds.sa.chunks; and different conditions should have different values
%     in ds.sa.targets. The following table illustrates how .sa.targets and
%     .sa.chunks should be set to perform within- or between-group
%     statistical tests:
%
%     ds.sa.targets'   ds.sa.chunks'
%     --------------   -------------
%     [1 1 1 1 1 1]    [1 2 3 4 5 6]    Six subjects, one condition;
%                                       one-sample t-test against the null
%                                       hypothesis of a mean of h0_mean
%                                       (h0_mean is required)
%     [1 1 1 2 2 2]    [1 2 3 4 5 6]    Six subjects, two groups;
%                                       two-sample (unpaired) t-test
%                                       against the null hypothesis of no
%                                       differences between the two groups
%                                       (h0_mean is not allowed)
%     [1 1 2 2 3 3]    [1 2 3 4 5 6]    Six subjects, three groups;
%                                       one-way ANOVA against the null
%                                       hypothesis of no differences
%                                       between the three groups.
%                                       (h0_mean is not allowed)
%     [1 1 1 2 2 2]    [1 2 3 1 2 3]    Three subjects, two conditions;
%                                       paired t-test against the null
%                                       hypothesis of no differences
%                                       between samples with targets=1 and
%                                       those with targets=2.
%                                       (h0_mean is not allowed)
%     [1 1 2 2 3 3]    [1 2 1 2 1 2]    Two subjects, three conditions;
%                                       repeated-measures ANOVA against
%                                       the null hypothesis of no
%                                       differences between samples with
%                                       targets=1, targets=2, and targets=3
%                                       (h0_mean is not allowed)
%
%   - As illustrated above, if the 'h0_mean' option is provided, then a
%     one-sample t-test against a mean of h0_mean is performed. Use-cases
%     involve testing one group of subjects against a mean of zero for
%     correlation differences (if maps were obtained using a searchlight
%     with cosmo_correlation_measure), or against a mean of 1/C (if maps
%     were obtained using a searchlight with classification analysis
%     with C classes, with each class occuring equally often in the
%     training set).
%   - The permutations used with the 'h0_mean' option involve randomly
%     flipping the sign of samples (over all features) after subtracting
%     'h0_mean' (This preserves spatial smoothness in individual samples).
%     This approach is fast but somewhat conservative, and it becomes
%     more conservative with larger effect sizes. For the most accurate
%     (but also slowest to compute) results, use the 'null' data option
%     instead.
%   - The number of iterations determines the precision of the estimates
%     z-scores. For publication-quality papers, 10,000 iterations is
%     recommended.
%   - The neighborhood used for clustering can, for almost all use cases,
%     be computed using cosmo_cluster_neighborhood.
%   - The rationale for returning z-scores (instead of p-values) that are
%     corrected for multiple comparisons is that extreme values are the
%     most significant; when visualized using an external package, a
%     threshold can be applied to see which features (e.g. voxels or nodes)
%     survive a particular cluster-corrected significance threshold.
%
% References:
%   - Stephen M. Smith, Thomas E. Nichols (2009), Threshold-free
%     cluster enhancement: Addressing problems of smoothing, threshold
%     dependence and localisation in cluster inference, NeuroImage, Volume
%     44, 83-98.
%   - Maris, E., Oostenveld, R. Nonparametric statistical testing of EEG-
%     and MEG-data. Journal of Neuroscience Methods (2007).
%   - Johannes Stelzer, Yi Chen and Robert Turner (2013). Statistical
%     inference and multiple testing correction in classification-based
%     multi-voxel pattern analysis (MVPA): Random permutations and cluster
%     size control. NeuroImage, Volume 65, 69-82.
%
% See also: cosmo_cluster_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    defaults=struct();
    defaults.dh=.1;
    defaults.cluster_stat='tfce';
    defaults.progress=10;

    opt=cosmo_structjoin(defaults,varargin);

    % ensure dataset and neighborhood are kosher
    check_inputs(ds,nbrhood);



    % the heavy lifting is done by four helper functions:
    % 1) ds_preproc=preproc_func(ds) takes a dataset and preprocesses it.
    %    Here, in the case that h0_mean is provided, it will subtract
    %    h0_mean from the samples; otherwise it does nothing.
    %
    preproc_func=get_preproc_func(ds,opt);

    % 2) ds_perm_iter=permutation_func(iter) returns the null dataset
    %    for the iter-th iteration. If the input has an option .null,
    %    the the null dataset is based on that option; otherwise, it
    %    is based on the input dataset. (Either the contents of .null or
    %    those of the input dataset are stored in permutation_func
    %    using a closure). In all cases, preproc_func is applied to the
    %    null data before the data is permuted
    %
    permutation_preproc_func=get_permuter_preproc_func(ds,preproc_func,...
                                                                opt);

    % 3) ds_zscore=stat_func(ds) takes a dataset ds, performs
    %    a univariate test (for each feature separately), and returns
    %    a dataset with z-scores of the statistic (F or t value)
    stat_func=get_stat_func(ds);

    % 4) cluster_vals=cluster_func(zscores) measures a cluster
    %    based on zscores. For example, if cluster_stat=='tfce', then
    %    cluster_vals contains TFCE scores for each feature
    %    (the contents of nbrhood are stored in cluster_func using
    %    a closure)
    cluster_func=get_clusterizer_func(nbrhood,opt);

    nfeatures=size(ds.samples,2);
    orig_cluster_vals=zeros(2,nfeatures);
    less_than_orig_count=zeros(2,nfeatures);

    niter=opt.niter;

    prev_progress_msg='';
    clock_start=clock();

    for iter=0:niter
        is_null_iter=iter>0;

        if is_null_iter
            ds_perm=permutation_preproc_func(iter);
        else
            ds_perm=preproc_func(ds);
        end

        ds_perm_zscore=stat_func(ds_perm);

        for neg_pos=1:2
            % treat negative and positive values separately

            perm_sign=2*neg_pos-3; % -1 or 1

            % multiple samples by either 1 or -1
            signed_perm_zscore=ds_perm_zscore.samples*perm_sign;

            % apply clustering to z-scored data
            cluster_vals=cluster_func(signed_perm_zscore);

            if is_null_iter
                % null permuted data, see which features show weaker
                % cluster stat than the original data
                perm_lt=max(cluster_vals)<orig_cluster_vals(neg_pos,:);

                % increase counter for those features
                less_than_orig_count(neg_pos,perm_lt)=...
                            less_than_orig_count(neg_pos,perm_lt)+1;
            else
                % original data, store for comparison with null data
                orig_cluster_vals(neg_pos,:)=cluster_vals;
            end
        end

        show_progress=opt.progress && (iter<10 || ...
                                        mod(iter, opt.progress)==0 || ...
                                        iter==niter);

        if show_progress
            iter_pos=max(iter,1);
            p_min=(iter_pos-max(less_than_orig_count,[],2))/iter_pos;
            p_range=sqrt(1/4/max(iter,1));
            msg=sprintf('p = %.3f / %.3f [+/-%.3f] (left/right)',...
                                    p_min,p_range);
            prev_progress_msg=cosmo_show_progress(clock_start, ...
                               (iter+1)/(niter+1), msg, prev_progress_msg);
        end
    end

    assert(max(sum(less_than_orig_count>0,1))<=1);

    % convert p-values of two tails into one p-value
    ps_two_tailed=sum(bsxfun(@times,[-1;1],less_than_orig_count))/...
                                        (niter*2)+.5;

    % deal with extreme tails
    ps_two_tailed(ps_two_tailed>1-1/niter)=1-1/niter;
    ps_two_tailed(ps_two_tailed<  1/niter)=1/niter;

    % convert to z-score
    z_two_tailed=norminv(ps_two_tailed);

    ds_z=struct();
    ds_z.samples=z_two_tailed;
    ds_z.sa.stats={'Zscore()'};
    ds_z.a=ds.a;
    ds_z.fa=ds.fa;


function stat_func=get_stat_func(ds)
    % returns a function f so that f(ds_perm) returns the
    % z-scored univariate f or t statistic for data in ds_perm
    nsamples=size(ds.samples,1);

    unq_targets=unique(ds.sa.targets);
    unq_chunks=unique(ds.sa.chunks);

    if numel(unq_chunks)==nsamples
        % all samples are independent
        % one-sample t-test, two sample t-test, or one-way ANOVA
        switch numel(unq_targets)
            case 1
                stat_name='t';
            case 2
                stat_name='t2';
            otherwise
                stat_name='F';
        end
    else
        % repeated measures design
        switch numel(unq_targets)
            case 2
                stat_name='t';
            otherwise
                stat_name='F';
        end
    end

    stat_func=@(ds_perm) cosmo_stat(ds_perm,stat_name,'z');

function preproc_func=get_preproc_func(ds,opt)
    nsamples=size(ds.samples,1);
    is_one_independent_sample=numel(unique(ds.sa.targets))==1 && ...
                             numel(unique(ds.sa.chunks))==nsamples;
    has_h0_mean=isfield(opt,'h0_mean');
    if is_one_independent_sample
        % one-sample t-test, enable subtracting h0_mean
        if has_h0_mean
            h0_mean=opt.h0_mean;

            preproc_func=@(perm_ds)subtract_from_samples(perm_ds,h0_mean);
        else
            error(['The option ''h0_mean'' is required for this '...
                'dataset, because the targets and chunks '...
                'specify an indepenent design with one '...
                'unique target.\n'...
                'Use h0_mean=M to test against the null hypothesis '...
                'of a mean of M.\n'...
                '- when testing correlation differences, in\n'...
                '  most cases M=0 is appropriate\n'...
                '- when testing classification accuracies (with \n'...
                '  balanced partitions), in most cases M=1/C,\n'...
                '  with C the number of classes (conditions)\n,'...
                '  is approriate'],'');
        end
    else
        % anything but one-sample t-test, permute targets to get
        % permutation
        if has_h0_mean
            error(['The option ''h0_mean'' is not allowed for this '...
                'dataset, because the targets and chunks do not '...
                'specify a design with indepedent samples and one '...
                'unique target']);
        else

            % identitfy permutation function
            preproc_func=@(x)x;
        end
    end

function ds=subtract_from_samples(ds,m)
    ds.samples=ds.samples-m;


function permuter_func=get_permuter_preproc_func(ds,preproc_func,opt)
    % return a general data permutation function
    if ~isfield(opt,'niter')
        error('The option ''niter'' is required');
    end
    niter=opt.niter;
    has_seed=isfield(opt,'seed');

    if has_seed

        % generate pseudo-random seeds for each iteration, and add to
        % function handle using a closure
        seeds=floor(2^31*cosmo_rand(1,niter,'seed',opt.seed));
    else
        seeds=NaN(1,niter);
    end

    % set the data permutation func
    if isfield(opt,'null') && ~isempty(opt.null)
        % permutations are based on null data
        permuter_func=get_null_permuter_func(ds,preproc_func,...
                                                opt.null,seeds);
    else
        % no null data; use ds to generate permutations
        nsamples=size(ds.samples,1);
        is_one_independent_sample=numel(unique(ds.sa.targets))==1 && ...
                                 numel(unique(ds.sa.chunks))==nsamples;

        if is_one_independent_sample
            permuter_func=@(iter)signflip_samples(ds,preproc_func,...
                                                        seeds(iter));
        else
            permuter_func=@(iter)permute_targets(ds,preproc_func,...
                                                        seeds(iter));
        end
    end

function permuter_func=get_null_permuter_func(ds,preproc_func,...
                                            null_datasets,seeds)
    % check all input null datasets to ensure they match ds
    check_null_datasets(ds,null_datasets);

    nnull=numel(null_datasets);
    nchunks=numel(unique(ds.sa.chunks));

    % cell with chunk_pos{k,j} the indices for the k-th null dataset
    % with the j-th chunk
    chunk_pos=cell(nnull,nchunks);
    for j=1:nnull
        null_dataset=null_datasets{j};
        null_idxs=cosmo_index_unique(null_dataset.sa.chunks);
        for k=1:nchunks
            chunk_pos{j,k}=null_idxs{k};
        end
    end

    permuter_func=@(iter) preproc_func(select_null_data(null_datasets, ...
                                            chunk_pos, seeds(iter)));

function ds=select_null_data(null_datasets, chunk_pos, seed)
    % helper function
    % Inputs:
    %    null_datasets       Kx1 cell with dataset structs, where K is the
    %                        number of null datasets
    %    chunk_pos           KxC cell, so that chunk_pos(k,j) has the
    %                        sample indices for the j-th chunk
    %    seed                if not NaN, the seed for the PRNG
    [nnull,nchunks]=size(chunk_pos);
    if isnan(seed)
        rs=cosmo_rand(1,nchunks);
    else
        rs=cosmo_rand(1,nchunks,'seed',seed);
    end

    null_idxs=ceil(rs*nnull);

    ds_cell=cell(nchunks,1);
    for k=1:nchunks
        null_idx=null_idxs(k);
        ds_cell{k}=cosmo_slice(null_datasets{null_idx},...
                                chunk_pos{null_idx,k},1,false);
    end

    ds=cosmo_stack(ds_cell);


function check_null_datasets(ds,null_datasets)
    % ensure data all datasets are in agreement with the input dataset
    if ~iscell(null_datasets)
        error('null data must be a cell with datasets');
    end

    n=numel(null_datasets);

    error_msg='';

    % ensure each null dataset is similar to the original
    for k=1:n
        elem=null_datasets{k};
        error_prefix=sprintf('%d-th null dataset: ',k);

        cosmo_check_dataset(elem,[],error_prefix);

        if ~isequal(size(elem.samples),size(ds.samples))
            error_msg='.samples size mismatch with dataset';
            break;
        end

        if isfield(ds,'fa') && (~isfield(elem,'fa') || ...
                                    ~isequal(elem.fa,ds.fa))
            error_msg='.fa mismatch with dataset';
            break;
        end

        if ~isfield(elem.sa,'chunks') || ~isfield(elem.sa,'targets')
            error_msg='missing chunks or targets';
            break;
        end

        if ~isequal(sort(elem.sa.chunks),sort(ds.sa.chunks))
            error_msg=['sorted chunks are not identical to '...
                            'those in dataset'];
            break;
        end

        if ~isequal(unique(elem.sa.targets),unique(ds.sa.targets))
            error_msg=['unique targets are not the same as '...
                            'those in dataset'];
            break;
        end
    end

    if ~isempty(error_msg)
        error([error_prefix error_msg]);
    end




function ds_preproc=permute_targets(ds,preproc_func,seed)
    % helper function to set randomized targets, optionally using a seed
    ds_preproc=preproc_func(ds);
    if isnan(seed)
        targets=cosmo_randomize_targets(ds_preproc);
    else
        targets=cosmo_randomize_targets(ds_preproc,'seed',seed);
    end

    ds_preproc.sa.targets=targets;

function ds_preproc=signflip_samples(ds,preproc_func,seed)
    % helper function to randomly sign flip samples, optionally using a
    % seed. h0_mean is subtracted before the samples are flipped
    nsamples=size(ds.samples,1);

    if isnan(seed)
        flip_msk=cosmo_rand(nsamples,1)>.5;
    else
        flip_msk=cosmo_rand(nsamples,1,'seed',seed)>.5;
    end

    ds_preproc=preproc_func(ds);
    ds_preproc.samples(flip_msk,:)=-ds_preproc.samples(flip_msk,:);




function clustering_func=get_clusterizer_func(nbrhood,opt)
    cluster_stat=opt.cluster_stat;
    opt=rmfield(opt,'cluster_stat');

    if ~isfield(opt,'feature_sizes')
        if cosmo_isfield(nbrhood,'fa.sizes')
            opt.feature_sizes=nbrhood.fa.sizes;
        else
            error(['option ''feature_sizes'' is not provided, '...
                    'and neighborhood struct does not contain a field '...
                    '.fa.sizes. This probably means that the '...
                    'neighborhood was not created using '...
                    'cosmo_cluster_neighborhood (which sets this '...
                    'feature attribute appropriately)\n\n'...
                    'Background: cluster measure usually requires the '...
                    'relative size of each feature. For example:\n'...
                    '- in a volumetric fMRI dataset it can be a '...
                    ' row vector of ones, because all voxels have '...
                    'the same size\n'...
                    '- in a surface-based dataset it should be '...
                    'the area of each node (such as computed by '...
                    'surfing_surfacearea in the surfing toolbox).\n\n'...
                    'Your options are:\n'...
                    '- generate the neighborhood using '...
                    'cosmo_cluster_neighborhood. This is the easiest '...
                    'option and should be used unless you are using '...
                    'a custom cluster neighborhood.\n'...
                    '- set the .fa.sizes manually.\n'],'');
        end
    end

    has_p_uncorrected=isfield(opt, 'p_uncorrected');

    switch cluster_stat
        case 'tfce'
            if has_p_uncorrected
                error(['option ''p_uncorrected'' not allowed '...
                            'for method %s'],cluster_stat);
            end

        otherwise
            if ~has_p_uncorrected
                error('missing field ''p_uncorrected'' for method %s',...
                        cluster_stat);
            end

            p_unc=opt.p_uncorrected;

            if ~isscalar(p_unc) || p_unc<=0 || p_unc>=.5
                error(['''p_uncorrected'' value must be between '...
                        '0 and .5; typical values are 0.001 or 0.05']);
            end

            opt=rmfield(opt,'p_uncorrected');
            opt=rmfield(opt,'dh'); % from TFCE defaults
            opt.threshold=-norminv(p_unc); % right tail
    end

    % convert neighborhood struct to matrix representation, because that
    % speeds up clustering significantly
    nbrhood_mat=cosmo_convert_neighborhood(nbrhood,'matrix');

    clustering_func=@(perm_ds) cosmo_measure_clusters(perm_ds,...
                                                       nbrhood_mat,...
                                                       cluster_stat,...
                                                       opt);
function check_inputs(ds, nbrhood)
    cosmo_check_dataset(ds);
    cosmo_check_neighborhood(nbrhood,ds);

