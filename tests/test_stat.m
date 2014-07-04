function test_suite = test_stat
    initTestSuite;


function test_stat_
    % test conformity with matlab's stat functions
    ds=generate_test_dataset();
    ds=cosmo_slice(ds,[5 10 13],2);
    [ns,nf]=size(ds.samples);

    f=zeros(1,nf);
    p=zeros(1,nf);
    for k=1:nf
        [p(k),tab]=anova1(ds.samples(:,k), ds.sa.targets, 'off');
        f(k)=tab{2,5};
        df=[tab{2:3,3}];
    end

    % f stat
    
    ds.sa.chunks=(1:ns)';
    ff=cosmo_stat(ds,'F');
    assertVectorsAlmostEqual(f,ff.samples);
    assertEqual(ff.sa.stats,{sprintf('Ftest(%d,%d)',df)});
    
    pp=cosmo_stat(ds,'F','p');
    assertVectorsAlmostEqual(p,pp.samples);

    ds.sa.chunks(:)=1;
    assertExceptionThrown(@()cosmo_stat(ds,'F'),'');

    % t stat
    tails={'p','left','right','both'};
    for k=1:numel(tails)
        tail=tails{k};
        if strcmp(tail,'p')
            ttest_arg=cell(0);
        else
            ttest_arg={'tail',tail};
        end
        [h,p,ci,stats]=ttest(ds.samples,0,ttest_arg{:});
        assertExceptionThrown(@()cosmo_stat(ds,'t'),'');
        ds1=ds;
        ds1.sa.targets(:)=10;
        ds1.sa.chunks=(1:ns)';
        tt=cosmo_stat(ds1,'t');
        assertVectorsAlmostEqual(stats.tstat,tt.samples);
        assertEqual(tt.sa.stats,{sprintf('Ttest(%d)',stats.df(1))});

        pp=cosmo_stat(ds1,'t',tail);
        assertVectorsAlmostEqual(p,pp.samples);
        
        ds1.sa.chunks(:)=1;
        assertExceptionThrown(@()cosmo_stat(ds1,'t'),'');


        ds2=ds;
        i=randperm(ns)';
        ds2.sa.targets=mod(i,2)+1;
        ds2.sa.chunks=i;
        ds_sp=cosmo_split(ds2,'targets');
        x=ds_sp{1}.samples;
        y=ds_sp{2}.samples;
        
        [h,p,ci,stats]=ttest2(x,y,ttest_arg{:});
        [tt]=cosmo_stat(ds2,'t2');

        assertVectorsAlmostEqual(stats.tstat,tt.samples);
        assertEqual(tt.sa.stats,{sprintf('Ttest(%d)',stats.df(1))});
        pp=cosmo_stat(ds2,'t2',tail);
        assertVectorsAlmostEqual(p,pp.samples);
        
        ds2.sa.chunks(1)=ds2.sa.chunks(1)+1;
        assertExceptionThrown(@()cosmo_stat(ds1,'t2'),'');

        ds2.sa.chunks(1)=ds2.sa.chunks(1)-1;
        ds2.sa.targets(1)=ds2.sa.targets(1)+1;
        assertExceptionThrown(@()cosmo_stat(ds1,'t2'),'');
        ds2.sa.targets(:)=1;
        assertExceptionThrown(@()cosmo_stat(ds1,'t2'),'');
        
    end

    assertExceptionThrown(@()cosmo_stat(ds,'t2'),'');
    assertExceptionThrown(@()cosmo_stat(ds,'t'),'');
    
    
    
