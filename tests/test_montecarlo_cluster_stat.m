function test_suite=test_montecarlo_cluster_stat
% tests for cosmo_montecarlo_cluster_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_onesample_ttest_montecarlo_cluster_extremes
    ds=cosmo_synthetic_dataset('ntargets',1,...
                                'nchunks',10,...
                                'size','normal');
    nh=cosmo_cluster_neighborhood(ds,'progress',false);

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


    for signal_sign=[-1 1]
        magnitude=10;
        ds_pos=ds;
        ds_pos.samples=ds_pos.samples+signal_sign*magnitude;

        niter=10+ceil(rand()*(numel(z_lookup)-10));
        opt.niter=niter;
        opt.h0_mean=0;
        opt.progress=false;
        z_ds=cosmo_montecarlo_cluster_stat(ds_pos,nh,opt);

        z_expected=signal_sign*z_lookup(niter);

        nfeatures=size(ds.samples,2);
        assertElementsAlmostEqual(z_ds.samples,...
                            z_expected+zeros(1,nfeatures),...
                            'absolute',1e-4);
    end



function test_onesample_ttest_montecarlo_cluster_stat
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_montecarlo_cluster_stat(varargin{:}),'');


    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',6);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    opt=struct();
    opt.niter=10;
    opt.h0_mean=0;
    opt.seed=7;
    opt.progress=false;
    z_ds1=cosmo_montecarlo_cluster_stat(ds,nh1,opt);

    assertElementsAlmostEqual(z_ds1.samples,...
                    [1.2816 0 1.2816 -0.84162 1.2816 0],...
                    'absolute',1e-4);

    % different h0_mean
    opt.h0_mean=1.2;
    nh2=cosmo_cluster_neighborhood(ds,'progress',false,'fmri',1);
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds2.samples,...
                [0 -1.2816 1.2816 -1.2816 0.5244 -1.2816],...
                'absolute',1e-4);

    opt.dh=1.1;
    z_ds3=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds3.samples,...
                [0 -1.2816 0 -0.84162 0 -0.84162],...
                'absolute',1e-4);


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
                [0.84162 1.2816 0 0.84162 0.84162 0],...
                'absolute',1e-4);


    opt.h0_mean=2;
    z_ds5=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds5.samples,...
                [-0.25335 -0.25335 0 -0.25335 -0.5244 1.2816],...
                'absolute',1e-4);

    opt=rmfield(opt,'h0_mean');
    aet(ds,nh2,opt);

    % lots of signal, should work with no seed specified
    opt=struct();
    opt.h0_mean=-15;
    opt.progress=false;
    opt.niter=14;
    z_ds6=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds6.samples,...
                        repmat(1.4652,1,6),...
                        'absolute',1e-4);

function test_twosample_ttest_montecarlo_cluster_stat
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_montecarlo_cluster_stat(varargin{:}),'');

    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',6,'sigma',2);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    % test within-subjects
    opt=struct();
    opt.niter=10;
    opt.seed=1;
    opt.progress=false;
    z_ds1=cosmo_montecarlo_cluster_stat(ds,nh1,opt);

    assertElementsAlmostEqual(z_ds1.samples,...
                    [0.5244 -1.2816 0 0.84162 -0.5244 -0.84162],...
                    'absolute',1e-4);
    opt.cluster_stat='maxsum';
    opt.p_uncorrected=0.35;
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh1,opt);

    assertElementsAlmostEqual(z_ds2.samples,...
                    [0.5244 -1.2816 0 0.5244 -1.2816 -0.84162],...
                    'absolute',1e-4);

    % test between-subjects
    ds.sa.chunks=ds.sa.chunks*2+ds.sa.targets;
    opt=struct();
    opt.niter=10;
    opt.seed=1;
    opt.progress=false;
    z_ds3=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds3.samples,...
                    [-0.84162 -1.2816 0 -0.25335 -1.2816 -1.2816],...
                    'absolute',1e-4);

    % lots of signal, should work with no seed specified
    opt=struct();
    opt.niter=15;
    opt.progress=false;
    msk1=ds.sa.targets==1;
    ds.samples(msk1,:)=ds.samples(msk1,:)+10;
    z_ds3=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds3.samples,...
                    repmat(1.5011,1,6),...
                    'absolute',1e-4);

    opt.cluster_stat='foo';
    aet(ds,nh1,opt);

    opt=rmfield(opt,'cluster_stat');
    opt.h0_mean=3;
    aet(ds,nh1,opt);

    %%

function test_anova_montecarlo_cluster_stat
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_montecarlo_cluster_stat(varargin{:}),'');

    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',6,'sigma',2);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    % test within-subjects
    opt=struct();
    opt.niter=10;
    opt.seed=1;
    opt.progress=false;
    z_ds1=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds1.samples,...
                    [1.2816 -0.25335 0 0 1.2816 -0.84162],...
                    'absolute',1e-4);

    % test between-subjects
    ds.sa.chunks=ds.sa.chunks*3+ds.sa.targets;
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds2.samples,...
                    [1.2816 0.84162 1.2816 -0.84162 1.2816 0.5244],...
                    'absolute',1e-4);

    % unbalanced design
    ds.sa.chunks(1)=5;
    aet(ds,nh1,opt);



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
                    [0 -1.2816 0.5244 0 -0.5244 0],...
                    'absolute',1e-4);

    opt.h0_mean=0.5;
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds2.samples,...
                    [0 -0.25335 1.2816 0 1.2816 0],...
                    'absolute',1e-4);


    opt=rmfield(opt,'seed');
    for k=1:numel(opt.null)
        opt.null{k}.samples=opt.null{k}.samples-10;
    end
    opt.h0_mean=-10;
    z_ds3=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds3.samples,...
                    repmat(1.2816,1,6),...
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

    expected_samples=[-0.84162 0.25335 0 0 0.25335 0];
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

