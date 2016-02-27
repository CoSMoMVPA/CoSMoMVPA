function test_suite=test_montecarlo_cluster_stat
% tests for cosmo_montecarlo_cluster_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

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
    aet(ds,nh2,opt);
    opt=rmfield(opt,'dh');
    aet(ds,nh2,opt);
    opt.p_uncorrected=.55;
    aet(ds,nh2,opt);
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
                    [1.03643 -1.28155 0 1.28155 -1.03643 0.25335],...
                    'absolute',1e-4);
    opt.cluster_stat='maxsum';
    opt.p_uncorrected=0.35;
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh1,opt);

    assertElementsAlmostEqual(z_ds2.samples,...
                    [1.03643 -1.28155 0 1.03643 -1.28155 0.25335],...
                    'absolute',1e-4);

    % test between-subjects
    ds.sa.chunks=ds.sa.chunks*2+ds.sa.targets;
    opt=struct();
    opt.niter=10;
    opt.seed=1;
    opt.progress=false;
    z_ds3=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds3.samples,...
                    [  0.2533 -1.2816 0 0.5244 -1.2816 0.1257],...
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
                    [1.28155 0.52440 0 0 1.28155 0.25335 ],...
                    'absolute',1e-4);

    % test between-subjects
    ds.sa.chunks=ds.sa.chunks*3+ds.sa.targets;
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds2.samples,...
                    [1.2816 1.2816 -0.1257 0.2533 1.2816 1.0364],...
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
                    [0 -1.28155 1.03643 0 0.38532 0],...
                    'absolute',1e-4);

    opt.h0_mean=0.5;
    z_ds2=cosmo_montecarlo_cluster_stat(ds,nh1,opt);
    assertElementsAlmostEqual(z_ds2.samples,...
                    [0 -0.84162 1.28155 0 1.28155 0],...
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




