function test_suite = test_corr
    initTestSuite;


function test_corr_no_type
    x=randn(10,20);
    y=randn(10,5);

    aeaa=@(x,y)assertElementsAlmostEqual(x,y);

    aeaa(cosmo_corr(x),corr(x));
    aeaa(cosmo_corr(x,y),corr(x,y));
    aeaa(cosmo_corr(y,x),corr(y,x));

function test_corr_with_type
    if cosmo_wtf('is_octave')
        cosmo_notify_test_skipped(['Non-Pearson correlation cannot '...
                        'be tested because Octave''s ''corr'' function '...
                        'does not support it']);
        return
    end

    x=randn(10,20);
    y=randn(10,5);

    aeaa=@(x,y)assertElementsAlmostEqual(x,y);
    aeaa(cosmo_corr(x,'Pearson'),corr(x,'type','Pearson'));
    aeaa(cosmo_corr(x,'Spearman'),corr(x,'type','Spearman'));


    aeaa(cosmo_corr(x,'Pearson'),corr(x,'type','Pearson'));
    aeaa(cosmo_corr(x,y,'Pearson'),corr(x,y,'type','Pearson'));

function test_corr_exceptions
    if cosmo_wtf('is_octave')
        id_minrhs='Octave:undefined-function';
        id_innerdim='Octave:nonconformant-args';
    else

        id_minrhs='MATLAB:minrhs';
        id_innerdim='MATLAB:innerdim';
    end

    aet=@(args,e)assertExceptionThrown(@()cosmo_corr(args{:}),e);

    x=randn(10,20);
    y=randn(10,5);

    aet({},id_minrhs);
    aet({y',x},id_innerdim);

