function test_suite=test_balance_partitions
% tests for cosmo_balance_partitions
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_balance_partitions_repeats
    nchunks=5;
    nsamples=200;
    nclasses=4;
    [p,ds]=get_sample_data(nsamples,nchunks,nclasses);

    opt_cell={{ {'balance_test',false},...
            {'balance_test',true},...
            {},...
          },...
          { {'nrepeats',1},...
            {'nrepeats',5},...
            {}...
          },...
          { {'opt_as_struct',false},...
            {'opt_as_struct',true},...
          }};
    opt_prod=cosmo_cartprod(opt_cell);

    defaults=struct();
    defaults.nrepeats=1;
    defaults.balance_test=true;

    for k=1:size(opt_prod,1)
        opt=opt_prod(k,:);
        opt_struct=cosmo_structjoin(opt);
        opt_as_struct=opt_struct.opt_as_struct;
        opt_struct=rmfield(opt_struct,'opt_as_struct');
        if opt_as_struct;
            args=opt_struct;
        else
            args=[fieldnames(opt_struct) struct2cell(opt_struct)]';
        end

        b=cosmo_balance_partitions(p,ds,args);

        full_args=cosmo_structjoin(defaults,args);
        nrep=full_args.nrepeats;
        balance_test=full_args.balance_test;

        assertEqual(numel(b.train_indices),nrep*nchunks);
        assertEqual(numel(b.test_indices),nrep*nchunks);
        assertEqual(fieldnames(b),{'train_indices';'test_indices'});

        nfolds=numel(p.test_indices);
        for j=1:nfolds
            pi=p.train_indices{j};
            pt=ds.sa.targets(pi);

            for k=1:nrep
                fold_i=(j-1)*nrep+k;
                bi=b.train_indices{fold_i};
                bt=ds.sa.targets(bi);
                h=histc(bt,1:nclasses)';
                assertTrue(all(min(histc(pt,1:nclasses))==h));
            end
        end

        assert_partitions_ok(ds,b,balance_test);
        assert_balanced_partitions_subset(p,b);
    end

function assert_balanced_partitions_subset(unbal_partitions,bal_partitions)
% each training and test fold in bal_partitions must correspond to
% a fold in the original partitions
    nsamples=max([cellfun(@max,unbal_partitions.train_indices) ...
                    cellfun(@max,unbal_partitions.test_indices)]);
    unbal_nfolds=numel(unbal_partitions.train_indices);

    % see which indices were used in each fold
    msk_train=find_member(unbal_partitions,'train_indices',nsamples);
    msk_test=find_member(unbal_partitions,'test_indices',nsamples);

    unbal_was_used=false(unbal_nfolds,1);

    bal_nfolds=numel(bal_partitions.train_indices);
    for fold_i=1:bal_nfolds
        bal_train=bal_partitions.train_indices{fold_i};
        bal_test=bal_partitions.test_indices{fold_i};

        candidate_msk=all(msk_train(:,bal_train),2) & ...
                            all(msk_test(:,bal_test),2);

        assert(any(candidate_msk));
        unbal_was_used(candidate_msk)=true;
    end

    assertEqual(unbal_was_used,true(unbal_nfolds,1));

function msk=find_member(partitions, label, nsamples)
    folds=partitions.(label);
    nfolds=numel(folds);
    msk=false(nfolds,nsamples);
    for k=1:nfolds
        msk(k,folds{k})=true;
    end

function assert_partitions_ok(ds, partitions, balanced_test_indices)
    assertEqual(sort(fieldnames(partitions)),sort({'train_indices';...
                                                   'test_indices'}));
    nfolds=numel(partitions.train_indices);
    assertEqual(numel(partitions.test_indices),nfolds);

    for fold_i=1:nfolds
        assert_fold_balanced(ds,partitions,fold_i, 'train_indices');
        if balanced_test_indices
            assert_fold_balanced(ds,partitions,fold_i, 'test_indices');
        end
        assert_fold_no_double_dipping(ds,partitions,fold_i);
        assert_fold_targets_match(ds,partitions,fold_i);
        assert_fold_indices_unique(partitions,fold_i);
    end

