function test_suite=test_montecarlo_cluster_stat
% tests for cosmo_montecarlo_cluster_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_onesample_ttest_montecarlo_cluster_extremes
    ds=cosmo_synthetic_dataset('ntargets',1,...
                                'nchunks',20,...
                                'size','normal');
    nh=cosmo_cluster_neighborhood(ds,'progress',false);

    z_lookup=get_zscore_lookup_table();

    for repeat=1:5
        for signal_sign=[-1 1]
            magnitude=10;
            ds_pos=ds;
            ds_pos.samples=randn(size(ds.samples))+signal_sign*magnitude;

            niter=10+ceil(rand()*(numel(z_lookup)-11));
            opt.niter=niter;
            opt.h0_mean=0;
            opt.dh=.25;
            opt.progress=false;
            z_ds=cosmo_montecarlo_cluster_stat(ds_pos,nh,opt);

            z_expected=signal_sign*z_lookup(niter+1);

            nfeatures=size(ds.samples,2);
            assertElementsAlmostEqual(z_ds.samples,...
                                z_expected+zeros(1,nfeatures),...
                                'absolute',1e-4);


        end
    end

function z_lookup=get_zscore_lookup_table()
    % table generated using
    %     niter=1:40; fprintf('%.4f %.4f %.4f %.4f %.4f ...\n',...
    %                       norminv(1-1./niter))
    % but without need for presence of norminv
    z_lookup=[    -Inf 0.0000 0.4307 0.6745 0.8416 ...
                0.9674 1.0676 1.1503 1.2206 1.2816 ...
                1.3352 1.3830 1.4261 1.4652 1.5011 ...
                1.5341 1.5647 1.5932 1.6199 1.6449 ...
                1.6684 1.6906 1.7117 1.7317 1.7507 ...
                1.7688 1.7862 1.8027 1.8186 1.8339 ...
                1.8486 1.8627 1.8764 1.8895 1.9022 ...
                1.9145 1.9264 1.9379 1.9491 1.9600 ...
                ];


function test_onesample_ttest_mccs_left_tail
    helper_test_mccs_with_tail(true,false);

function test_onesample_ttest_mccs_right_tail
    helper_test_mccs_with_tail(false,true);

function test_onesample_ttest_mccs_both_tail
    helper_test_mccs_with_tail(true,true);

function test_onesample_ttest_mccs_no_tail
    helper_test_mccs_with_tail(false,false);


