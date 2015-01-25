function test_suite = test_classify
    initTestSuite;

function test_classify_lda
    cfy=@cosmo_classify_lda;
    handle=get_predictor(cfy);
    assert_predictions_equal(handle,[1 3 9 8 5 6 8 9 7 5 7 5 4 ...
                                    9 2 7 7 7 1 2 1 1 7 6 7 1 7 ]');
    assert_throws_illegal_input_exceptions(cfy)

function test_classify_naive_bayes
    cfy=@cosmo_classify_naive_bayes;
    handle=get_predictor(cfy);
    assert_predictions_equal(handle,[8 8 3 8 8 8 8 9 8 8 9 8 8 ...
                                    8 8 8 8 8 8 8 8 8 8 8 8 8 8]');
    assert_throws_illegal_input_exceptions(cfy)

function test_classify_nn
    cfy=@cosmo_classify_nn;
    handle=get_predictor(cfy);
    assert_predictions_equal(handle,[1 3 6 8 6 6 8 7 7 5 7 7 4 ...
                                    9 7 7 7 7 1 2 7 1 5 6 7 1 9]');
    assert_throws_illegal_input_exceptions(cfy)

function test_classify_knn
    cfy=@cosmo_classify_knn;
    opt=struct();
    opt.knn=2;

    handle=get_predictor(cfy,opt);
    assert_predictions_equal(handle,[7 3 6 1 7 2 8 7 9 4 7 5 7 1 ...
                                    7 7 7 8 1 6 1 1 9 5 8 1 9]');
    assert_throws_illegal_input_exceptions(@(x,y,z)cfy(x,y,z,opt));

function test_classify_matlabsvm
    cfy=@cosmo_classify_matlabsvm;
    handle=get_predictor(cfy);
    if no_external('matlabsvm')
        assertExceptionThrown(handle,'');
        return;
    end
    assert_predictions_equal(handle,[1 3 9 7 6 6 9 3 7 5 6 6 4 ...
                                    1 7 7 7 7 1 7 7 1 7 6 7 1 9]');
    assert_throws_illegal_input_exceptions(cfy)

function test_classify_libsvm
    cfy=@cosmo_classify_libsvm;
    handle=get_predictor(cfy);
    if no_external('libsvm')
        assertExceptionThrown(handle(),'');
        return
    end
    assert_predictions_equal(handle,[1 3 6 8 6 6 8 7 7 5 7 5 4 ...
                                    9 7 7 7 8 1 2 8 1 9 6 7 1 7]');
    assert_throws_illegal_input_exceptions(cfy)

function test_classify_svm
    cfy=@cosmo_classify_svm;
    handle=get_predictor(cfy);
    if no_external('svm')
        assertExceptionThrown(handle,'');
        return;
    end
    if cosmo_check_external('libsvm',false)
        pred=[1 3 6 8 6 6 8 7 7 5 7 5 4 9 7 7 7 8 1 2 8 1 9 6 7 1 7]';
    else
        pred=[1 3 9 7 6 6 9 3 7 5 6 6 4 1 7 7 7 7 1 7 7 1 7 6 7 1 9]';
    end

    assert_predictions_equal(handle,pred);
    assert_throws_illegal_input_exceptions(cfy)

function assert_throws_illegal_input_exceptions(cfy)
    assertExceptionThrown(@()cfy([1 2],[1;2],[1 2]),'')
    assertExceptionThrown(@()cfy([1;2],[1 2],[1 2]),'')
    assertExceptionThrown(@()cfy([1 2],[1 2],[1 2]),'')
    assertExceptionThrown(@()cfy([1 2],1,[1;2]),'')
    assertExceptionThrown(@()cfy([1;2],1,[1 2]),'')
    assertExceptionThrown(@()cfy([1 2; 3 4; 5 6],[1;1],[1 2]),'')
    assertExceptionThrown(@()cfy([1 2; 3 4; 5 6],[1;1;1],[1 2 3]),'')

    % should pass
    cfy([1 2; 3 4],[1;1],[1 2]);
    cfy([1 2; 3 4; 5 6],[1;1;1],[1 2]);

function handle=get_predictor(cfy,opt)
    if nargin<2
        opt=struct();
    end
    [tr_samples,tr_targets,te_samples]=generate_data();
    handle=@()cfy(tr_samples,tr_targets,te_samples,opt);


function assert_predictions_equal(handle, targets)
    pred=handle();
    assertEqual(pred, targets);


function [tr_samples,tr_targets,te_samples]=generate_data()
    ds=cosmo_synthetic_dataset('ntargets',9,'nchunks',6);
    te_msk=ds.sa.chunks<=3;
    tr_msk=~te_msk;
    tr_targets=ds.sa.targets(tr_msk);
    tr_samples=ds.samples(tr_msk,:);
    te_samples=ds.samples(te_msk,:);

function is_absent=no_external(name)
    is_absent=~cosmo_check_external(name,false);
    if is_absent
        reason=sprintf('External ''%s'' is not present',name);
        cosmo_notify_test_skipped(reason)
    end