function assert_fold_no_double_dipping(ds, partitions, fold)
    train_indices=partitions.train_indices;
    test_indices=partitions.test_indices;

    train_chunks=ds.sa.chunks(train_indices{fold});
    test_chunks=ds.sa.chunks(test_indices{fold});

    assert(isempty(intersect(train_chunks,test_chunks)));


function assert_fold_balanced(ds, partitions, fold, label)
    all_indices=partitions.(label);
    indices=all_indices{fold};

    unq_targets=unique(ds.sa.targets);
    targets=ds.sa.targets(indices);

    assertEqual(unique(targets),unq_targets);
    h=histc(targets,unq_targets);
    assertEqual(h(1)*ones(size(h)),h);

function assert_fold_targets_match(ds,partitions,fold)
    train_indices=partitions.train_indices{fold};
    test_indices=partitions.test_indices{fold};

    nsamples=size(ds.samples,1);
    assert_all_int_with_max(train_indices,nsamples);
    assert_all_int_with_max(test_indices,nsamples);

    train_targets=ds.sa.targets(train_indices);
    test_targets=ds.sa.targets(test_indices);
    assertEqual(unique(train_targets),unique(test_targets));

function assert_fold_indices_unique(partitions,fold)
    train_indices=partitions.train_indices{fold};
    test_indices=partitions.test_indices{fold};

    assert(isequal(sort(train_indices),unique(train_indices)));
    assert(isequal(sort(test_indices),unique(test_indices)));

function assert_all_int_with_max(indices,max_value)
    assert(min(indices)>=1);
    assert(max(indices)<=max_value);
    assert(all(round(indices)==indices));



function test_balance_partitions_nmin
    nchunks=5;
    nsamples=200;
    nclasses=4;
    [p,ds]=get_sample_data(nsamples,nchunks,nclasses);

    nmin=8+round(rand()*4);
    args=struct();
    args.nmin=nmin;
    args.balance_test=[false,true];

    arg_prod=cosmo_cartprod(args);

    for arg_i=1:numel(arg_prod)
        arg=arg_prod{arg_i};
        b=cosmo_balance_partitions(p,ds,arg);

        counter=zeros(nsamples,nchunks);

        for j=1:numel(b.train_indices)
            bi=b.train_indices{j};
            bj=b.test_indices{j};

            ch=unique(ds.sa.chunks(bj));
            assert(numel(ch)==1);

            if arg.balance_test
                % no other indices
                assertEqual(setdiff(bj,p.test_indices{ch}),zeros(0,1));
            else
                assertEqual(sort(bj),p.test_indices{ch});
            end

            bt=ds.sa.targets(bi);

            h=histc(bt,1:nclasses);
            assertEqual(ones(nclasses,1)*h(1),h);

            counter(bi,ch)=counter(bi,ch)+1;
        end

        for k=1:nchunks
            msk=ds.sa.chunks~=k;
            assert(min(counter(msk,k))>=nmin);
            assert(all(counter(~msk,k)==0));
        end

        assert_partitions_ok(ds,b,arg.balance_test);
        assert_balanced_partitions_subset(p,b);
    end

function test_balance_partitions_exceptions

    ds=cosmo_synthetic_dataset();
    p=cosmo_nfold_partitioner(ds);
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_balance_partitions(varargin{:}),'');

    aet(struct,struct)
    aet(ds,p); % wrong order

    aet(p,ds,'nmin',1,'nrepeats',1);

    % create missing class
    ds.sa.targets(1)=4;
    aet(p,ds);

    % missing target
    p.train_indices{1}=p.train_indices{1}([1 3]);
    aet(p,ds);

    % double dipping
    p.train_indices{1}=p.train_indices{2};
    aet(p,ds);


function [p,ds]=get_sample_data(nsamples,nchunks,nclasses)


    ds=struct();
    ds.samples=(1:nsamples)';
    ds.sa.targets=ceil(cosmo_rand(nsamples,1)*nclasses);
    ds.sa.chunks=ceil(cosmo_rand(nsamples,1)*nchunks);

    p=cosmo_nfold_partitioner(ds);
