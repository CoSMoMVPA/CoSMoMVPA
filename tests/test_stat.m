function test_suite = test_stat
    initTestSuite;


function test_stat_
    % test conformity with matlab's stat functions
    ds=generate_test_dataset();
    ds=cosmo_slice(ds,[5 10 13],2);
    [ns,nf]=size(ds.samples);

    f=zeros(1,nf);
    for k=1:nf
        [p,tab]=anova1(ds.samples(:,k), ds.sa.targets, 'off');
        f(k)=tab{2,5};
        df=[tab{2:3,3}];
    end

    % f stat
    ff=cosmo_stat('f',ds);
    assertVectorsAlmostEqual(f,ff.samples);
    assertVectorsAlmostEqual(df,ff.sa.df);

    [f_,df_]=cosmo_stat('f',ds.samples,ds.sa.targets);
    assertVectorsAlmostEqual(f,f_);
    assertVectorsAlmostEqual(df,df_);

    % t stat
    [h,p,ci,stats]=ttest(ds.samples);
    tt=cosmo_stat('t',ds);
    assertVectorsAlmostEqual(stats.tstat,tt.samples);
    assertVectorsAlmostEqual(unique(stats.df),tt.sa.df);

    [t_,df_]=cosmo_stat('t',ds.samples);
    assertVectorsAlmostEqual(stats.tstat,t_);
    assertVectorsAlmostEqual(unique(stats.df),df_);

    % exceptions
    assertExceptionThrown(@()cosmo_stat('t2',ds),'');
    assertExceptionThrown(@()cosmo_stat('t2',ds.samples,ds.sa.targets),'');

    assertExceptionThrown(@()cosmo_stat('f',ds.sa),'');
    assertExceptionThrown(@()cosmo_stat('t',ds.sa),'');
    assertExceptionThrown(@()cosmo_stat('t2',ds.sa),'');

    % t2 stat
    ds=cosmo_slice(ds,ds.sa.targets>=3);
    x=ds.samples(ds.sa.targets==3,:);
    y=ds.samples(ds.sa.targets==4,:);

    [h,p,ci,stats]=ttest2(x,y);
    [tt]=cosmo_stat('t2',ds);
    assertVectorsAlmostEqual(stats.tstat,tt.samples);
    assertVectorsAlmostEqual(unique(stats.df),tt.sa.df);

    [t_,df_]=cosmo_stat('t2',ds.samples,ds.sa.targets);
    assertVectorsAlmostEqual(stats.tstat,t_);
    assertVectorsAlmostEqual(unique(stats.df),df_);

    ds=cosmo_slice(ds,ds.sa.targets==3); % single target
    assertExceptionThrown(@()cosmo_stat('t2',ds.sa),'');