function helper_test_mccs_with_tail(left_tail,right_tail)
    nchunks=ceil(rand()*5)+20;
    ds=cosmo_synthetic_dataset('size','big',...
                                'nchunks',nchunks,...
                                'ntargets',1);
    ds=cosmo_slice(ds,ds.fa.i<8,2);
    ds=cosmo_dim_prune(ds);

    nfeatures=size(ds.samples,2);

    % generate some effect for some of the features. Here we generate data
    % where about 1/3rd of the features may show an effect in the left tail
    % (less than 0), and 1/3rd of the features may show an effect in the
    % right tail (greater than 0).
    ratio_effect=1/3;
    nfeatures_effect=ceil(nfeatures*ratio_effect);

    z_table=get_zscore_lookup_table();


    [unused,rp]=sort(rand(1,nfeatures));
    ds.samples=randn(nchunks,nfeatures);

    sigma=4/sqrt(nchunks);

    % add effect below zero
    if left_tail
        neg_idx=rp(nfeatures_effect+(1:nfeatures_effect));
        ds.samples(:,neg_idx)=ds.samples(:,neg_idx)-sigma;
    end

    % add effect above zero
    if right_tail
        pos_idx=rp(1:nfeatures_effect);
        ds.samples(:,pos_idx)=ds.samples(:,pos_idx)+sigma;
    end

    % run TFCE
    nh=cosmo_cluster_neighborhood(ds,'progress',false);
    opt=struct();
    opt.niter=ceil(rand()*10+10);
    opt.h0_mean=0;
    opt.dh=1; % make it faster
    opt.progress=false;
    z=cosmo_montecarlo_cluster_stat(ds,nh,opt);

    % check sign of output of each feature
    t=cosmo_stat(ds,'t');

    for tail_sign=[-1,1]
        % everywhere where z is positive [negative], the
        % corresponding t value must also be positive [negative]
        z_msk=z.samples*tail_sign>0;
        t_msk=t.samples*tail_sign>0;
        assertTrue(all(t_msk(z_msk)));
    end

    % see how many significant effects found
    tiny=1e-4;
    for tail_sign=[-1,1]
        has_effect=(tail_sign==-1 && left_tail) || ...
                        (tail_sign==1 && right_tail);

        if has_effect
            % quite a lof of features should show an effect
            minimum_tail_ratio=.1;
            maximum_tail_ratio=.5;
        else
            % very few features should show an effect
            minimum_tail_ratio=0;
            maximum_tail_ratio=.1;
        end

        expected_extreme_z=tail_sign*z_table(opt.niter+1);
        if has_effect
            extreme_z=max(z.samples*tail_sign)*tail_sign;
            assertElementsAlmostEqual(extreme_z,...
                                expected_extreme_z,...
                                'absolute',tiny);
        end

        % deal with rounding
        extreme_ratio=mean(abs(z.samples-expected_extreme_z)<tiny);
        assertTrue(extreme_ratio>=minimum_tail_ratio);
        assertTrue(extreme_ratio<=maximum_tail_ratio);
    end

    % count number of features without an effect
    median_zero_ratio=1-2*ratio_effect;
    if ~left_tail
        median_zero_ratio=median_zero_ratio+ratio_effect;
    end
    if ~right_tail
        median_zero_ratio=median_zero_ratio+ratio_effect;
    end

    if left_tail && right_tail
        % allow for more non-results
        margin=1/4;
    else
        margin=1/6;
    end

    minimum_zero_ratio=median_zero_ratio-margin;
    maximum_zero_ratio=median_zero_ratio+margin;

    zero_ratio=mean(abs(z.samples)<tiny);
    assertTrue(zero_ratio>=minimum_zero_ratio);
    assertTrue(zero_ratio<=maximum_zero_ratio);



function test_onesample_ttest_montecarlo_cluster_stat_basics
    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',6);
    nh=cosmo_cluster_neighborhood(ds,'progress',false);

    opt=struct();
    opt.niter=9;
    opt.h0_mean=0;
    opt.seed=7;
    opt.progress=false;
    z=cosmo_montecarlo_cluster_stat(ds,nh,opt);

    assertElementsAlmostEqual(z.samples,...
                    [0.8416 0 1.2816 0 1.2816 0],...
                    'absolute',1e-4);

function test_onesample_ttest_montecarlo_cluster_stat_other_mean
    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',6);
    nh=cosmo_cluster_neighborhood(ds,'progress',false,'fmri',1);

    % different h0_mean
    opt=struct();
    opt.niter=9;
    opt.seed=7;
    opt.progress=false;
    opt.h0_mean=1.2;

    z=cosmo_montecarlo_cluster_stat(ds,nh,opt);
    assertElementsAlmostEqual(z.samples,...
                [0 -1.2816 1.2816 -1.2816 0.25335 -1.2816],...
                'absolute',1e-4);

function test_onesample_ttest_montecarlo_cluster_stat_other_dh
    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',6);
    nh=cosmo_cluster_neighborhood(ds,'progress',false,'fmri',1);

    opt=struct();
    opt.niter=9;
    opt.h0_mean=1.2;
    opt.seed=7;
    opt.progress=false;
    opt.dh=1.1;


    z=cosmo_montecarlo_cluster_stat(ds,nh,opt);
    assertElementsAlmostEqual(z.samples,...
                [0 -1.2816 0 -0.5244 0 -0.5244],...
                'absolute',1e-4);

