function test_suite=test_montecarlo_phase_stat
% tests for test_phase_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function r=randint()
    r=ceil(rand()*10+10);

function test_phase_stat_basics
    ds=generate_random_phase_dataset(40+randint(),'small');
    nsamples=size(ds.samples,1);

    methods={'param','nonparam_nan','nonparam',''};
    outputs={'pbi','pos','pop'};

    for k=1:numel(outputs)
        method=methods{k};
        for j=1:numel(outputs)
            output=outputs{j};

            opt=struct();
            opt.niter=randint();
            opt.progress=false;

            opt.permuter_func=@(iter) deterministic_permute(nsamples,...
                                                        opt.niter,iter);
            opt.output=output;
            opt.seed=randint();

            is_parametric=false;
            extreme_tail_is_nan=true;
            switch method
                case 'param'
                    opt.zscore='parametric';
                    is_parametric=true;

                case 'nonparam_nan'
                    opt.zscore='non_parametric';

                case 'nonparam'
                    opt.extreme_tail_set_nan=false;
                    extreme_tail_is_nan=false;

                case ''
                    % deafults,ok

                otherwise
                    assert(false);
            end

            expected_samples=compute_expected_samples(ds,output,...
                                        opt.niter,opt.permuter_func,...
                                        is_parametric,...
                                        extreme_tail_is_nan);
            result=cosmo_montecarlo_phase_stat(ds,opt);

            assertElementsAlmostEqual(expected_samples,result.samples,...
                                            'absolute',1e-5);
        end
    end




function test_random_data_nonparam_uniformity
% when getting phase stats for random data, z-scores must follow some sort
% of z-like distribution
    ds=generate_random_phase_dataset(40+randint(),'big');
    nsamples=size(ds.samples,1);

    methods={'nonparam_nan','nonparam',''};
    outputs={'pbi','pos','pop'};
    for k=1:numel(outputs)
        method=methods{k};
        for j=1:numel(outputs)
            output=outputs{j};

            opt=struct();
            opt.niter=50+randint();
            opt.output=output;
            opt.seed=[];
            opt.permuter_func=@(unused)nondeterministic_permute(nsamples);
            opt.progress=false;

            if ~isempty(method)
                opt.zscore='non_parametric';
                opt.extreme_tail_set_nan=~strcmp(method,'nonparam');
            end


            stat_ds=cosmo_montecarlo_phase_stat(ds,opt);
            samples=stat_ds.samples;
            nan_msk=isnan(samples);
            assert(mean(nan_msk)<.2); % not too many nans

            z_sorted=sort(samples(~nan_msk));
            n_z=numel(z_sorted);

            p_uniform=(.5:n_z)/n_z;
            z_uniform=cosmo_norminv(p_uniform);

            r2=var(z_sorted);
            r2_resid=var(z_sorted-z_uniform);
            F=r2/r2_resid;
            assert(F>10);
        end
    end

function ds=generate_random_phase_dataset(nsamples_per_class,size_str)
    ds=cosmo_synthetic_dataset('ntargets',2,...
                                    'nchunks',nsamples_per_class,...
                                    'size',size_str,...
                                    'seed',0);
    sz=size(ds.samples);
    ds.samples=randn(sz)+1i*randn(sz);
    ds.sa.chunks(:)=1:sz(1);


function samples=compute_expected_samples(ds,output,...
                                        niter,permuter_func,...
                                        is_parametric,...
                                        extreme_tail_is_nan)

    stat_orig=cosmo_phase_stat(ds,'output',output);
    [nsamples,nfeatures]=size(ds.samples);

    stat_null_cell=cell(niter,1);
    for iter=1:niter
        rp=permuter_func(iter);
        ds_null=ds;
        ds_null.sa.targets=ds.sa.targets(rp);
        stat=cosmo_phase_stat(ds_null,'output',output);
        stat_null_cell{iter}=stat;
    end

    stat_null=cosmo_stack(stat_null_cell);

    if is_parametric
        mu=mean(stat_null.samples,1);
        sd=std(stat_null.samples,[],1);

        samples=(stat_orig.samples-mu)./sd;
    else
        count_gt=sum(bsxfun(@gt,stat_orig.samples,stat_null.samples),1);
        count_lt=sum(bsxfun(@lt,stat_orig.samples,stat_null.samples),1);

        msk_gt=count_gt>niter/2;
        msk_lt=count_lt>niter/2;

        p=zeros(1,nfeatures)+.5;
        p(msk_gt)=count_gt(msk_gt)/(1+niter);
        p(msk_lt)=1-count_lt(msk_lt)/(1+niter);

        min_p=1/(1+niter)+1e-10;

        assert(all(p>=min_p-2e-10));
        assert(all((1-p)>=(min_p-2e-10)));

        if extreme_tail_is_nan
            p(count_gt==niter | count_lt==niter)=NaN;
        end

        samples=cosmo_norminv(p);
    end


