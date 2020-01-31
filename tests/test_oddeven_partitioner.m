function test_suite=test_oddeven_partitioner
% tests for cosmo_oddeven_partitioner
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_test_oddeven_partitioner_basics
    for nchunks=[2 6 8]
        ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',nchunks);

        nsamples=size(ds.samples,1);
        rp=randperm(nsamples);
        ds=cosmo_slice(ds,[rp rp]);

        unq_chunks=unique(ds.sa.chunks);
        msk_odd=cosmo_match(ds.sa.chunks,unq_chunks(1:2:end));

        idx_odd=find(msk_odd);
        idx_even=find(~msk_odd);

        fp=struct();
        fp.train_indices={idx_odd, idx_even};
        fp.test_indices={idx_even, idx_odd};
        assert_partitions_equal(fp,cosmo_oddeven_partitioner(ds,'full'));
        %c=ds.sa.chunks;
        %assert_partitions_equal(fp,cosmo_oddeven_partitioner(c,'full'));

        hp=struct();
        hp.train_indices={idx_odd};
        hp.test_indices={idx_even};
        assert_partitions_equal(hp,cosmo_oddeven_partitioner(ds,'half'));
        %c=ds.sa.chunks;
        %assert_partitions_equal(hp,cosmo_oddeven_partitioner(c,'half'));
    end


function test_test_oddeven_partitioner_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_oddeven_partitioner(varargin{:}),'');
    ds=struct();
    aet(ds);
    ds.samples=zeros(3,4);
    aet(ds);
    ds=cosmo_synthetic_dataset('nchunks',1);
    aet(ds);

    ds=cosmo_synthetic_dataset('nchunks',2);
    aet(ds,'foo');



function assert_partitions_equal(p,q)
    expected_fieldnames={'train_indices';'test_indices'};
    assertEqual(sort(fieldnames(p)),sort(expected_fieldnames));
    assertEqual(sort(fieldnames(p)),sort(fieldnames(q)));

    assert_cell_same_elements(p.train_indices,q.train_indices);
    assert_cell_same_elements(p.test_indices,q.test_indices);

function assert_cell_same_elements(p,q)
    assertEqual(size(p),size(q));
    n=numel(p);
    for k=1:n
        assertEqual(sort(p{k}),sort(q{k}));
    end

function test_unbalanced_partitions()
    ds=struct();
    ntargets=randi();
    nchunks=randi();
    ds.samples=randn(ntargets*nchunks,1);
    ds.sa.chunks=repmat(1:nchunks,1,ntargets)';
    ds.sa.targets=repmat(1:ntargets,1,nchunks)';

    idxs=cosmo_randperm(numel(ds.sa.chunks));
    ds=cosmo_slice(ds,idxs);

    % should be ok
    cosmo_oddeven_partitioner(ds);

    idx=ceil(rand()*ntargets*nchunks);
    ds.sa.chunks(idx)=ds.sa.chunks(idx)+1;
    assertExceptionThrown(@() cosmo_oddeven_partitioner(ds),'*');

function v=randi()
    v=ceil(rand()*10+2);