function test_onesample_ttest_montecarlo_cluster_stat_exceptions
    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',6);
    nh2=cosmo_cluster_neighborhood(ds,'progress',false,'fmri',1);

    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_montecarlo_cluster_stat(varargin{:}),'');

    opt=struct();
    opt.niter=9;
    opt.h0_mean=1.2;
    opt.seed=7;
    opt.progress=false;
    opt.dh=1.1;

    opt.cluster_stat='maxsize';
    aet(ds,nh2,opt);
    opt=rmfield(opt,'dh');
    aet(ds,nh2,opt);
    opt.p_uncorrected=.55;
    aet(ds,nh2,opt);
    opt.p_uncorrected=.4;
    opt.h0_mean=0;
    z_ds4=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds4.samples,...
                [0.5244 0 0 0.5244 0.5244 0],...
                'absolute',1e-4);


    opt.h0_mean=2;
    z_ds5=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds5.samples,...
                [-0.25335 -0.25335 0 -0.25335 0 0],...
                'absolute',1e-4);

    opt=rmfield(opt,'h0_mean');
    aet(ds,nh2,opt);


function test_onesample_ttest_montecarlo_cluster_stat_strong
    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',12);
    nh=cosmo_cluster_neighborhood(ds,'progress',false,'fmri',1);

    % lots of signal, should work with no seed specified

    for effect_sign=[-1,1]
        niter=ceil(rand()*10+10);
        z_table=get_zscore_lookup_table();
        expected_z=z_table(niter+1);

        opt=struct();
        opt.h0_mean=(-effect_sign)*15;
        opt.progress=false;
        opt.niter=niter;
        z=cosmo_montecarlo_cluster_stat(ds,nh,opt);
        assertElementsAlmostEqual(z.samples,...
                            repmat(effect_sign*expected_z,1,6),...
                            'absolute',1e-4);
    end


function test_twosample_ttest_montecarlo_cluster_stat_basics
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_montecarlo_cluster_stat(varargin{:}),'');

    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',6,'sigma',2);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    % test within-subjects
    opt=struct();
    opt.niter=9;
    opt.seed=1;
    opt.progress=false;

    z=cosmo_montecarlo_cluster_stat(ds,nh1,opt);

    assertElementsAlmostEqual(z.samples,...
                    [0.5244 -1.2816 0 0.84162 -0.25335 0],...
                     'absolute',1e-4);




function test_twosample_ttest_montecarlo_cluster_stat_ws
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',6,'sigma',2);
    nh=cosmo_cluster_neighborhood(ds,'progress',false);

    % test within-subjects
    opt=struct();
    opt.niter=9;
    opt.seed=1;
    opt.progress=false;
    opt.cluster_stat='maxsum';
    opt.p_uncorrected=0.35;

    z=cosmo_montecarlo_cluster_stat(ds,nh,opt);

    assertElementsAlmostEqual(z.samples,...
                    [0.5244 -1.2816 0 0.5244 -1.2816 0],...
                    'absolute',1e-4);


function test_twosample_ttest_montecarlo_cluster_stat_bs

    % test between-subjects
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',6,'sigma',2);
    nh=cosmo_cluster_neighborhood(ds,'progress',false);
    ds.sa.chunks=ds.sa.chunks*2+ds.sa.targets;

    opt=struct();
    opt.niter=9;
    opt.seed=1;
    opt.progress=false;
    z=cosmo_montecarlo_cluster_stat(ds,nh,opt);
    assertElementsAlmostEqual(z.samples,...
                    [0 -1.2816 0 0 -1.2816 0],...
                    'absolute',1e-4);


