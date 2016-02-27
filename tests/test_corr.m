function test_suite = test_corr
% tests for cosmo_corr
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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

function test_corr_assert_symmetric
    % ensure that correlating a matrix with itself gives a symmetric matrix
    for k=1:10
        nrows=ceil(rand()*5+3);
        ncols=ceil(rand()*2000+30);

        c=cosmo_corr(randn(ncols,nrows));
        assertEqual(c-c',zeros(nrows));
    end

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

