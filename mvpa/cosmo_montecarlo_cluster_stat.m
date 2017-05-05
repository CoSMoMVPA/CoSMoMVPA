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
%   'h0_mean'           Mean under the null hypothesis
%                       Required if and only if a one-sample t-test is
%                       performed, i.e. all values in ds.sa.targets are the
%                       same and all values in ds.sa.chunks are different
%                       - If ds contains correlation differences, then
%                         h0_mean=0 is a typical value
%                       - If ds contains classification accuracies, then
%                         h0_mean=1/C, with C the number of classes
%                         (conditions), is a typical value (assuming that
%                         the partitioning scheme is balanced)
%   'feature_stat',f    (optional) statistic for features, one of 'auto' or
%                       'none':
%                       - 'auto': Compute cluster-based statistics (one- or
%                                 two-sample t-test, one-way ANOVA, or
%                                 repeated measures ANOVA; see Notes
%                                 section below how to set the .sa.targets
%                                 and .sa.chunks attributes.
%                       - 'none': Do not compute statistics, but instead
%                                 use the input data from ds directly. In
%                                 this case:
%                                 * no statistic is computed;
%                                 * ds.samples must be a row vector.
%                                 * h0_mean is required.
%                                 * the 'null' option is required
%                                 * 'niter' must not be provided.
%                                 * when using the 'tfce' cluster_stat
%                                   option (the default), 'dh' must be
%                                   provided explicitly.
%                                 This option is intended for use when
%                                 null data and feature-wise statistics
%                                 have already been computed.
%                       Default: 'auto'.
%   'cluster_stat',s    (optional) statistic for clusters, one of 'tfce'
%                       'max', 'maxsum', 'maxsize'. Default: 'tfce'
%                       (Threshold-Free Cluster Enhancement; see
%                       References)
%   'dh',dh             (optional) Threshold step (only if cluster_stat is
%                       'tfce'). The default value of dh=0.1 should be fine
%                       in most (if not all) cases.
%                       Exception: when using 'feature_stat','none',
%                       the 'dh' option is required when using 'tfce'.
%                       For typical use cases, a value so that 100*dh is
%                       in the same order of magnitude as the range
%                       (maximum minus minimum) of the input (in .samples)
%                       may be a reasonable compromise between speed and
%                       accuracy
%   'p_uncorrected'     (optional) Uncorrected (feature-wise) p-value (only
%                       if cluster_stat is not 'tfce')
%   'null', null_data   (optional) 1xP cell with null datasets, for example
%                       from cosmo_randomize_targets. Each dataset in
%                       null_data{i} must have the same size as ds, but
%                       must contain null data. For example, if a
%                       one-sample t-test across participants is used to
%                       test classification  accuracies against chance
%                       level (with the 'h0_mean' option), then each
%                       dataset null_data{i} should contain classification
%                       accuracies for each participant that were computed
%                       using randomized values for .sa.targets.
%                       If this option is provided, then null data is
%                       sampled from null_data. According to Stelzer et al
%                       (see References), about 100 null datasets per
%                       participant are sufficient for good estimates of
%                       data under the null hypothesis.
%                       If this option is not provided, null data is based
%                       on the contents of ds, which is less precise (more
%                       conservative, in other words has less power).
%                       Exception: when using 'feature_stat','none', then
%                       the recommendation for the number of null_data
%                       elements is the same as the recommendation of
%                       'niter' if the 'feature_stat' option is not 'none'.
%   'progress',p        Show progress every p steps (default: 10). Use
%                       p=false to not show progress.
%   'nproc', np         If the Matlab parallel processing toolbox, or the
%                       GNU Octave parallel package is available, use
%                       np parallel threads. (Multiple threads may speed
%                       up computations).
%                       If parallel processing is not available, or if
%                       this option is not provided, then a single thread
%                       is used.
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
%     ||[ 0.929         0      1.76         0      1.29         0 ]
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
%   - Versions of this function from before 23 November 2016 incorrectly
%     producted z-scores corresponding to one-tailed, rather than
%     two-tailed, probablity values.
%   - p-values are computed by dividing as (r+1) / (niter+1), with r the
%     number of times that the original data as less then the null
%     distributions. This follows the recommendation of North et al (2002).
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
%   - North, Bernard V., David Curtis, and Pak C. Sham. "A note on the
%     calculation of empirical P values from Monte Carlo procedures." The
%     American Journal of Human Genetics 71.2 (2002): 439-441.
%
% See also: cosmo_cluster_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    defaults=struct();
    defaults.feature_stat='auto';
    defaults.cluster_stat='tfce';
    defaults.progress=10;
    defaults.nproc=1;

    opt=cosmo_structjoin(defaults,varargin);

    % ensure dataset and neighborhood are kosher
    check_inputs(ds,nbrhood);

    % check input options
    check_opt(ds,opt);

    % get number of processes
    nproc_available=cosmo_parallel_get_nproc_available(opt);

    % Matlab needs newline character at progress message to show it in
    % parallel mode; Octave should not have newline character
    environment=cosmo_wtf('environment');
    progress_suffix=get_progress_suffix(environment);

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

    % 3) ds_zscore=stat_func(ds,opt) takes a dataset ds, performs
    %    a univariate test (for each feature separately), and returns
    %    a dataset with z-scores of the statistic (F or t value)
    stat_func=get_stat_func(ds,opt);

    % 4) cluster_vals=cluster_func(zscores) measures a cluster
    %    based on zscores. For example, if cluster_stat=='tfce', then
    %    cluster_vals contains TFCE scores for each feature
    %    (the contents of nbrhood are stored in cluster_func using
    %    a closure)
    cluster_func=get_clusterizer_func(nbrhood,opt);

    nfeatures=size(ds.samples,2);
    orig_cluster_vals=zeros(2,nfeatures);

    niter=get_niter(opt);

    %compute the original values first
    ds_perm=preproc_func(ds);
    ds_perm_zscore=stat_func(ds_perm);

    for neg_pos=1:2
        % treat negative and positive values separately
        perm_sign=2*neg_pos-3; % -1 or 1
        % multiple samples by either 1 or -1
        signed_perm_zscore=ds_perm_zscore.samples*perm_sign;
        % apply clustering to z-scored data
        cluster_vals=cluster_func(signed_perm_zscore);
        orig_cluster_vals(neg_pos,:)=cluster_vals;
    end

    % split iterations in multiple parts, so that each thread can do a
    % subset of all the work


    [iter_start, iter_end]=divide_in_blocks(niter, nproc_available);
    nproc_used=numel(iter_start);

    % set options for each worker process
    worker_opt_cell=cell(1,nproc_used);
    for p=1:nproc_used
        worker_opt=struct();
        worker_opt.orig_cluster_vals=orig_cluster_vals;
        worker_opt.permutation_preproc_func=permutation_preproc_func;
        worker_opt.stat_func=stat_func;
        worker_opt.cluster_func=cluster_func;
        worker_opt.nfeatures=nfeatures;
        worker_opt.worker_id=p;
        worker_opt.nworkers=nproc_used;
        worker_opt.progress=opt.progress;
        worker_opt.progress_suffix=progress_suffix;
        worker_opt.iters=iter_start(p):iter_end(p);
        worker_opt_cell{p}=worker_opt;
    end

    % Run process for each worker in parallel
    % Note that when using nproc=1, cosmo_parcellfun does actually not
    % use any parallellization; the result is a cell with a single element.
    result_cell=cosmo_parcellfun(nproc_used,...
                                    @run_with_worker,...
                                    worker_opt_cell,...
                                    'UniformOutput',false);

    % join results from each worker
    less_than_orig_count = sum(cat(3,result_cell{:}),3);

    % safety check: each item is either positive or negative
    assert(max(sum(less_than_orig_count>0,1))<=1);

    % convert p-values of two tails into one p-value
    pos_mask=less_than_orig_count(1,:)>niter/2;
    neg_mask=less_than_orig_count(2,:)>niter/2;
    nfeatures=numel(pos_mask);
    ps_two_tailed=zeros(1,nfeatures)+.5;

    min_p_value=1/(niter+1);

    % - in the extreme case of highly positive values
    %     less_than_orig_count==0
    %   and we want to set p=1-1/(niter+1),
    % - in the case of no positive values
    %     less_than_orig_count==niter/2
    %   and we want to set p=0.5 = 1-(niter/2+1)/(niter+1)

    ps_two_tailed(pos_mask)=(niter-less_than_orig_count(1,pos_mask)+1)*min_p_value;
    ps_two_tailed(neg_mask)=1-(niter-less_than_orig_count(2,neg_mask)+1)*min_p_value;


    tiny=1e-8;
    assert(all(ps_two_tailed+tiny>=  min_p_value));
    assert(all(ps_two_tailed-tiny<=1-min_p_value));

    % convert to z-score
    z_two_tailed=cosmo_norminv(ps_two_tailed);

    % store result in dataset structure
    ds_z=struct();
    ds_z.samples=z_two_tailed;
    ds_z.sa.stats={'Zscore()'};
    ds_z.a=ds.a;
    ds_z.fa=ds.fa;

