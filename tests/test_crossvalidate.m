function test_suite = test_crossvalidate
% tests for test_crossvalidate
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_crossvalidate_basics
    classifier=@cosmo_classify_nn;
    randint=@()ceil(rand()*5+5);

    ds=cosmo_synthetic_dataset('ntargets',randint(),...
                               'nchunks',randint(),...
                               'nreps',randint(),...
                               'seed',0);    % random data
    nsamples=size(ds.samples,1);
    nfolds=randint();

    partitions=struct();
    partitions.train_indices=cell(nfolds,1);
    partitions.test_indices=cell(nfolds,1);

    train_size=ceil(nsamples*(rand()*.5+.25));

    pred=NaN(nsamples,nfolds);

    for fold=1:nfolds
        all_idx=randperm(nsamples);
        train_idx=all_idx(1:train_size);
        test_idx=all_idx((train_size+1):end);

        partitions.train_indices{fold}=train_idx;
        partitions.test_indices{fold}=test_idx;

        pred(test_idx,fold)=classifier(ds.samples(train_idx,:),...
                                        ds.sa.targets(train_idx),...
                                        ds.samples(test_idx,:));
    end

    pred_msk=~isnan(pred);
    is_correct=bsxfun(@eq,ds.sa.targets,pred) & pred_msk;
    acc=sum(is_correct(:))/sum(pred_msk(:));

    opt=struct();
    opt.check_partitions=false;

    [res_pred,res_acc]=cosmo_crossvalidate(ds,classifier,partitions,opt);
    assertEqual(res_pred,pred);
    assertElementsAlmostEqual(res_acc,acc);