function test_twosample_ttest_montecarlo_cluster_stat_strong

    % test between-subjects
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',6,'sigma',2);
    nh=cosmo_cluster_neighborhood(ds,'progress',false);
    ds.sa.chunks=ds.sa.chunks*2+ds.sa.targets;

    % lots of signal, should work with no seed specified
    opt=struct();
    opt.niter=14;
    opt.progress=false;
    msk1=ds.sa.targets==1;
    ds.samples(msk1,:)=ds.samples(msk1,:)+10;
    z=cosmo_montecarlo_cluster_stat(ds,nh,opt);
    assertElementsAlmostEqual(z.samples,...
                    repmat(1.5011,1,6),...
                    'absolute',1e-4);

function test_twosample_ttest_montecarlo_cluster_stat_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_montecarlo_cluster_stat(varargin{:}),'');

    % test between-subjects
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',6,'sigma',2);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);
    opt.cluster_stat='foo';
    aet(ds,nh1,opt);

    opt=rmfield(opt,'cluster_stat');
    opt.h0_mean=3;
    aet(ds,nh1,opt);


function test_anova_montecarlo_cluster_stat_ws
    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',6,'sigma',2);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    % test within-subjects
    opt=struct();
    opt.niter=9;
    opt.seed=1;
    opt.progress=false;
    z_ds1=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds1.samples,...
                   [1.2816 0 0 0 0.84162 0],...
                    'absolute',1e-4);


function test_anova_montecarlo_cluster_stat_bs
    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',6,'sigma',2);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    % test within-subjects
    opt=struct();
    opt.niter=9;
    opt.seed=1;
    opt.progress=false;

    % test between-subjects
    ds.sa.chunks=ds.sa.chunks*3+ds.sa.targets;
    z=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z.samples,...
                    [1.2816 0.84162 0 0 1.2816 0.5244],...
                    'absolute',1e-4);



function test_anova_montecarlo_cluster_stat_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_montecarlo_cluster_stat(varargin{:}),'');

    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',6,'sigma',2);
    nh=cosmo_cluster_neighborhood(ds,'progress',false);
    opt=struct();
    opt.niter=9;
    opt.seed=1;
    opt.progress=false;

    % unbalanced design
    ds.sa.chunks(1)=5;
    aet(ds,nh,opt);

function test_null_data_montecarlo_cluster_stat
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_montecarlo_cluster_stat(varargin{:}),'');

    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',6,'sigma',2);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    n_null=5;
    null_ds_cell=cell(1,n_null);
    for k=1:n_null
        w=k/n_null;
        null_ds=ds;
        prm=mod(k+(1:6),6)+1;
        null_ds.samples=(w*ds.samples(:,prm)+(1-w)*ds.samples(prm,:)')/2;
        null_ds_cell{k}=cosmo_slice(null_ds,prm,1,false);
    end

    opt=struct();
    aet(ds,nh1,opt);

    opt.h0_mean=0;
    aet(ds,nh1,opt);

    opt.niter=10;
    opt.progress=false;

    opt.null=ds;
    aet(ds,nh1,opt);

    wrong_ds=cosmo_stack({ds,ds});

    opt.null=wrong_ds;
    aet(ds,nh1,opt);

    % different targets
    opt.null=null_ds_cell;
    opt.null{end}.sa.targets(:)=0;
    aet(ds,nh1,opt);

    % no dataset
    opt.null=null_ds_cell;
    opt.null{end}=struct();
    aet(ds,nh1,opt);

    % sample size mismatch
    opt.null=null_ds_cell;
    opt.null{end}=cosmo_stack(opt.null([end end]));
    aet(ds,nh1,opt);

    % .fa mismatch
    opt.null=null_ds_cell;
    opt.null{end}.fa.i=opt.null{end}.fa.i(end:-1:1);
    aet(ds,nh1,opt);

    % missing .sa.targets
    opt.null=null_ds_cell;
    opt.null{end}.sa=rmfield(opt.null{end}.sa,'targets');
    aet(ds,nh1,opt);

    % .sa.chunks mismatch
    opt.null=null_ds_cell;
    opt.null{end}.sa.chunks=opt.null{end}.sa.chunks+1;
    aet(ds,nh1,opt);

    % no feature_sizes
    opt.null=null_ds_cell;
    nh_bad=nh1;
    nh_bad.fa=rmfield(nh_bad.fa,'sizes');
    aet(ds,nh_bad,opt);


    % check with standard datasets
    opt.null=null_ds_cell;
    opt.seed=1;
    opt.h0_mean=0;
    z_ds1=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds1.samples,...
                    [0 -0.90846 0.34876 0 0 0],...
                    'absolute',1e-4);

    opt.h0_mean=0.5;
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds2.samples,...
                    [0 -0.11419 1.3352 0 1.3352 0],...
                    'absolute',1e-4);


    opt=rmfield(opt,'seed');
    for k=1:numel(opt.null)
        opt.null{k}.samples=opt.null{k}.samples-10;
    end
    opt.h0_mean=-10;
    z_ds3=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds3.samples,...
                    repmat(1.3352,1,6),...
                    'absolute',1e-4);



