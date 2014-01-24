function test_suite = test_slice
    initTestSuite;


function test_corr_
    x=randn(10,20);
    y=randn(10,5);

    aeaa=@(x,y)assertElementsAlmostEqual(x,y);
    aet=@(args,e)assertExceptionThrown(@()cosmo_corr(args{:}),e);

    aeaa(cosmo_corr(x),corr(x));
    aeaa(cosmo_corr(x,'Pearson'),corr(x,'type','Pearson'));
    aeaa(cosmo_corr(x,'Spearman'),corr(x,'type','Spearman'));

    aeaa(cosmo_corr(x,y),corr(x,y));
    aeaa(cosmo_corr(y,x),corr(y,x));
    aeaa(cosmo_corr(x,'Pearson'),corr(x,'type','Pearson'));
    aeaa(cosmo_corr(x,y,'Pearson'),corr(x,y,'type','Pearson'));


    aet({},'MATLAB:minrhs');
    aet({x,'foo'},'stats:corr:UnknownType');
    aet({y,'foo'},'stats:corr:UnknownType');
    aet({y',x},'MATLAB:innerdim');

