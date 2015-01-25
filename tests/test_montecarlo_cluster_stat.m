function test_suite=test_montecarlo_cluster_stat
    initTestSuite;

function test_onesample_ttest_montecarlo_cluster_stat

    ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',6);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    opt=struct();
    opt.niter=10;
    opt.h0_mean=0;
    opt.seed=7;
    opt.progress=false;
    z_ds1=cosmo_montecarlo_cluster_stat(ds,nh1,opt);

    assertElementsAlmostEqual(z_ds1.samples,...
                    [1.28155 -0.67449 1.28155 0.25335 1.28155 0],...
                    'absolute',1e-4);
    %
    opt.h0_mean=1.5;
    nh2=cosmo_cluster_neighborhood(ds,'progress',false,'fmri',1);
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds2.samples,...
                [-0.12566 -1.28155 0.67449 -1.28155 0.67449 -1.28155],...
                'absolute',1e-4);

    opt.dh=1.1;
    z_ds3=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds3.samples,...
                [0 -1.28155 0 -1.03643 0 -1.28155 ],...
                'absolute',1e-4);


    opt.cluster_stat='maxsize';
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh2,opt),'');
    opt=rmfield(opt,'dh');
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh2,opt),'');
    opt.p_uncorrected=.55;
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh2,opt),'');
    opt.p_uncorrected=.4;
    opt.h0_mean=0;
    z_ds4=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds4.samples,...
                [1.28155 -0.12566 0 1.28155 1.28155 0],...
                'absolute',1e-4);


    opt.h0_mean=2;
    z_ds5=cosmo_montecarlo_cluster_stat(ds,nh2,opt);
    assertElementsAlmostEqual(z_ds5.samples,...
                [-0.84162 -0.84162 0 -0.84162 0.38532 -0.12566 ],...
                'absolute',1e-4);

    opt=rmfield(opt,'h0_mean');
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh2,opt),'');

function test_twosample_ttest_montecarlo_cluster_stat
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',6,'sigma',2);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    opt=struct();
    opt.niter=10;
    opt.seed=1;
    opt.progress=false;
    z_ds1=cosmo_montecarlo_cluster_stat(ds,nh1,opt);

    assertElementsAlmostEqual(z_ds1.samples,...
                    [1.03643 -1.28155 0 1.28155 -1.03643 0.25335],...
                    'absolute',1e-4);
    opt.cluster_stat='maxsum';
    opt.p_uncorrected=0.35;
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh1,opt);

    assertElementsAlmostEqual(z_ds2.samples,...
                    [1.03643 -1.28155 0 1.03643 -1.28155 0.25335],...
                    'absolute',1e-4);


    opt.cluster_stat='foo';
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh1,opt),'');
    opt=rmfield(opt,'cluster_stat');

    opt.h0_mean=3;
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh1,opt),'');

    %%

function test_anova_montecarlo_cluster_stat
    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',6,'sigma',2);
    nh1=cosmo_cluster_neighborhood(ds,'progress',false);

    opt=struct();
    opt.niter=10;
    opt.seed=1;
    opt.progress=false;
    z_ds1=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds1.samples,...
                    [1.28155 0.52440 0 0 1.28155 0.25335 ],...
                    'absolute',1e-4);
    ds.sa.targets(1)=3;
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh1,opt),'');



function test_null_data_montecarlo_cluster_stat
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
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh1,opt),'');

    opt.h0_mean=0;
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh1,opt),'');

    opt.niter=10;
    opt.progress=false;

    opt.null=ds;
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh1,opt),'');

    wrong_ds=cosmo_stack({ds,ds});

    opt.null=wrong_ds;
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh1,opt),'');

    opt.null=null_ds_cell;
    opt.null{end}.sa.targets(:)=0;
    assertExceptionThrown(@()cosmo_montecarlo_cluster_stat(ds,nh1,opt),'');


    opt.null=null_ds_cell;
    opt.seed=1;
    opt.h0_mean=0;
    z_ds1=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds1.samples,...
                    [0 -1.28155 1.03643 0 0.38532 0],...
                    'absolute',1e-4);

    opt.h0_mean=0.5;
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds2.samples,...
                    [0 -0.84162 1.28155 0 1.28155 0],...
                    'absolute',1e-4);