function func=get_determistic_permute_func(ntargets,niter)
    func=@(iter) deterministic_permute(ntargets,niter,iter);

function targets_idxs=deterministic_permute(ntargets,niter,iter)
    persistent cached_rand_vec;
    persistent cached_args;

    args={ntargets,niter};

    if ~isequal(args,cached_args)
        cached_rand_vec=cosmo_rand(ntargets,1,'seed',ntargets*niter);

        cached_args=args;
    end

    rand_vals=cached_rand_vec+iter/niter;
    msk=rand_vals>1;
    rand_vals(msk)=rand_vals(msk)-1;

    [unused,targets_idxs]=sort(rand_vals,1);

function target_idxs=nondeterministic_permute(ntargets)
    rand_vals=randn(ntargets,1);
    [unused,target_idxs]=sort(rand_vals);



function test_monte_carlo_phase_stat_seed
    ds=generate_random_phase_dataset(20,'tiny');

    opt=struct();
    opt.niter=10+randint();
    opt.output='pbi';
    opt.progress=false;


    % different results with empty seeed
    opt.seed=[];
    r1=cosmo_montecarlo_phase_stat(ds,opt);
    attempt=10;
    while attempt>0
        attempt=attempt-1;
        assert(attempt>0,'results are always the same');
        r2=cosmo_montecarlo_phase_stat(ds,opt);
        if ~isequal(r1.samples,r2.samples)
            break;
        end
    end

    % fixed seed, same result
    opt.seed=randint();
    r1=cosmo_montecarlo_phase_stat(ds,opt);
    r2=cosmo_montecarlo_phase_stat(ds,opt);
    assertElementsAlmostEqual(r1.samples,r2.samples);

    % different seed, different result
    attempt=10;
    while attempt>0
        opt.seed=opt.seed+1;
        attempt=attempt-1;
        assert(attempt>0,'results are always the same');
        r2=cosmo_montecarlo_phase_stat(ds,opt);
        if ~isequal(r1.samples,r2.samples)
            break;
        end
    end




function test_montecarlo_phase_stat_exceptions()
    func=@cosmo_montecarlo_phase_stat;
    aet=@(x,varargin)assertExceptionThrown(@()...
                func(x,varargin{:}),'');
    extra_args=cosmo_structjoin({'progress',false,...
                                'niter',3,...
                                'output','pbi'});
    aet_arg=@(x,varargin)aet(x,extra_args,varargin{:});

    % valid
    ds=generate_random_phase_dataset(5,'tiny');
    func(ds,extra_args); % ok

    % unbalanced targets
    bad_ds=ds;
    i=find(ds.sa.targets==2,1,'first');
    bad_ds.sa.targets(i)=1;
    aet_arg(bad_ds);

    % invalid output
    aet_arg(ds,'output','foo');

    % valid zscore
    func(ds,extra_args,'zscore','parametric');
    func(ds,extra_args,'zscore','non_parametric');

    % invalid zscore
    aet_arg(ds,'zscore','nonparametric');
    aet_arg(ds,'zscore','foo');

    % invalid niter
    aet_arg(ds,'niter',.3);
    aet_arg(ds,'niter',-3);
    aet_arg(ds,'niter',[2 2]);
    aet_arg(ds,'niter','f');


    % valid output
    func(ds,extra_args,'output','pbi');
    func(ds,extra_args,'output','pos');
    func(ds,extra_args,'output','pop');

    % invalid output
    aet_arg(ds,'output','foo');
    aet_arg(ds,'output',2);

    % missing fields
    aet(ds,rmfield(extra_args,'niter'));
    aet(ds,rmfield(extra_args,'output'));

    % valid extreme_tail_set_nan
    func(ds,extra_args,'extreme_tail_set_nan',true);
    func(ds,extra_args,'extreme_tail_set_nan',false);

    % invalid func(ds,extra_args,'extreme_tail_set_nan',true);
    aet(ds,extra_args,'extreme_tail_set_nan',2);
    aet(ds,extra_args,'extreme_tail_set_nan','foo');

function test_unit_length_exception
    ds=cosmo_synthetic_dataset('nchunks',10);
    sample_size=size(ds.samples);
    ds.sa.chunks(:)=1:sample_size(1);

    rand_func=single(randn(sample_size));

    ds.samples=rand_func() + 1i*rand_func();

    opt=struct();
    opt.output='pos';
    opt.niter=100;
    opt.progress=false;

    % should not raise an exception
    cosmo_montecarlo_phase_stat(ds,opt);
