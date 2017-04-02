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
%                           shuffling the targets
%  'zscore',z               (optional, default='non_parametric')
%                           Compute z-score using either:
%                           'non_parametric': non-parametric aproach based
%                                             on how many values in the
%                                             original dataset show an
%                                             output greater than the
%                                             null data
%                           'parametric'    : parametric approach based on
%                                             mean and standard deviation
%                                             of the null data. This would
%                                             assume normality of the
%                                             computed output statistic
%  'extreme_tail_set_nan',n (optional, default=true)
%                           If n==true and all the output value in the
%                           original dataset for a particular feature i is
%                           less than or greater than all output values for
%                           that feature in the null datasets, set the
%                           output in stat.samples(i) to NaN.
%                           If n==false,
%  'progress',p             Show progress every p null datasets.
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
%                           hypothesis of no phase difference
%
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

    [nsamples,nfeatures]=size(ds.samples);

    % normalize dataset
    ds.samples=ds.samples./abs(ds.samples);


    phase_opt=struct();
    phase_opt.output=opt.output;
    phase_opt.samples_are_unit_length=true;
    phase_opt.check_dataset=false;

    stat_orig=cosmo_phase_stat(ds,phase_opt);

    permuter_func=opt.permuter_func;
    if isempty(permuter_func)
        opt.permuter_func=@(iter)default_permute(nsamples,...
                                                    opt.seed,opt.niter,...
                                                    iter);
    end

    zscore_func=get_zscore_func(opt.zscore);
    z=zscore_func(ds,stat_orig,opt);

    ds_stat=stat_orig;
    ds_stat.samples=z;

    cosmo_check_dataset(ds_stat);



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


function z=compute_zscore_parametric(ds,stat_orig,opt)
    niter=opt.niter;
    nfeatures=size(ds.samples,2);

    null_data=zeros(niter,nfeatures);
    for iter=1:niter
        ds_null=ds;
        ds_null.sa.targets=ds.sa.targets(opt.permuter_func(iter));
        stat_null=cosmo_phase_stat(ds_null,opt);

        null_data(iter,:)=stat_null.samples;
    end

    mu=mean(null_data,1);
    sd=std(null_data,[],1);

    z=(stat_orig.samples-mu)./sd;


function z=compute_zscore_non_parametric(ds,stat_orig,opt)
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
        sample_idxs=opt.permuter_func(iter);

        ds_null.sa.targets=ds.sa.targets(sample_idxs);
        stat_null=cosmo_phase_stat(ds_null,opt);

        msk_gt=stat_orig.samples>stat_null.samples;
        msk_lt=stat_orig.samples<stat_null.samples;

        exceed_count(msk_gt)=exceed_count(msk_gt)+1;
        exceed_count(msk_lt)=exceed_count(msk_lt)-1;
    end

    p=(exceed_count+niter)/(2*niter);

    if opt.extreme_tail_set_nan
        replacement=NaN;
    else
        replacement=1/niter;
    end

    p(p<1/niter)=replacement;
    p(p>1-1/niter)=1-replacement;

    z=cosmo_norminv(p);



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

    required_fields={'output','niter'};
    missing_fields=setdiff(required_fields,fieldnames(opt));
    if ~isempty(missing_fields)
        error('Missing option ''%s''', missing_fields{1});
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