function [iter_start, iter_end]=divide_in_blocks(niter, nproc_available)
    nblocks=min(niter,nproc_available);
    block_size = ceil(niter/nblocks);

    iter_start=1:block_size:niter;
    iter_end=iter_start+(block_size-1);
    iter_end(end)=niter;


function less_than_orig_count=run_with_worker(worker_opt)

    orig_cluster_vals=worker_opt.orig_cluster_vals;
    permutation_preproc_func=worker_opt.permutation_preproc_func;
    stat_func=worker_opt.stat_func;
    cluster_func=worker_opt.cluster_func;
    nfeatures=worker_opt.nfeatures;
    worker_id=worker_opt.worker_id;
    nworkers=worker_opt.nworkers;
    progress=worker_opt.progress;
    progress_suffix=worker_opt.progress_suffix;
    iters=worker_opt.iters;

    less_than_orig_count=zeros(2,nfeatures);
    niter = length(iters);

    % see if progress is to be reported
    show_progress=~isempty(progress) && ...
                        progress && ...
                        worker_id==1;
    if show_progress
        progress_step=progress;
        if progress_step<1
            progress_step=ceil(ncenters*progress_step);
        end
        prev_progress_msg='';
        clock_start=clock();
    end

    for iter=1:niter
        ds_perm=permutation_preproc_func(iters(iter));
        ds_perm_zscore=stat_func(ds_perm);

        for neg_pos=1:2
            % treat negative and positive values separately

            perm_sign=2*neg_pos-3; % -1 or 1

            % multiple samples by either 1 or -1
            signed_perm_zscore=ds_perm_zscore.samples*perm_sign;

            % apply clustering to z-scored data
            cluster_vals=cluster_func(signed_perm_zscore);

            % null permuted data, see which features show weaker
            % cluster stat than the original data
            perm_lt=max(cluster_vals)<orig_cluster_vals(neg_pos,:);

            % increase counter for those features
            less_than_orig_count(neg_pos,perm_lt)=...
                        less_than_orig_count(neg_pos,perm_lt)+1;
        end

        if show_progress && (iter<10 || ...
                                ~mod(iter, progress_step) || ...
                                iter==niter);
            if nworkers>1
                if iter==niter
                    % other workers may be slower than first worker
                    msg=sprintf(['worker %d has completed; waiting for '...
                                    'other workers to finish...%s'],...
                                    worker_id, progress_suffix);
                else
                    % can only show progress from a single worker;
                    % therefore show progress of first worker
                    msg=sprintf('for worker %d / %d%s', worker_id, ...
                                    nworkers, progress_suffix);
                end
                prev_progress_msg=cosmo_show_progress(clock_start, ...
                                iter/niter, msg, prev_progress_msg);
            else
                iter_pos=max(iter,1);
                p_min=(iter_pos-max(less_than_orig_count,[],2))/iter_pos;
                p_range=sqrt(1/4/max(iter,1));
                msg=sprintf('p = %.3f / %.3f [+/-%.3f] (left/right)',...
                                        p_min,p_range);
                prev_progress_msg=cosmo_show_progress(clock_start, ...
                                   (iter+1)/(niter+1), msg, prev_progress_msg);
            end
        end
    end

