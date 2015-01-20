function test_suite = test_corr
    initTestSuite;


function test_corr_
    x=randn(10,20);
    y=randn(10,5);

    aeaa=@(x,y)assertElementsAlmostEqual(x,y);
    aet=@(args,e)assertExceptionThrown(@()cosmo_corr(args{:}),e);

    aeaa(cosmo_corr(x),corr(x));
    aeaa(cosmo_corr(x,y),corr(x,y));
    aeaa(cosmo_corr(y,x),corr(y,x));

    if cosmo_wtf('is_octave')
        cosmo_notify_test_skipped(['Non-Pearson correlation cannot '...
                        'be tested because Octave''s ''corr'' function '...
                        'does not suport it']);

        id_minrhs='Octave:undefined-function';
        id_unknown_type='Octave:invalid-fun-call';
        id_innerdim='Octave:nonconformant-args';
    else
        aeaa(cosmo_corr(x,'Pearson'),corr(x,'type','Pearson'));
        aeaa(cosmo_corr(x,'Spearman'),corr(x,'type','Spearman'));


        aeaa(cosmo_corr(x,'Pearson'),corr(x,'type','Pearson'));
        aeaa(cosmo_corr(x,y,'Pearson'),corr(x,y,'type','Pearson'));

        id_minrhs='MATLAB:minrhs';
        id_unknown_type='stats:corr:UnknownType';
        id_innerdim='MATLAB:innerdim';
    end



    aet({},id_minrhs);
    aet({x,'foo'},id_unknown_type);
    aet({y,'foo'},id_unknown_type);
    aet({y',x},id_innerdim);

