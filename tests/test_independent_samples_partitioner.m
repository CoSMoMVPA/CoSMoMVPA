function test_suite = test_independent_samples_partitioner
% tests for cosmo_independent_samples_partitioner
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_independent_samples_partitioner_tiny()
    min_class_count=2;
    max_class_count=2+min_class_count;
    rng_class_count=[min_class_count,max_class_count];

    for nclasses=[2 3]
        for test_count=0:(nclasses+1)
            seed=ceil(rand()*1e6);
            opt=struct();
            opt.test_count=test_count;
            p1=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,opt,seed);

            opt=struct();
            opt.test_count=-test_count; % use test_ratio
            p2=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,opt,seed);

            assertEqual(p1,p2);
        end
    end


function test_independent_samples_partitioner_big()
    nclasses=ceil(rand()*4+10);
    for test_count=0:(nclasses+1)
        min_class_count=ceil(rand()*10+2);
        max_class_count=min_class_count+ceil(rand()*10+2);
        rng_class_count=[min_class_count,max_class_count];

        opt=struct();
        opt.test_count=test_count;
        opt.fold_count=ceil(rand()*100+10);

        p1=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,...
                                opt);

        opt=struct();
        opt.test_count=-test_count; % use test_ratio
        opt.fold_count=ceil(rand()*100+10);
        p2=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,...
                                opt);
    end

function test_independent_samples_partitioner_big_with_seed()
    opt=struct();
    opt.fold_count=100;
    opt.test_count=1;

    nclasses=ceil(rand()*4+10);
    min_class_count=ceil(rand()*10+2);
    max_class_count=min_class_count+ceil(rand()*10+2);
    rng_class_count=[min_class_count,max_class_count];

    ds_seed=(ceil(rand()*1e6));

    % without seed they use the default seed, must be equal
    p1=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,...
                                opt,ds_seed);
    p2=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,...
                                opt,ds_seed);
    assertEqual(p1,p2);
    opt.seed=1;
    p3=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,...
                                opt,ds_seed);
    assertEqual(p1,p3);
    opt.seed=2;
    p4=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,...
                                opt,ds_seed);
    assertFalse(isequal(p1,p4));

    % with no seed they must be identical
    opt.seed=0;
    p1=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,...
                                opt,ds_seed);
    p2=helper_test_independent_samples_partitioner(nclasses,...
                                rng_class_count,...
                                opt,ds_seed);

    assertFalse(isequal(p1,p2));




function p=helper_test_independent_samples_partitioner(nclasses,...
                            rng_class_count,opt,gen_seed)
    if nargin<4
        gen_seed=0;
    end


    ds=helper_generate_dataset(nclasses,...
                            rng_class_count,...
                            gen_seed);

    % compute how many samples per class in test set
    class_counts=histc(ds.sa.targets,1:nclasses);
    min_class_count=min(class_counts);
    max_class_count=max(class_counts);

    test_count=opt.test_count;
    if test_count<0
        % use test_ratio
        test_count=-test_count;
        opt=rmfield(opt,'test_count');
        opt.test_ratio=test_count/min_class_count;

    end

    train_count=min_class_count-test_count;

    has_illegal_count=train_count<=0 || test_count<=0;
    if has_illegal_count
        if ~isfield(opt,'fold_count')
            opt.fold_count=1;
        end
    else
        if isfield(opt,'fold_count')
            % given by calling funciton
            fold_count=opt.fold_count;
        else
            % use all folds available
            assert(nclasses<=3,'fold_count required with nclasses>3');
            assert(max_class_count<=5,'too many classes');
            % When not set we generate all possible folds; thereare at most
            % nchoosek(5,3)^nreps <= 20^3 = 8000 possible folds
            max_fold_count=8000; %

            % see how many possible folds based on each class
            combi_test=@(i)nchoosek(class_counts(i),test_count);
            test_fold_counts=arrayfun(combi_test,1:nclasses);
            combi_train=@(i)nchoosek(class_counts(i)-test_count,train_count);
            train_fold_counts=arrayfun(combi_train,1:nclasses);

            % take product
            fold_count=prod(test_fold_counts)*prod(train_fold_counts);
            assert(fold_count<=max_fold_count,'memory safety limit exceeded');
            opt.fold_count=fold_count;
        end
    end


    func=@()cosmo_independent_samples_partitioner(ds,opt);

    if has_illegal_count
        % not enough samples, expect an exception
        assertExceptionThrown(func,'')
        p=[];
        return
    end

    p=func();

    assertEqual(numel(p.train_indices),fold_count);
    assertEqual(numel(p.test_indices),fold_count);

    nsamples=size(ds.samples,1);

    train_count=min(class_counts)-test_count;

    for f=1:fold_count
        tr=p.train_indices{f};
        te=p.test_indices{f};
        assertTrue(isempty(intersect(tr,te)));

        assert_all_int_less_than(tr,nsamples);
        assert_all_int_less_than(te,nsamples);

        % equal number of targets in all classes, for train and test
        assert_all_hist_equal(ds.sa.targets(te),nclasses,test_count);
        assert_all_hist_equal(ds.sa.targets(tr),nclasses,train_count);
    end

    assert_all_folds_unique(p.train_indices,p.test_indices)