function stat_func=get_stat_func(ds,opt)
    if has_feature_stat_auto(opt)
        stat_func=get_stat_func_auto(ds);
    else
        stat_func=get_stat_func_none(ds);
    end

function stat_func=get_stat_func_none(ds)
    % returns a function f so that f(ds_perm) returns
    % just ds_perm

    stat_func=@(x)x;


function stat_func=get_stat_func_auto(ds)
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

    has_targets_chunks=all(cosmo_isfield(ds,{'sa.targets',...
                                                'sa.chunks'}));
    is_one_independent_sample=has_targets_chunks && ...
                              numel(unique(ds.sa.targets))==1 && ...
                              numel(unique(ds.sa.chunks))==nsamples;
    is_single_sample=size(ds.samples,1)==1;

    has_h0_mean=isfield(opt,'h0_mean');
    if is_one_independent_sample || is_single_sample
        % one-sample t-test, enable subtracting h0_mean
        if has_h0_mean
            h0_mean=opt.h0_mean;

            preproc_func=@(perm_ds)subtract_from_samples(perm_ds,h0_mean);
        else
            if is_single_sample
                infix='the .samples field has a single row';
            else
                infix=['the targets and chunks '...
                        'specify an indepenent design with one '...
                        'unique target'];
            end

            error(['The option ''h0_mean'' is required for this '...
                'dataset, because %s.\n'...
                'Use h0_mean=M to test against the null hypothesis '...
                'of a mean of M.\n'...
                '- when testing correlation differences, in\n'...
                '  most cases M=0 is appropriate\n'...
                '- when testing classification accuracies (with \n'...
                '  balanced partitions), in most cases M=1/C,\n'...
                '  with C the number of classes (conditions)),\n'...
                '  is approriate'],infix);
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