function test_feature_stat_montecarlo_cluster_stat
    % when using 'feature_stat','none':
    % - size(ds.samples,1) must be 1
    % - the option 'null' must be provided
    % - the option 'niter' must be 0
    % - h0_mean is required (but can be zero)

    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_montecarlo_cluster_stat(varargin{:}),'');

    opt=cosmo_structjoin({'niter',10,...
                                    'h0_mean',0,...
                                    'progress',false,...
                                    'seed',1,...
                                    'cluster_stat','tfce',...
                                    'dh',.1});
    ds6=cosmo_synthetic_dataset('ntargets',1,'nchunks',6);
    nh=cosmo_cluster_neighborhood(ds6,'progress',false);

    % using default for 'feature_stat' option gives same output as 'auto'
    res1=cosmo_montecarlo_cluster_stat(ds6,nh,opt,...
                            'feature_stat','auto');
    res2=cosmo_montecarlo_cluster_stat(ds6,nh,opt);
    assertEqual(res1,res2);

    % get dataset with single sample
    ds1=cosmo_slice(ds6,1);

    % crash with illegal inputs
    aet(ds1,nh,opt,'feature_stat','foo');
    aet(ds1,nh,opt,'feature_stat',1);
    aet(ds1,nh,opt,'feature_stat',false);



    % cannot have 'niter' option, even with 'null' option
    n_null=10;
    null_cell=arrayfun(@(x)cosmo_synthetic_dataset('ntargets',1,...
                                                 'nchunks',1',...
                                                 'seed',x),...
                     1:n_null,...
                     'UniformOutput',false);



    opt.feature_stat='none';
    aet(ds1,nh,opt,'null',null_cell);
    opt=rmfield(opt,'niter');

    % cannot be without 'null' option
    aet(ds1,opt);

    opt.null=null_cell;

    % error when using more than one sample
    aet(ds6,nh,opt);

    % when using default TFCE, dh must be provided
    opt_no_dh=rmfield(opt,'dh');
    aet(ds1,nh,opt_no_dh);

    % simple regression test
    res=cosmo_montecarlo_cluster_stat(ds1,nh,opt);

    expected_samples=[0 0 0 0 0.11419 0];
    assertElementsAlmostEqual(res.samples,expected_samples,...
                                'absolute',1e-4)
    assertEqual(res.fa,ds1.fa);
    assertEqual(res.a,ds1.a);

    % should also work when no .sa present, or no .sa.targets
    ds_no_sa=rmfield(ds1,'sa');
    res_no_sa=cosmo_montecarlo_cluster_stat(ds_no_sa,nh,opt);
    assertElementsAlmostEqual(res_no_sa.samples,res.samples);

    ds_no_targets=ds1;
    ds_no_targets.sa=rmfield(ds_no_targets.sa,'targets');
    res_no_targets=cosmo_montecarlo_cluster_stat(ds_no_targets,nh,opt);
    assertElementsAlmostEqual(res_no_targets.samples,res.samples);


    % h0_mean should work
    c=8+rand();
    null_cell_const=null_cell;
    for k=1:numel(null_cell_const)
        null_cell_const{k}.samples=null_cell_const{k}.samples+c;
    end

    ds1_const=ds1;
    ds1_const.samples=ds1_const.samples+c;


    opt.h0_mean=c;
    opt.null=null_cell_const;

    res_const=cosmo_montecarlo_cluster_stat(ds1_const,nh,opt);
    assertElementsAlmostEqual(res_const.samples,res.samples,...
                                'absolute',1e-4);
    assertEqual(res.fa,res_const.fa);
    assertEqual(res.a,res_const.a);




