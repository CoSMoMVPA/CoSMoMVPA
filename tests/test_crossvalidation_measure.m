function test_suite = test_crossvalidation_measure
% tests for cosmo_crossvalidation_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_crossvalidation_measure_basics
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',4);
    ds.sa.targets=ds.sa.targets+10;
    ds.sa.chunks=ds.sa.chunks+20;

    opt=struct();
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.classifier=@cosmo_classify_lda;

    res=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res.samples,0.6250);
    assertEqual(res.sa,cosmo_structjoin('labels',{'accuracy'}));

    opt.output='accuracy';
    res2=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res,res2);

    opt.output='predictions';
    res3=cosmo_crossvalidation_measure(ds,opt);
    assertEqual(res3.samples,10+[1 2 3 4 5 5 4 6 2 4 2 6 ...
                                1 2 3 4 6 6 1 3 3 4 3 1]');
    assertEqual(res3.sa,ds.sa);

    opt.output='accuracy_by_chunk';
    res4=cosmo_crossvalidation_measure(ds,opt);
    assertElementsAlmostEqual(res4.samples,[5 2 5 3]'/6);

    opt.partitions=cosmo_nchoosek_partitioner(ds,2);
    opt.partitions.test_indices{1}=find(ds.sa.chunks==21);
    opt.partitions.test_indices{4}=find(ds.sa.chunks==22);
    opt.partitions.test_indices{5}=find(ds.sa.chunks==24);
    res5=cosmo_crossvalidation_measure(ds,opt);
    assertElementsAlmostEqual(res5.samples,[3 NaN NaN NaN]'/6);
    assertEqual(res5.sa,cosmo_structjoin('chunks',[22 NaN NaN NaN]'));

    % test different classifier
    opt.classifier=@cosmo_classify_nn;
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.output='predictions';

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



function test_crossvalidation_measure_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_crossvalidation_measure(varargin{:}),'');
    opt=struct();
    opt.partitions=struct();
    opt.classifier=@abs;
    aet(struct,opt);

    ds=cosmo_synthetic_dataset();
    opt.partitions=cosmo_nfold_partitioner(ds);
    opt.classifier=@cosmo_classify_lda;

    aet(struct,opt)

    opt.output='foo';
    aet(ds,opt);


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

    opt.output='predictions';
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

