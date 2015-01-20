function test_suite = test_stat
    initTestSuite;


function test_stat_
    is_matlab=cosmo_wtf('is_matlab');

    % test conformity with matlab's stat functions
    ds=cosmo_synthetic_dataset('nchunks',5,'ntargets',4,'sigma',0);
    ds=cosmo_slice(ds,[2 5 6],2);
    [ns,nf]=size(ds.samples);

    f=zeros(1,nf);
    p=zeros(1,nf);


    for k=1:nf
        if is_matlab
            [p(k),tab]=anova1(ds.samples(:,k), ds.sa.targets, 'off');
            f(k)=tab{2,5};
            df=[tab{2:3,3}];
        else
            [p(k),f(k),df_b,df_w]=anova(ds.samples(:,k), ds.sa.targets);
            df=[df_b df_w];
        end
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
        % one-sample ttest
        assertExceptionThrown(@()cosmo_stat(ds,'t'),'');
        ds1=ds;
        ds1.sa.targets(:)=10;
        ds1.sa.chunks=(1:ns)';

        tail=tails{k};

        if is_matlab
            if strcmp(tail,'p')
                ttest_arg=cell(0);
            else
                ttest_arg={'tail',tail};
            end

            % test t-statistic
            [h,p,ci,stats]=ttest(ds.samples,0,ttest_arg{:});

            tt=cosmo_stat(ds1,'t');
            assertVectorsAlmostEqual(stats.tstat,tt.samples);
            assertEqual(tt.sa.stats,{sprintf('Ttest(%d)',stats.df(1))});
        else
            if strcmp(tail,'p')
                ttest_arg=cell(0);
            else
                ttest_arg={tail};
            end
            [h,p]=ttest(ds.samples,0,.05,ttest_arg{:});
        end

        pp=cosmo_stat(ds1,'t',tail);
        assertVectorsAlmostEqual(p,pp.samples);

        ds1.sa.chunks(:)=1;
        assertExceptionThrown(@()cosmo_stat(ds1,'t'),'');

        % two-sample (unpaired) ttest
        ds2=ds;
        i=randperm(ns)';
        ds2.sa.targets=mod(i,2)+1;
        ds2.sa.chunks=i;
        ds_sp=cosmo_split(ds2,'targets');
        x=ds_sp{1}.samples;
        y=ds_sp{2}.samples;

        if is_matlab
            [h,p,ci,stats]=ttest2(x,y,ttest_arg{:});
            [tt]=cosmo_stat(ds2,'t2');

            assertVectorsAlmostEqual(stats.tstat,tt.samples);
            assertEqual(tt.sa.stats,{sprintf('Ttest(%d)',stats.df(1))});
        else
            [h,p]=ttest2(x,y,.05,ttest_arg{:});
        end

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



