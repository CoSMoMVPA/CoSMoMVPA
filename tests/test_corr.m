function test_suite = test_corr
% tests for cosmo_corr
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function [x,y]=get_test_data()
     x= [  -1.3248     0.84109   -0.086612 ;...
            1.5733     -1.8183    -0.57326 ;...
          -0.42249     -1.6352      1.1706 ;...
           0.05563    -0.29544    -0.78571 ;...
          -0.98777     -1.4062   0.0017427 ];

     y= [   -1.2001    -0.61776 ;...
             1.6666      1.3606 ;...
           -0.67152    -0.51148 ;...
          -0.011727     0.47389 ;...
           -0.79028     0.95889 ];

function test_regression_pearson()
    r=[  0.9875    0.6584 ;...
        -0.5327   -0.5610 ;...
        -0.4914   -0.6014];

    [x,y]=get_test_data();
    assertElementsAlmostEqual(r,cosmo_corr(x,y),'absolute',.001);
    assertElementsAlmostEqual(r,cosmo_corr(x,y,'Pearson'),...
                                                    'absolute',.001);

function test_regression_spearman()
    r=[  1.0    0.7 ;...
        -0.7   -0.7 ;...
        -0.5   -0.3];

    [x,y]=get_test_data();
    assertElementsAlmostEqual(r,cosmo_corr(x,y,'Spearman'));


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
        v=cosmo_wtf('version');
        is_prior_to_2012b=str2num(v(1))<=7;

        if is_prior_to_2012b
            id_minrhs='MATLAB:inputArgUndefined';
        else
            id_minrhs='MATLAB:minrhs';
        end

        id_innerdim='MATLAB:innerdim';
    end

    aet=@(args,e)assertExceptionThrown(@()cosmo_corr(args{:}),e);

    x=randn(10,20);
    y=randn(10,5);

    aet({},id_minrhs);
    aet({y',x},id_innerdim);