function test_montecarlo_cluster_stat_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_montecarlo_cluster_stat(varargin{:}),'');
    % dh not allowed with non-tfce cluster stat
    ds=cosmo_synthetic_dataset();
    nh=cosmo_cluster_neighborhood(ds,'progress',false);

    opt=struct();
    opt.progress=false;
    opt.niter=10;

    % cannot have dh with non-tfce cluster stat
    aet(ds,nh,opt,'cluster_stat','maxsize','p_uncorrected',.01,'dh',.1);

    % cannot have p_uncorreced with tfce cluster stat
    aet(ds,nh,opt,'p_uncorrected',.01);
    aet(ds,nh,opt,'p_uncorrected',.01,'cluster_stat','tfce');

    % when using feature_stat none, the null option is required
    ds1=cosmo_slice(ds,1);
    aet(ds1,nh,'feature_stat','none','dh',.01,'h0_mean',0)



function test_montecarlo_cluster_stat_default_dh
    ds=cosmo_synthetic_dataset('size','normal',...
                                'ntargets',1,'nchunks',15);
    ds.samples=randn(size(ds.samples))+.5;
    nh=cosmo_cluster_neighborhood(ds,'progress',false);

    opt=struct();
    opt.progress=false;
    opt.h0_mean=0;

    % make output detereministic over multiple runs
    opt.niter=ceil(rand()*5+15);
    opt.seed=ceil(rand()*100+1);


    % default value of dh should give identical result
    res_no_dh=cosmo_montecarlo_cluster_stat(ds,nh,opt);
    res_dh_naught_one=cosmo_montecarlo_cluster_stat(ds,nh,opt,'dh',.1);
    assertEqual(res_no_dh,res_dh_naught_one);

    % different dh value should (almost always) give different result
    res_dh_naught_five=cosmo_montecarlo_cluster_stat(ds,nh,opt,'dh',.5);
    assertFalse(isequal(res_no_dh.samples,res_dh_naught_five.samples));

    min_corr=.7;
    assertTrue(corr(res_dh_naught_one.samples(:),...
                        res_dh_naught_five.samples(:))>min_corr);

function test_montecarlo_cluster_stat_tiny_niter_singlethread
    helper_test_tiny_niter_with_nproc(1);

function test_montecarlo_cluster_stat_tiny_niter_multithread
    if cosmo_parallel_get_nproc_available()<=1
        cosmo_notify_test_skipped('No parallel toolbox available');
        return;
    end

    helper_test_tiny_niter_with_nproc(2);

function helper_test_tiny_niter_with_nproc(nproc)

    ds=cosmo_synthetic_dataset('size','normal',...
                                'ntargets',1,'nchunks',15);
    nh=cosmo_cluster_neighborhood(ds,'progress',false);
    opt=struct();
    opt.progress=false;
    opt.h0_mean=0;

    % single iteration
    opt.niter=1;

    % set nproc
    opt.nproc=nproc;

    % should not raise an error
    cosmo_montecarlo_cluster_stat(ds,nh,opt);




