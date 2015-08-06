function test_suite = test_classify
    initTestSuite;

function test_classify_lda
    cfy=@cosmo_classify_lda;
    handle=get_predictor(cfy);
    assert_predictions_equal(handle,[1 3 9 8 5 6 8 9 7 5 7 5 4 ...
                                    9 2 7 7 7 1 2 1 1 7 6 7 1 7 ]');
    assert_throws_illegal_input_exceptions(cfy);

    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_classify_lda(varargin{:}),'');
    x=randn(5,3);
    y=randn(2,3);
    aet(x,[1 1 1 2 2],y);

    % too many features
    x=zeros(1,1e4);
    y=zeros(1,1e4);
    aet(x,1,1e4);


function test_classify_naive_bayes
    cfy=@cosmo_classify_naive_bayes;
    handle=get_predictor(cfy);
    assert_predictions_equal(handle,[1 7 3 9 2 2 8 9 7 4 7 2 4 ...
                                    8 2 7 7 7 1 2 7 1 7 2 7 1 9 ]');
    assert_throws_illegal_input_exceptions(cfy)


function test_classify_meta_feature_selection
    cfy=@cosmo_classify_meta_feature_selection;
    opt=struct();
    opt.child_classifier=@cosmo_classify_lda;
    opt.feature_selector=@cosmo_anova_feature_selector;
    opt.feature_selection_ratio_to_keep=.6;
    handle=get_predictor(cfy,opt);
    assert_predictions_equal(handle,[1 3 7 8 6 6 8 3 7 5 7 5 4 ...
                                    9 2 7 7 3 3 2 1 3 7 6 7 9 7 ]');
    assert_throws_illegal_input_exceptions(cfy,opt)

function test_cosmo_meta_feature_selection_classifier
    % deprecated, so shows a warning
    warning_state=cosmo_warning();
    warning_state_resetter=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    cfy=@cosmo_meta_feature_selection_classifier;
    opt=struct();
    opt.child_classifier=@cosmo_classify_lda;
    opt.feature_selector=@cosmo_anova_feature_selector;
    opt.feature_selection_ratio_to_keep=.6;
    handle=get_predictor(cfy,opt);
    assert_predictions_equal(handle,[1 3 7 8 6 6 8 3 7 5 7 5 4 ...
                                    9 2 7 7 3 3 2 1 3 7 6 7 9 7 ]');
    assert_throws_illegal_input_exceptions(cfy,opt)

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
    assert_throws_illegal_input_exceptions(cfy,opt);

function test_classify_matlabsvm
    cfy=@cosmo_classify_matlabsvm;
    handle=get_predictor(cfy);
    if no_external('matlabsvm')
        assertExceptionThrown(handle,'');
        return;
    end

    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    assert_predictions_equal(handle,[1 3 9 7 6 6 9 3 7 5 6 6 4 ...
                                    1 7 7 7 7 1 7 7 1 7 6 7 1 9]');
    assert_throws_illegal_input_exceptions(cfy);

function test_classify_matlabsvm_2class
    cfy=@cosmo_classify_matlabsvm_2class;
    handle=get_predictor(cfy);
    if no_external('matlabsvm')
        assertExceptionThrown(handle,'');
        return;
    end
    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    assertExceptionThrown(handle,''); % cannot deal with nine classes

    handle=get_predictor(cfy,struct(),2);

    assert_predictions_equal(handle,[1 2 2 2 1 2]');
    assert_throws_illegal_input_exceptions(cfy);

     % test non-convergence
    aet=@(exc,varargin)assertExceptionThrown(@()...
                        cosmo_classify_matlabsvm_2class(varargin{:}),exc);
    opt=struct();
    opt.options.MaxIter=1;
    aet('',[0 0; 0 1; 1 0; 1 1; ],[1 2 2 1],NaN(2),opt);
    opt.tolkkt=struct();
    aet('stats:svmtrain:badTolKKT',...
                [0 0; 0 1; 1 0; 1 1; ],[1 2 2 1],NaN(2),opt);



function test_classify_libsvm_with_autoscale
    cfy=@cosmo_classify_libsvm;
    opt=struct();
    opt.autoscale=true;
    handle=get_predictor(cfy,opt);
    if no_external('libsvm')
        assertExceptionThrown(handle,'');
        return;
    end

    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    assert_predictions_equal(handle,[8 3 3 8 6 6 1 3 7 5 7 6 4 ...
                                    1 2 7 7 7 1 2 8 1 9 6 7 1 3 ]');
    assert_throws_illegal_input_exceptions(cfy,opt);

function test_classify_libsvm_no_autoscale
    cfy=@cosmo_classify_libsvm;
    opt=struct();
    opt.autoscale=false;
    handle=get_predictor(cfy,opt);
    if no_external('libsvm')
        assertExceptionThrown(handle,'');
        return;
    end

    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    assert_predictions_equal(handle,[8 3 3 8 6 6 1 3 7 5 7 6 4 ...
                                    1 2 7 7 7 1 2 8 1 9 6 7 1 3]');
    assert_throws_illegal_input_exceptions(cfy,opt);



function test_classify_libsvm_t0
    % test with default (linear kernel) type t=0
    cfy=@cosmo_classify_libsvm;

    % with or without some of the default options; all should give the same
    % result
    params={{},...
            {'t','0'},...
            {'t',0},...
            {'t',0,'autoscale',false,'s','0','r',0,'c',1,'h',1}};
    n=numel(params);

    for k=1:n
        param=params{k};
        if isempty(param)
            opt=[];
            opt_struct=struct();
        else
            opt=cosmo_structjoin(param);
            opt_struct=opt;
        end
        handle=get_predictor(cfy,opt);
        if no_external('libsvm')
            assertExceptionThrown(handle,'');
            return
        end

        assert_predictions_equal(handle,[8 3 3 8 6 6 1 3 7 5 7 6 4 ...
                                        1 2 7 7 7 1 2 8 1 9 6 7 1 3]');
        assert_throws_illegal_input_exceptions(cfy,opt_struct)
    end

function test_classify_libsvm_t2
    cfy=@cosmo_classify_libsvm;
    opt=struct();
    opt.t=2;
    handle=get_predictor(cfy,opt);
    if no_external('libsvm')
        assertExceptionThrown(handle,'');
        return
    end

    % libsvm uses autoscale by default
    assert_predictions_equal(handle,[1 3 6 8 6 6 8 3 7 5 7 5 4 ...
                                    5 7 7 7 8 1 2 8 1 5 5 7 1 7]');
    assert_throws_illegal_input_exceptions(cfy,opt)

function test_classify_svm
    cfy=@cosmo_classify_svm;
    handle=get_predictor(cfy);
    if no_external('svm')
        assertExceptionThrown(handle,'');
        return;
    end

    % matlab and libsvm show slightly different results
    if cosmo_check_external('libsvm',false)
        pred=[8 3 3 8 6 6 1 3 7 5 7 6 4 1 2 7 7 7 1 2 8 1 9 6 7 1 3]';
    else
        % do not show warning message
        warning_state=cosmo_warning();
        cleaner=onCleanup(@()cosmo_warning(warning_state));
        cosmo_warning('off');

        pred=[1 3 9 7 6 6 9 3 7 5 6 6 4 1 7 7 7 7 1 7 7 1 7 6 7 1 9]';
    end

    assert_predictions_equal(handle,pred);
    assert_throws_illegal_input_exceptions(cfy)

function assert_throws_illegal_input_exceptions(cfy_base,opt)
    if nargin<2
        cfy=cfy_base;
    else
        cfy=@(x,y,z)cfy_base(x,y,z,opt);
    end
    assertExceptionThrown(@()cfy([1 2],[1;2],[1 2]),'')
    assertExceptionThrown(@()cfy([1;2],[1 2],[1 2]),'')
    assertExceptionThrown(@()cfy([1 2],[1 2],[1 2]),'')
    assertExceptionThrown(@()cfy([1 2],1,[1;2]),'')
    assertExceptionThrown(@()cfy([1;2],1,[1 2]),'')
    assertExceptionThrown(@()cfy([1 2; 3 4; 5 6],[1;1],[1 2]),'')
    assertExceptionThrown(@()cfy([1 2; 3 4; 5 6],[1;1;1],[1 2 3]),'')

    % should pass
    non_one_class_classifiers={@cosmo_classify_matlabsvm_2class,...
                               @cosmo_classify_meta_feature_selection,...
                               @cosmo_meta_feature_selection_classifier};

    can_handle_single_class=~any(cellfun(@(x)isequal(cfy_base,x),...
                                    non_one_class_classifiers));

    if can_handle_single_class
        cfy([1 2; 3 4],[1;1],[1 2]);
        cfy([1 2; 3 4; 5 6],[1;1;1],[1 2]);
    end

    % no features, should still make prediction
    res=cfy(zeros(4,0),[1 1 2 2]',zeros(2,0));
    assertEqual(size(res),[2 1]);
    assertTrue(all(res==1 | res==2));

    res2=cfy(zeros(4,0),[1 1 2 2]',zeros(2,0));
    assertEqual(res,res2);

function handle=get_predictor(cfy,opt,nclasses)
    clear(func2str(cfy));

    if nargin<3
        nclasses=9;
    end
    if nargin<2 || isempty(opt)
        opt_arg={};
    else
        opt_arg={opt};
    end
    [tr_samples,tr_targets,te_samples]=generate_data(nclasses);
    handle=@()cfy(tr_samples,tr_targets,te_samples,opt_arg{:});


function assert_predictions_equal(handle, targets)
    pred=handle();
    assertEqual(pred, targets);

    % test caching, if implemented
    pred2=handle();
    assertEqual(pred,pred2);


function [tr_samples,tr_targets,te_samples]=generate_data(nclasses)
    ds=cosmo_synthetic_dataset('ntargets',nclasses,...
                                'nchunks',6);
    te_msk=ds.sa.chunks<=3;
    tr_msk=~te_msk;
    tr_targets=ds.sa.targets(tr_msk);
    tr_samples=ds.samples(tr_msk,:);
    te_samples=ds.samples(te_msk,:);

function is_absent=no_external(external_name)
    is_absent=cosmo_skip_test_if_no_external(external_name);

