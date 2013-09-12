function test_suite = test_cosmo_dataset_operations
    initTestSuite;

function test_nfold_partitioner()
    ds=generate_test_dataset();

    p=cosmo_nfold_partitioner(ds);
    assertEqual(p, cosmo_nfold_partitioner(ds.sa.chunks));

    fns={'train_indices';'test_indices'};
    assertEqual(fns, fieldnames(p));
    for k=1:5
        test_indices=(k-1)*4+(1:4);
        train_indices=setdiff(1:20,test_indices);
        for j=1:2
            fn=fns{j};
            if j==1
                v=train_indices;
            else
                v=test_indices;
            end
            w=p.(fn);
            assertEqual(w{k}, v);
        end
    end

function test_nchoosek_partitioner()    
    ds=generate_test_dataset();

    p=cosmo_nfold_partitioner(ds);
    q=cosmo_nchoosek_partitioner(ds,1);
    assertEqual(p,q);

    q=cosmo_nchoosek_partitioner(ds,.2);
    assertEqual(p,q);

    assertExceptionThrown(@()cosmo_nchoosek_partitioner(ds,-1),'');
    assertExceptionThrown(@()cosmo_nchoosek_partitioner(ds,0),'');
    assertExceptionThrown(@()cosmo_nchoosek_partitioner(ds,1.01),'');
    assertExceptionThrown(@()cosmo_nchoosek_partitioner(ds,.99),'');

    p=cosmo_nchoosek_partitioner(ds,3);
    q=cosmo_nchoosek_partitioner(ds,.6);

    assertEqual(p,q);
    assertFalse(isequal(p, cosmo_nchoosek_partitioner(ds,.4)));

    fns={'train_indices';'test_indices'};
    for j=1:2
        fn=fns{j};
        counts=zeros(20,1);

        v=p.(fn);
        assertEqual(size(v),[1 10]);

        for k=1:numel(v)
            w=v{k};
            counts(w)=counts(w)+1;
        end
        assertEqual(counts,ones(20,1)*j*2+2);
    end

