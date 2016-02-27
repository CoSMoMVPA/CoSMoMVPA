function test_suite=test_dim_generalization_measure()
% tests for cosmo_dim_generalization_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_dim_generalization_measure_basics
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_dim_generalization_measure(varargin{:}),'');

    % error on empty input
    aet(struct());
    ds=struct();
    ds.samples=0;
    aet(ds);

    ds=cosmo_synthetic_dataset('type','meeg');
    ds=cosmo_stack({ds,cosmo_slice(ds,1:2,2)},2);

     % four time points, two channels
    ds.fa.chan=[1 2 1 2 1 2 1 2];
    ds.fa.time=[1 1 2 2 3 3 4 4];
    ds.a.fdim.values{1}{end}='foochan';
    ds.a.fdim.values{2}=[-1 0 1 2];
    cosmo_check_dataset(ds);
    opt=struct();
    opt.progress=false;
    opt.measure=@delta_measure;
    aet(ds,opt);
    aet(ds,'dimension','time');
    opt.dimension='time';
    aet(ds,opt);


    ds=cosmo_dim_transpose(ds,'time',1);

    % measure must be a function handle
    aet(ds,'dimension','time','measure','foo');

    % chunks are required
    chunks=ds.sa.chunks;
    ds.sa=rmfield(ds.sa,'chunks');
    aet(ds,opt);
    ds.sa.chunks=chunks;

    % chunks must be 1 and 2, not 1, 2 and 3
    aet(ds,opt)

    ds.sa.chunks=ds.sa.targets;
    ds.sa.targets=chunks;

    % partitions not allowed
    aet(ds,opt,'partitions',cosmo_nfold_partitioner(ds));

    ds.samples=bsxfun(@plus,(ds.fa.chan-1)*12,...
                    6*(ds.sa.time-1)+3*(ds.sa.chunks-1)+ds.sa.targets);

    ds.a.sdim.values{1}(end+1)=2;
    tr_ds=cosmo_slice(ds,ds.sa.chunks==1);
    te_ds=cosmo_slice(ds,repmat(find(ds.sa.chunks==2),2,1));
    te_ds.sa.time=te_ds.sa.time+1;
    ds=cosmo_stack({tr_ds,te_ds});

    for radius=0:1
        unq_tr_time=unique(tr_ds.sa.time)';
        unq_te_time=unique(te_ds.sa.time)';

        ntime=numel(unq_tr_time)*numel(unq_te_time);
        expected_result_cell=cell(ntime,1);

        pos=0;
        for k=(1+radius):(numel(unq_tr_time)-radius)
            tr_time=unq_tr_time(k);
            tr=cosmo_slice(tr_ds,abs(tr_ds.sa.time-tr_time)<=radius);
            tr_tr=cosmo_dim_transpose(tr,'time',2);
            for j=(1+radius):(numel(unq_te_time)-radius)
                te_time=unq_te_time(j);
                te=cosmo_slice(te_ds,abs(te_ds.sa.time-te_time)<=radius);

                te_tr=cosmo_dim_transpose(te,'time',2);


                both=cosmo_stack({tr_tr,te_tr},1,'drop_nonunique');
                both.a.fdim.values=both.a.fdim.values(1);
                both.a.fdim.labels=both.a.fdim.labels(1);
                pos=pos+1;

                res=delta_measure(both);
                e=ones(size(res.samples));
                res.sa.train_time=e*k;
                res.sa.test_time=e*j;
                expected_result_cell{pos}=res;
            end
        end

        expected_result=cosmo_stack(expected_result_cell(1:pos),1);
        expected_result.a.sdim.labels=cell(1,2);
        expected_result.a.sdim.labels{1}='train_time';
        expected_result.a.sdim.labels{2}='test_time';

        tr_dim=ds.a.sdim.values{1}(unq_tr_time);
        te_dim=ds.a.sdim.values{1}(unq_te_time);

        expected_result.a.sdim.values=cell(1,2);
        expected_result.a.sdim.values{1}=tr_dim(:);
        expected_result.a.sdim.values{2}=te_dim(:);

        expected_result=cosmo_dim_prune(expected_result);

        result=cosmo_dim_generalization_measure(ds,opt,'radius',radius);
        assertEqual(result, expected_result);
    end

    % result should be unaffected by permutation of the samples
    nsamples=size(ds.samples,1);
    rp=randperm(nsamples);
    ds_perm=cosmo_slice(ds,rp);
    assertFalse(isequal(ds_perm,ds));

    opt.radius=1;
    assertExceptionThrown(@()cosmo_dim_generalization_measure(...
                                                    ds_perm,opt),'')
    %result_perm=cosmo_dim_generalization_measure(ds_perm,opt);
    %assertEqual(result_perm,result);

    % try with correlation measure
    ds=cosmo_stack({ds,ds},2);
    ds.samples=randn(size(ds.samples));
    ds_perm=cosmo_slice(ds,rp);

    opt.radius=0;
    opt.measure=@cosmo_correlation_measure;
    opt.output='correlation';
    result=cosmo_dim_generalization_measure(ds,opt);


    ds1=cosmo_slice(ds,ds.sa.chunks==1 & ds.sa.time==1);
    ds2=cosmo_slice(ds,ds.sa.chunks==2 & ds.sa.time==3);
    c=opt.measure(cosmo_stack({ds1,ds2}),opt);

    result1=cosmo_slice(result,result.sa.train_time==1 & ...
                                        result.sa.test_time==2);
    assertElementsAlmostEqual(c.samples,result1.samples);
    assertEqual(result1.sa.half1,c.sa.half1);
    assertEqual(result1.sa.half2,c.sa.half2);

    % try with crossvalidation measure
    % swap chunks to get two samples in each class in the training set
    ds.sa.chunks=3-ds.sa.chunks;
    ds1=cosmo_slice(ds,ds.sa.chunks==2 & ds.sa.time==1);
    ds2=cosmo_slice(ds,ds.sa.chunks==1 & ds.sa.time==3);
    opt.measure=@cosmo_crossvalidation_measure;
    opt.output='predictions';

    if cosmo_wtf('is_matlab')
        err_id='MATLAB:nonExistentField';
    else
        err_id='Octave:invalid-indexing';
    end
    assertExceptionThrown(@()...
            cosmo_dim_generalization_measure(ds,opt),err_id);

    opt.classifier=@cosmo_classify_lda;
    result=cosmo_dim_generalization_measure(ds,opt);

    ds_tiny=cosmo_stack({ds1,ds2});
    opt.partitions=cosmo_nchoosek_partitioner(ds_tiny,1,'chunks',2);
    r=opt.measure(ds_tiny,opt);
    ones_=ones(size(r.samples,1),1);
    r.sa.test_time=ones_*1;
    r.sa.train_time=ones_*2;
    r.sa=rmfield(r.sa,'time');

    result1=cosmo_slice(result,result.sa.train_time==2 & ...
                                        result.sa.test_time==1);
    result1.sa=rmfield(result1.sa,'transpose_ids');
    r=set_nan_chunks_unique(r);
    result1=set_nan_chunks_unique(result1);

    mp=cosmo_align(r.sa,result1.sa);
    assertEqual(r.samples(mp),result1.samples);

    % try with unbalanced partitions
    opt.classifier=@my_stupid_classifier;
    ds.sa.orig_targets=ds.sa.targets;
    ds.sa.targets(ds.sa.targets==2)=3;

    ds1=cosmo_slice(ds,ds.sa.chunks==2 & ds.sa.time==1);
    ds2=cosmo_slice(ds,ds.sa.chunks==1 & ds.sa.time==3);
    ds_tiny=cosmo_stack({ds1,ds2});

    opt.partitions=cosmo_nchoosek_partitioner(ds_tiny,1,'chunks',2);
    opt.partitions=cosmo_balance_partitions(opt.partitions,ds_tiny);
    r=opt.measure(ds_tiny,opt);
    r.sa.test_time=ones_*1;
    r.sa.train_time=ones_*2;
    r.sa=rmfield(r.sa,'time');

    opt=rmfield(opt,'partitions');
    result=cosmo_dim_generalization_measure(ds,opt);
    result1=cosmo_slice(result,result.sa.train_time==2 & ...
                                        result.sa.test_time==1);
    result1.sa=rmfield(result1.sa,'transpose_ids');

    r_msk=~isnan(r.sa.chunks);
    result1_msk=~isnan(result1.sa.chunks);

    r=cosmo_slice(r,r_msk);
    result1=cosmo_slice(result1,result1_msk);

    mp=cosmo_align(r.sa,result1.sa);
    assertEqual(r.samples(mp),result1.samples);

function ds=set_nan_chunks_unique(ds)
    nan_msk=isnan(ds.sa.chunks);
    nsamples=numel(nan_msk);
    ds.sa.chunks(nan_msk)=nsamples+(1:sum(nan_msk));

function pred=my_stupid_classifier(x,y,z,unused)
    [foo,i]=sort(x(:));
    unq=unique(y);
    pred=unq(mod(i(1:size(z,1)),numel(unq))+1);

function z=delta_func(x,y)
    z_mat=bsxfun(@minus,mean(x,1),mean(y,1)');
    z=z_mat(:);

function x=delta_measure(ds,unused)
    msk=ds.sa.chunks==1;

    x=cosmo_slice(ds,msk);
    y=cosmo_slice(ds,~msk);

    x.samples=delta_func(x.samples,y.samples);
    x.sa=struct();
    x.sa.mu=abs(x.samples);
    x.a=rmfield(x.a,'fdim');
    x=rmfield(x,'fa');