function ds=helper_generate_dataset(nclasses,rng_class_count,seed)
    % generate dataset where each target occurs at least min_class_count
    % times
    min_count=rng_class_count(1);
    max_count=rng_class_count(2);

    seed_arg={'seed',seed};

    delta=(max_count-min_count);
    assert(delta>0);

    % make lots of trials
    nregular=nclasses*min_count;
    nextra=ceil(delta*nclasses*cosmo_rand(seed_arg{:}));

    nsamples=nregular+nextra;

    ds=struct();
    ds.samples=rand(nsamples,2);
    ds.sa.targets=zeros(nsamples,1);
    rp=cosmo_randperm(nsamples,seed_arg{:});
    ds.sa.targets(1:nsamples)=mod(rp,nclasses)+1;
    ds.sa.chunks=(1:nsamples)';

    h=histc(ds.sa.targets,1:nclasses);
    assert(min(h)>=min_count)
    assert(max(h)<=max_count)



function assert_all_folds_unique(xs,ys)
    assert(all(min(cellfun(@min,xs))>=0));
    assert(all(min(cellfun(@min,ys))>=0));


    xs_max=max(cellfun(@max,xs));
    ys_max=max(cellfun(@max,ys));

    % value greater than max in all
    ys_mark=1+max(xs_max,ys_max);

    nfolds=numel(xs);
    merged=cell(nfolds,1);
    for f_i=1:nfolds

        xy=sort([xs{f_i}(:); (ys_mark+ys{f_i}(:))]);
        merged{f_i}=xy(:)';
    end

    % must all be same length
    c=cellfun(@numel,merged);
    assertEqual(c(1)+zeros(size(c)),c,'inputs do not have same length');

    % put in matrix
    merged_mat=cat(1,merged{:});
    s=sortrows(merged_mat);

    % look for duplicate rows
    eq_msk=bsxfun(@eq,s(1:(end-1),:),s(2:end,:));
    row_same=find(all(eq_msk,2),1);

    assertEqual(row_same,zeros(0,1),'row duplicate');



function assert_all_hist_equal(targets,nclasses,nreps)
    h_targets=histc(targets(:)',1:nclasses);
    assertEqual(h_targets,nreps+zeros(1,nclasses));


function assert_all_int_less_than(x,mx)
    assert(isnumeric(x));
    assertEqual(sort(x),x);
    assert(all(x>=1));
    assert(all(x<=mx));
    assert(all(round(x)==x));




function test_independent_samples_partitioner_mismatch_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                   cosmo_independent_samples_partitioner(varargin{:}),'');

    aet_targets=@(counts,varargin)aet(...
                 helper_generate_dataset_with_target_counts(counts{:}),...
                                                            varargin{:});


    opt=struct();
    opt.test_count=1;
    opt.fold_count=1;

    % missing target
    aet_targets({[3 3 3],[4 4]},opt);

    % not enought targets in one class
    aet_targets({[3 3 3],[2 2 1]},opt);


    opt.test_count=3;
    aet_targets({[4 3 4],[4 4 4]},opt);

    % try with ratio
    opt=rmfield(opt,'test_count');

    % missing target
    opt.test_ratio=.25;
    aet_targets({[10 10 10],[10 10]},opt);

    % too few targets
    aet_targets({[2 2 2],[4 4 4]},opt);

    % with too many folds
    aet_targets({[4 4 4],[4 4 4]},opt,'max_fold_count',0);



function test_independent_samples_partitioner_arg_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                   cosmo_independent_samples_partitioner(varargin{:}),'');
    ds=cosmo_synthetic_dataset();
    ds.sa.chunks=(1:size(ds.samples,1))';

    % missing arguments
    aet(ds);
    aet(ds,'fold_count');
    aet(ds,'fold_count',2);

    % mutually exclusive arguments
    aet(ds,'fold_count',2,'test_count',1,'test_ratio',.5);

    % not a dataset
    aet(struct,'fold_count',2,'test_count',1);

    % non-unique
    ds_bad=ds;
    ds_bad.sa.chunks(2)=ds.sa.chunks(1);
    aet(ds_bad,'fold_count',2,'test_count',1);


function ds=helper_generate_dataset_with_target_counts(varargin)
    nfeatures=2;
    nchunks=numel(varargin);
    ds_cell=cell(nchunks,1);
    for i=1:nchunks
        counts=varargin{i};
        nclasses=numel(counts);
        ds_parts=cell(nclasses,1);
        for j=1:nclasses
            nt=counts(j);
            ds=struct();

            ds.samples=randn(nt,nfeatures);
            ds.sa.targets=zeros(nt,1)+j;
            ds.sa.chunks=zeros(nt,1)+i;
            ds_parts{j}=ds;
        end

        ds_cell{i}=cosmo_stack(ds_parts);
    end

    ds=cosmo_stack(ds_cell);
