function ds_stat=cosmo_montecarlo_phase_stat(ds,varargin)
% compute phase statistics based on Monte Carlo simulation
%
% ds_stat=cosmo_montecarlo_phase_stat(ds,...)
%
% Inputs:
%   ds                      dataset struct with fields:
%       .samples            PxQ complex matrix for P samples (trials,
%                           observations) and Q features (e.g. combinations
%                           of time points, frequencies and channels)
%       .sa.targets         Px1 array with trial conditions.
%                           There must be exactly two conditions, thus
%                           .sa.targets must have exactly two unique
%                           values. A balanced number of samples is
%                           requires, i.e. each of the two unique values in
%                           .sa.targets must occur equally often.
%       .sa.chunks          Px1 array indicating which samples can be
%                           considered to be independent. It is required
%                           that all samples are independent, therefore
%                           all values in .sa.chunks must be different from
%                           each other
%       .fa                 } optional feature attributes
%       .a                  } optional sample attributes
%  'output',p               Return statistic, one of the following:
%                           - 'pbi': phase bifurcation index
%                           - 'pos': phase opposition sum
%                           - 'pop': phase opposition product
%  'niter',niter            Generate niter null datasets by random
%                           shuffling the targets.
%                           If you have no idea what value to use, consider
%                           using niter=1000.
%  'zscore',z               (optional, default='non_parametric')
%                           Compute z-score using either:
%                           'non_parametric': non-parametric approach based
%                                             on how many values in the
%                                             original dataset show an
%                                             output greater than the
%                                             null data.
%                           'parametric'    : parametric approach based on
%                                             mean and standard deviation
%                                             of the null data. This would
%                                             assume normality of the
%                                             computed output statistic.
%  'extreme_tail_set_nan',n (optional, default=true)
%                           If n==true and all the output value in the
%                           original dataset for a particular feature i is
%                           less than or greater than all output values for
%                           that feature in the null datasets, set the
%                           output in stat.samples(i) to NaN.
%                           If n==false, the p value corresponding to the
%                           output is limited to the range
%                               [1/niter,1-1/niter]
%  'progress',p             (optional,default=1)
%                           Show progress every p null datasets.
%  'permuter_func',f        (optional, default is function defined in
%                            this function's body)
%                           Function handle with signature
%                             idxs=f(iter)
%                           which returns permuted indices in the range
%                           1:nsamples for the iter-th iteration with that
%                           seed value. The targets are resamples using
%                           these permuted indices.
%  'seed',s                 (optional, default=1)
%                           Use seed s when generating pseudo-random
%                           permutations for null distribution.
%
% Output:
%   stat_ds                 Dataset with field
%       .samples            1xQ z-scores indicating the probability of the
%                           observed data in ds.samples, under the null
%                           hypothesis of no phase difference. z-scores are
%                           not corrected for multiple comparisons.
%
% Notes:
%   - this function computes phase statistics for each feature separately;
%     it does not correct for multiple comparisons
%   - p-values are computed by dividing as (r+1) / (niter+1), with r the
%     number of times that the original data as less then the null
%     distributions. This follows the recommendation of North et al (2002).
%
% Reference
%   - North, Bernard V., David Curtis, and Pak C. Sham. "A note on the
%     calculation of empirical P values from Monte Carlo procedures." The
%     American Journal of Human Genetics 71.2 (2002): 439-441.
%
% See also: cosmo_phase_stat, cosmo_phase_itc

    defaults=struct();
    defaults.progress=10;
    defaults.permuter_func=[];
    defaults.zscore='non_parametric';
    defaults.extreme_tail_set_nan=true;
    defaults.seed=1;

    opt=cosmo_structjoin(defaults,varargin{:});
    check_inputs(ds,opt);

    progress_func=get_progress_func(opt);

    [nsamples,nfeatures]=size(ds.samples);

    % normalize dataset here. This is more efficient than letting
    % cosmo_phase_stat normalize the data for each null dataset seperately.
    ds.samples=ds.samples./abs(ds.samples);
    phase_opt=struct();
    phase_opt.output=opt.output;
    phase_opt.samples_are_unit_length=true;
    phase_opt.check_dataset=false;

    phase_func=@(phase_ds) cosmo_phase_stat(phase_ds, phase_opt);

    % compute statistic for original dataset
    stat_orig=phase_func(ds);

    % indicate progress
    progress_func(0);

%     % set permutation function
    permuter_func=get_permuter_func(opt,nsamples);

    zscore_func=get_zscore_func(opt.zscore);
    z=zscore_func(ds,stat_orig,phase_func,progress_func,permuter_func,opt);

    ds_stat=stat_orig;
    ds_stat.samples=z;

    progress_func(opt.niter+1);
    cosmo_check_dataset(ds_stat);


function permuter_func=get_permuter_func(opt,nsamples)
    permuter_func=opt.permuter_func;
    if isempty(permuter_func)
        permuter_func=@(iter)default_permute(nsamples,...
                                                    opt.seed,opt.niter,...
                                                    iter);
    end

function zscore_func=get_zscore_func(zscore_name)
    funcs=struct();
    funcs.non_parametric=@compute_zscore_non_parametric;
    funcs.parametric=@compute_zscore_parametric;

    if ~(ischar(zscore_name) ...
            && isfield(funcs,zscore_name))
        error('Illegal ''zscore'' option, allowed are: ''%s''',...
                    cosmo_strjoin(fieldnames(funcs),''', '''));
    end

    zscore_func=funcs.(zscore_name);


function z=compute_zscore_parametric(ds,stat_orig,phase_func,...
                                                progress_func,permuter_func,opt)
    niter=opt.niter;
    nfeatures=size(ds.samples,2);

    null_data=zeros(niter,nfeatures);
    for iter=1:niter
        ds_null=ds;
        ds_null.sa.targets=ds.sa.targets(permuter_func(iter));
        stat_null=phase_func(ds_null);

        null_data(iter,:)=stat_null.samples;
        progress_func(iter);
    end

    mu=mean(null_data,1);
    sd=std(null_data,[],1);

    z=(stat_orig.samples-mu)./sd;


function z=compute_zscore_non_parametric(ds,stat_orig,phase_func,...
                                        progress_func,permuter_func,opt)
    % compute z-score non-parametrically
    % number of times the original data is less than (leading to negative
    % values) or greater than (leading to positive values) the null data.
    % Afer running all iterations, values in exceed_count range from
    % -opt.niter to +opt.niter.
    nfeatures=size(ds.samples,2);
    exceed_count=zeros(1,nfeatures);

    niter=opt.niter;
    for iter=1:niter
        ds_null=ds;

        sample_idxs=permuter_func(iter);
        ds_null.sa.targets=ds.sa.targets(sample_idxs);
        stat_null=phase_func(ds_null);

        msk_gt=stat_orig.samples>stat_null.samples;
        msk_lt=stat_orig.samples<stat_null.samples;

        exceed_count(msk_gt)=exceed_count(msk_gt)+1;
        exceed_count(msk_lt)=exceed_count(msk_lt)-1;

        progress_func(iter);
    end

    % Note that exceed_count is even if niter is even.
    %
    % if exceed_count==-niter,     p=1/(niter+1)
    % if             ==-(niter+2), p=2/(niter+1)
    % if             ==-(niter+4), p=3/(niter+1)
    % ...
    %
    % if exceed_count==niter,      p=niter/(niter+1)
    % if exceed_count==niter-2,    p=(niter-1)/(niter+1)
    % if exceed_count==niter-4,    p=(niter-2)/(niter+1)
    p=.5+zeros(1,nfeatures);
    neg_msk=exceed_count<0;
    p(neg_msk)=((exceed_count(neg_msk)+niter)/2+1)/(niter+1);

    pos_msk=exceed_count>0;
    p(pos_msk)=1-((niter-exceed_count(pos_msk))/2+1)/(niter+1);

    tail=1/(2*(niter+1))-1e-7;
    assert(all(p>=tail));
    assert(all(p<1-tail));

    if opt.extreme_tail_set_nan
        p(exceed_count==-niter | exceed_count==niter)=NaN;
    end

    z=cosmo_norminv(p);

function func=get_progress_func(opt)
    if ~(opt.progress)
        func=@do_nothing;
        return;
    end

    func=@(iter)show_progress(iter,opt.progress,opt.niter);

function show_progress(iter,progress_step,niter)
    persistent prev_msg;
    persistent clock_start;

    reset_state=isempty(clock_start) ...
                    || iter==0 ...
                    || ~ischar(prev_msg);

    if reset_state
        clock_start=clock();
        prev_msg='';
    end

    if mod(iter,progress_step)~=0;
        return;
    end

    msg='';
    progress=(iter+1)/(niter+1);
    prev_msg=cosmo_show_progress(clock_start,progress,msg,prev_msg);





function do_nothing(varargin)
    % This is used in case of no progress reporting.
    % This function does absolutely nothing


function idxs=default_permute(nsamples,seed,niter,iter)
    persistent cached_args;
    persistent cached_rand_vals;

    args={nsamples,seed,niter,iter};
    if ~isequal(cached_args,args)

        if isempty(seed)
            rand_args={};
        else
            rand_args={'seed',seed};
        end

        % compute once for all possible iterations
        cached_rand_vals=cosmo_rand(nsamples,niter,rand_args{:});
        cached_args=args;
    end

    [unused,idxs]=sort(cached_rand_vals(:,iter));



function check_inputs(ds,opt)
    raise_exception=true;
    cosmo_check_dataset(ds,raise_exception);

    if ~isfield(opt,'niter')
        error(['The option ''niter'' is required. If you have '...
                'absolutely no idea what value to use, consider '...
                'using niter=10000']);
    end

    if ~isfield(opt,'output')
        error(['The option ''output'' is required. Use one of '...
                    '''pos'',''pop'', or ''pos''']);
    end

    verify_positive_scalar_int(opt,'niter');
    if ~isequal(opt.progress,false)
        verify_positive_scalar_int(opt,'progress');
    end

    extreme_tail_set_nan=opt.extreme_tail_set_nan;
    if ~(islogical(extreme_tail_set_nan) ...
            && isscalar(extreme_tail_set_nan))
        error('option ''extreme_tail_set_nan'' must be logical scalar');
    end




function verify_positive_scalar_int(opt,name)
    v=opt.(name);
    if ~(isnumeric(v) ...
            && isscalar(v) ...
            && round(v)==v ...
            && v>0)
        error('option ''%s'' must be a positive scalar integer',name);
    end





