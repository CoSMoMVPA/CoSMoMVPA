function test_suite = test_norminv
% tests for cosmo_norminv
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_norminv_stats_correspondence
    if cosmo_skip_test_if_no_external('!norminv')
        return;
    end

    helper_test_norminv_same(rand());
    helper_test_norminv_same(1+rand());

    helper_test_norminv_same(rand(10,200));
    helper_test_norminv_same(rand(2,3,5)*2-.5);

    sz=ceil(2+rand(1,3)*2);
    helper_test_norminv_same(rand(sz),rand(),rand());
    helper_test_norminv_same(rand(sz),rand(sz),rand(sz));

    helper_test_norminv_same(NaN);
    helper_test_norminv_same(0);
    helper_test_norminv_same(1);
    helper_test_norminv_same(-inf);
    helper_test_norminv_same(+inf);

function test_norminv_stats_non_scalar_mu_sd_correspondence
    if cosmo_skip_test_if_no_external('!norminv')
        return;
    end

    if cosmo_wtf('is_octave')
        reason='Octave''s norminv cannot use bsxfun-like inputs';
        cosmo_notify_test_skipped(reason);
        return
    end

    v=cosmo_wtf('version_number');
    if v(1)<=8 || v(2)<=0
        % before 2016b
        reason='Older matlab''s norminv cannot use bsxfun-like inputs';
        cosmo_notify_test_skipped(reason);
        return;
    end

    helper_test_norminv_same(rand(10,5),rand(1,5),rand(10,1));
    helper_test_norminv_same(2*rand(10,5,2),rand(1,5,2),rand(10,1,1));



function test_norminv_regression
    x=[0.8287 0.8471 0.0660 0 1 -1 3 NaN -Inf Inf];
    y=[0.9490 1.0241 -1.5063 -Inf Inf NaN NaN NaN NaN NaN];
    assertElementsAlmostEqual(cosmo_norminv(x),y,'absolute',1e-4);


function helper_test_norminv_same(varargin)
    y1=norminv(varargin{:});
    y2=cosmo_norminv(varargin{:});

    assertElementsAlmostEqual(y1,y2);

