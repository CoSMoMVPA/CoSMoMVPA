function test_suite = test_crossvalidation_measure
% tests for cosmo_crossvalidation_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_crossvalidation_measure_regression
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',4);
    ds.sa.targets=ds.sa.targets+10;
    ds.sa.chunks=ds.sa.chunks+20;

    opt=struct();
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.classifier=@cosmo_classify_lda;

    res=cosmo_crossvalidation_measure(ds,opt);
    assertElementsAlmostEqual(res.samples,0.6250);
    assertEqual(res.sa,cosmo_structjoin('labels',{'accuracy'}));

    opt.output='accuracy';
    res2=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res,res2);

    opt.output='winner_predictions';
    res3=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res3.samples,10+[1 2 3 4 5 5 4 6 2 4 2 6 ...
                                1 2 3 4 6 6 1 3 3 4 3 1]');
    assertEqual(res3.sa,rmfield(ds.sa,'chunks'));

    % use deprecated output options
    warning_state=cosmo_warning();
    warning_state_resetter=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');
    opt.output='winner_predictions';
    res3a=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res3,res3a);


    opt.output='fold_accuracy';
    res4=cosmo_crossvalidation_measure(ds,opt);
    assertElementsAlmostEqual(res4.samples,[5 2 5 3]'/6);
    assertEqual(res4.sa.folds,(1:4)');

    % test different classifier
    opt.classifier=@cosmo_classify_nn;
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.output='winner_predictions';

    res6=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res6.samples,10+[1 2 3 1 5 6 4 6 5 4 6 6 6 ...
                                    2 3 4 2 5 1 2 3 4 3 1]');
    % test normalization option
    opt.normalization='zscore';
    res7=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res7.samples,10+[1 2 3 5 5 6 4 6 5 4 6 6 6 ...
                                    2 3 4 5 5 1 5 3 1 3 1]');

    % test with averaging samples
    opt=rmfield(opt,'normalization');
    opt.average_train_count=1;
    res8=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res8.samples,10+[1 2 3 1 5 6 4 6 5 4 6 6 6 ...
                                    2 3 4 2 5 1 2 3 4 3 1]');

    opt.average_train_count=2;
    opt.average_train_resamplings=5;
    res9=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res9.samples,10+[1 2 3 4 5 6 4 6 2 4 6 6 1 ...
                                    2 3 4 5 6 1 2 3 4 5 1]');


function test_fold_accuracy()
    randint=@()ceil(rand()*5)+5;

    ntargets=randint();
    ds=cosmo_synthetic_dataset('ntargets',ntargets,...
                                'nchunks',randint(),...
                                'nreps',randint());
    ds.samples(:)=randn(size(ds.samples));
    ds.sa.targets=ds.sa.targets+10;
    ds.sa.chunks=ds.sa.chunks+20;

    partitions=cosmo_nchoosek_partitioner(ds,3);

    opt=struct();
    opt.partitions=partitions;
    opt.classifier=@cosmo_classify_nn;
    opt.output='fold_accuracy';

    nfolds=numel(opt.partitions.train_indices);

    res=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(size(res.samples),[nfolds,1]);
    assertEqual(size(res.sa.folds),[nfolds,1]);

    for fold=1:nfolds
        f_opt=opt;
        f_opt.partitions.train_indices=partitions.train_indices(fold);
        f_opt.partitions.test_indices=partitions.test_indices(fold);
        f_res=cosmo_crossvalidation_measure(ds,f_opt);
        assertElementsAlmostEqual(res.samples(fold),f_res.samples);
    end



function test_fold_predictions
    randint=@()ceil(rand()*4)+1;

    ntargets=randint();
    targets_offset=randint();
    nchunks=randint()+1;
    ds=cosmo_synthetic_dataset('ntargets',ntargets,...
                                'nchunks',nchunks,...
                                'nreps',randint());
    ds.samples(:)=randn(size(ds.samples));
    ds.sa.targets=ds.sa.targets+targets_offset;
    ds.sa.chunks=ds.sa.chunks+20;


    opt=struct();
    opt.partitions=cosmo_nchoosek_partitioner(ds,ceil(nchunks/2));
    opt.classifier=@cosmo_classify_nn;
    opt.output='fold_predictions';

    train_idx=opt.partitions.train_indices;
    test_idx=opt.partitions.test_indices;

    nfolds=numel(train_idx);
    nsamples=size(ds.samples,1);

    % using crossvalidation_measure
    res=cosmo_crossvalidation_measure(ds,opt);

    % using crossvalidate function
    [cv_pred,acc]=cosmo_crossvalidate(ds,opt.classifier,opt.partitions);

    visited=false(size(res.samples));
    for k=1:nfolds
        % test crossvalidation_measure
        msk=res.sa.folds==k;
        visited(msk)=true;
        pred=res.samples(msk,:);
        assertEqual(size(pred),[numel(test_idx{k}),1]);
        assertEqual(res.sa.targets(msk),ds.sa.targets(test_idx{k}));

        % compare with classifier output
        fold_pred=opt.classifier(ds.samples(train_idx{k},:),...
                         ds.sa.targets(train_idx{k}),...
                         ds.samples(test_idx{k},:));
        assertEqual(fold_pred,pred);

        % check comso_crossvalidate output
        nan_msk=true(nsamples,1);
        nan_msk(test_idx{k})=false;
        assertEqual(isnan(cv_pred(:,k)),nan_msk);
        assertEqual(cv_pred(~nan_msk,k),fold_pred);
    end
    assert(all(visited));

    % fields should only be targets and folds
    assertEqual(sort(fieldnames(res.sa)),...
                sort({'targets';'folds'}));

    % test accuracy
    pred_msk=~isnan(cv_pred);
    correct_pred=bsxfun(@eq,cv_pred,ds.sa.targets) & pred_msk;
    assertElementsAlmostEqual(acc,sum(correct_pred)/sum(pred_msk));

    % test with winner_predictions
    opt.output='winner_predictions';
    res=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(size(res.samples),[nsamples,1]);

    for row=1:nsamples
        h=histc(cv_pred(row,:),(1:ntargets)+targets_offset);

        % predicted sample is a winner
        row_pred=res.samples(row)-targets_offset;
        assert(all(h<=h(row_pred)));

        % correct winner
        assert(h(row_pred)==max(h));
    end


function test_crossvalidation_measure_deprecations
    warning_state=cosmo_warning();
    state_resetter=onCleanup(@()cosmo_warning(warning_state));

    deprecated_outputs={'predictions','raw'};

    ds=cosmo_synthetic_dataset();
    opt=struct();
    opt.classifier=@cosmo_classify_nn;
    opt.partitions=cosmo_nfold_partitioner(ds);


    for i_output=1:numel(deprecated_outputs);
        cosmo_warning('reset');
        cosmo_warning('off');

        output=deprecated_outputs{i_output};
        opt.output=output;

        % run the measure
        cosmo_crossvalidation_measure(ds,opt);

        % must have shown a warning
        s=cosmo_warning();
        w=s.shown_warnings;
        assertTrue(numel(w)>=1, 'no warning was shown');
    end



function test_crossvalidation_measure_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_crossvalidation_measure(varargin{:}),'');
    bad_opt=struct();
    bad_opt.partitions=struct();
    bad_opt.classifier=@abs;
    aet(struct,bad_opt);

    ds=cosmo_synthetic_dataset();
    opt=struct();
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.classifier=@cosmo_classify_lda;

    aet(struct,opt)

    bad_opt=opt;
    bad_opt.output='foo';
    aet(ds,bad_opt);

    bad_opt=opt;
    bad_opt.output='accuracy_by_chunk'; % not supported anymore
    aet(ds,bad_opt);



function test_balanced_accuracy()
    nclasses=10;
    nchunks=20;
    ds=cosmo_synthetic_dataset('ntargets',nclasses,...
                                'nchunks',nchunks,...
                                'nreps',4);

    % shuffle targets, use random data - assume data is unbalanced
    % afterwards
    ds.samples=randn(size(ds.samples));

    nsamples=size(ds.samples,1);
    while true
        ds.sa.targets=ceil(rand(nsamples,1)*nclasses);
        ds.sa.chunks=ceil(rand(nsamples,1)*nchunks);

        h_t=histc(ds.sa.targets,1:nclasses);
        h_c=histc(ds.sa.chunks,1:nchunks);

        if numel(h_t)~=nclasses || ...
                numel(h_c)~=nchunks
            % classes or chunsk missing, regenerate
            continue;
        end

        if any(h_t~=nclasses) && any(h_c~=nchunks)
            % inbalance
            break;
        end
    end

    % keep subset of all partitions, so that there are missing predictions
    % for some of the samples
    partitions=cosmo_nfold_partitioner(ds);
    nkeep=ceil(.3*nchunks);
    partitions.train_indices=partitions.train_indices(1:nkeep);
    partitions.test_indices=partitions.test_indices(1:nkeep);

    % compute balanced accuracy
    opt=struct();
    opt.classifier=@cosmo_classify_nn;
    opt.partitions=partitions;


    % without check_partitions, an exception should be thrown as the
    % partitions are supposed to be unbalanced
    assertExceptionThrown(@()...
                        cosmo_check_partitions(partitions,ds),'');
    assertExceptionThrown(@()...
                        cosmo_crossvalidation_measure(ds,opt),'');
    opt.check_partitions=false;

    % compute accuracy
    opt.output='balanced_accuracy';
    ba_result=cosmo_crossvalidation_measure(ds,opt);

    opt.output='winner_predictions';
    pred_result=cosmo_crossvalidation_measure(ds,opt);

    opt.output='accuracy';
    acc_result=cosmo_crossvalidation_measure(ds,opt);

    % check fields
    result_cell={ba_result,acc_result};
    for k=1:numel(result_cell)
        result=result_cell{k};

        assertEqual(sort(fieldnames(result)),sort({'samples';'sa'}));
        assertEqual(fieldnames(result.sa),{'labels'});
    end

    assertEqual(ba_result.sa.labels,{'balanced_accuracy'});
    assertEqual(acc_result.sa.labels,{'accuracy'});


    % compute expected result for balanced accuracy
    [unused,unused,target_idx]=unique(ds.sa.targets);
    assert(max(target_idx)==nclasses);
    nfolds=numel(partitions.train_indices);

    correct_count=zeros(nfolds,nclasses);
    class_count=zeros(1,nclasses);

    all_pred=NaN(nsamples,1);

    for fold_i=1:nfolds
        tr_idx=partitions.train_indices{fold_i};
        te_idx=partitions.test_indices{fold_i};

        ds_tr=cosmo_slice(ds,tr_idx);
        ds_te=cosmo_slice(ds,te_idx);

        target_idx_te=target_idx(te_idx);

        pred=opt.classifier(ds_tr.samples,...
                            ds_tr.sa.targets,...
                            ds_te.samples);
        all_pred(te_idx)=pred;
        for class_i=1:nclasses
            target_msk=target_idx_te==class_i;
            is_correct=pred(target_msk)==ds_te.sa.targets(target_msk);
            correct_count(fold_i,class_i)=sum(is_correct);
            class_count(class_i)=class_count(class_i)+numel(is_correct);
        end
    end

    class_acc=bsxfun(@rdivide,sum(correct_count,1),class_count);

    % verify expected result for balanced accuracy
    assertElementsAlmostEqual(mean(class_acc),ba_result.samples);

    % verify expected result for predictions of each class
    assertEqual(pred_result.samples,all_pred);
    assertEqual(pred_result.sa.targets,ds.sa.targets);



function test_pca()
    ntargets=2;
    nchunks=5;

    nfeatures=ceil(rand()*10+10);
    nsamples=ntargets*nchunks*4*nfeatures;

    idxs=(1:nsamples)'-1;

    ds=struct();
    ds.samples=randn(nsamples,nfeatures);
    ds.sa.targets=mod(idxs,ntargets)+1;
    ds.sa.chunks=mod(floor(idxs/(ntargets*nchunks)),nchunks)+1;

    test_msk=ds.sa.chunks==nchunks;
    partitions=struct();
    partitions.train_indices={find(~test_msk)};
    partitions.test_indices={find(test_msk)};

    opt=struct();
    opt.partitions=partitions;
    opt.classifier=@cosmo_classify_lda;
    opt.output='winner_predictions';

    for count=[1 ceil(nfeatures/2) nfeatures ceil(rand()*nfeatures)]
        opt_count=opt;
        opt_count.pca_explained_count=count;
        helper_test_pca_count(ds,opt_count,count)
    end

    for ratio=[.1 .5 .9 1 rand()]
        opt_ratio=opt;
        opt_ratio.pca_explained_ratio=ratio;
        helper_test_pca_ratio(ds,opt_ratio,ratio)
    end

function helper_test_pca_count(ds,opt,count)
    pred_full=cosmo_crossvalidation_measure(ds,opt);

    % compute results manually
    [expected_pred,test_indices]=helper_pca_crossval_single_fold(ds,...
                                                        opt,count);
    % compare results
    assertEqual(expected_pred,...
                    pred_full.samples(test_indices));

function [pred,test_indices]=helper_pca_crossval_single_fold(ds,opt,count)
    partitions=opt.partitions;
    assert(numel(partitions.train_indices)==1);
    assert(numel(partitions.test_indices)==1);
    ds_train=cosmo_slice(ds,partitions.train_indices{1});
    [tr_pca,params]=cosmo_pca(ds_train.samples,count);

    test_indices=partitions.test_indices{1};
    ds_test=cosmo_slice(ds,test_indices);
    te_pca=bsxfun(@minus,ds_test.samples,params.mu)*params.coef;

    pred=opt.classifier(tr_pca,ds_train.sa.targets,te_pca);


function helper_test_pca_ratio(ds,opt,ratio)
    partitions=opt.partitions;
    assert(numel(partitions.train_indices)==1);
    ds_train=cosmo_slice(ds,partitions.train_indices{1});
    [unused,params]=cosmo_pca(ds_train.samples);

    count=find(cumsum(params.explained)>=ratio*100,1);
    if isempty(count)
        count=numel(params.explained);
    end

    % delegate to count helepr
    helper_test_pca_count(ds,opt,count)


function test_crossvalidation_measure_pca_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_crossvalidation_measure(varargin{:}),'');
    ds=cosmo_synthetic_dataset();

    opt=struct();
    opt.classifier=@cosmo_classify_lda;
    opt.partitions=cosmo_nfold_partitioner(ds);

    % mutually exclusive parameters
    bad_opt=opt;
    bad_opt.pca_explained_count=2;
    bad_opt.pca_explained_ratio=.5;

    aet(ds,bad_opt);