function niter=get_niter(opt)
    if has_feature_stat_auto(opt)
        niter=opt.niter;
    else
        niter=numel(opt.null);
    end

function tf=has_feature_stat_auto(opt)
    tf=isequal(opt.feature_stat,'auto');

function permuter_func=get_permuter_preproc_func(ds,preproc_func,opt)
    if has_feature_stat_auto(opt)
        permuter_func=get_permuter_preproc_stat_func(ds,preproc_func,opt);
    else
        permuter_func=get_permuter_preproc_none_func(ds,preproc_func,opt);
    end

function permuter_func=get_permuter_preproc_none_func(ds,preproc_func,opt)
    % if no stats func, that means also no selection of random samples;
    % instead, the number of iterations is defined by the 'null' input
    if isfield(opt,'niter')
        error(['The option ''niter'' is not allowed '...
                        'with ''none'' statfunc']);
    end

    if ~isfield(opt,'null')
        error(['The option ''null'' is required '...
                        'with ''none'' statfunc']);
    end

    permuter_func=@(iter) preproc_func(opt.null{iter});

function permuter_func=get_permuter_preproc_stat_func(ds,preproc_func,opt)

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
    tfce_default_dh=.1;

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

            if ~isfield(opt,'dh')
                % use default
                opt.dh=tfce_default_dh;
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
            if isfield(opt,'dh')
                error(['Option dh not allowed with non-tfce '...
                        'cluster_stat option ''%s'''], cluster_stat);
            end
            opt.threshold=-cosmo_norminv(p_unc); % right tail
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

function check_opt(ds,opt)
    feature_stat=opt.feature_stat;
    if ~ischar(feature_stat)
        error('''feature_stat'' option must be a string');
    end

    switch feature_stat
        case 'auto'
            assert(has_feature_stat_auto(opt));
            % ok

        case 'none'
            assert(~has_feature_stat_auto(opt));
            if size(ds.samples,1)~=1
                error(['When using ''none'' feature_stat option, '...
                            '.samples input must be a row vector']);
            end

            if strcmp(opt.cluster_stat,'tfce')
                if ~isfield(opt,'dh')
                    error(['Option ''dh'' must be set explicitly when '...
                            'using feature_stat=''none'' with TFCE. '...
                            'Which value for dh may be most suitable '...
                            'depends on the range of the input '...
                            '.samples field and the desired '...
                            'precision. For typical use cases, a value '...
                            'so that 100*dh is in the same order of '...
                            'magnitude as the range (maximum minus '...
                            'minimum) of the input (in .samples) may '...
                            'be a reasonable compromise between speed '...
                            'and accuracy.']);
                end
            end



        otherwise
            error('illegal feature_stat ''%s''',feature_stat);
    end


function suffix=get_progress_suffix(environment)
    % Matlab needs newline character at progress message to show it in
    % parallel mode; Octave should not have newline character

    switch environment
        case 'matlab'
            suffix=sprintf('\n');
        case 'octave'
            suffix='';
    end
