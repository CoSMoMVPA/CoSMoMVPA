function test_suite = test_cosmo_dataset_operations
    initTestSuite;

function test_test_dataset
    ds=generate_test_dataset();
    [nsamples,nfeatures]=size(ds.samples);

    assertEqual(nsamples,20);
    assertEqual(nfeatures,1001);

    fns=fieldnames(ds.sa);
    for k=1:numel(fns)
        fn=fns{k};
        v=ds.sa.(fn);
        assertTrue(isempty(v) || size(v,1)==nsamples);
    end

    fns=fieldnames(ds.fa);
    for k=1:numel(fns)
        fn=fns{k};
        v=ds.fa.(fn);
        assertTrue(isempty(v) || size(v,2)==nfeatures);
    end

function test_slicing
    ds=generate_test_dataset();

    % test features
    es=cosmo_dataset_slice(ds,[2 4],2);
    assertEqual(es.samples,ds.samples(:,[2 4]))
    assertEqual(es.sa,ds.sa);
    assertEqual(es.a,ds.a);

    fs=cosmo_dataset_slice(ds,(1:1001)==2|(1:1001)==4,2);
    assertEqual(es.samples,fs.samples);
    assertEqual(es.fa.voxel_indices, [2 4; 1 1;1 1]);

    f=@() cosmo_dataset_slice(ds,-1,2);
    assertExceptionThrown(f,'MATLAB:badsubscript')
    
    f=@() cosmo_dataset_slice(ds,[2 4], 3);
    assertExceptionThrown(f,'')

    % test samples
    es=cosmo_dataset_slice(ds,[2 4]);
    assertEqual(es.samples,ds.samples([2 4],:))
    assertEqual(es.fa,ds.fa);
    assertEqual(es.a,ds.a);
    assertEqual(es.sa.labels,{'bb','bb';'d','d'});

    fs=cosmo_dataset_slice(ds,(1:20)==2|(1:20)==4);
    assertEqual(es.samples,fs.samples);

    f=@() cosmo_dataset_slice(ds,-1);
    assertExceptionThrown(f,'MATLAB:badsubscript')

function test_stacking
    ds=generate_test_dataset();

    es=cosmo_dataset_stack({ds,ds});
    assertEqual(es.samples,[ds.samples;ds.samples])
    assertEqual(es.sa.targets,repmat(ds.sa.targets,2,1));
    assertEqual(es.fa,ds.fa);

    fs=cosmo_dataset_stack({ds,ds},1);
    assertEqual(es,fs)
    fs.fa.voxel_indices(1)=0;
    assertExceptionThrown(@()cosmo_dataset_stack({es,fs}),'');

    es=cosmo_dataset_stack({ds,ds},2);
    assertEqual(es.samples,[ds.samples ds.samples])
    es.sa.targets(1)=0;
    assertExceptionThrown(@()cosmo_dataset_stack({es,ds}),'');

