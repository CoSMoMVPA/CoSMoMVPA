function test_suite = test_cosmo_dataset_operations
% tests for slicing and stacking
%
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    initTestSuite;

function test_test_dataset
    ds=cosmo_synthetic_dataset();

    [nsamples,nfeatures]=size(ds.samples);

    assertEqual(nsamples,6);
    assertEqual(nfeatures,6);

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
    ds=cosmo_synthetic_dataset();

    % test features
    es=cosmo_slice(ds,[2 4],2);
    assertEqual(es.samples,ds.samples(:,[2 4]))
    assertEqual(es.sa,ds.sa);
    assertEqual(es.a,ds.a);

    fs=cosmo_slice(ds,1:6==2 | 1:6==4,2);
    assertEqual(es.samples,fs.samples);
    assertEqual([es.fa.i; es.fa.j; es.fa.k], [2 1; 1 2;1 1]);

    if cosmo_wtf('is_matlab')
        id_bad_index='MATLAB:badsubscript';
    else
        id_bad_index='Octave:invalid-index';
    end

    f=@() cosmo_slice(ds,-1,2);
    assertExceptionThrown(f,id_bad_index)

    f=@() cosmo_slice(ds,[2 4], 3);
    assertExceptionThrown(f,'')

    % test samples
    es=cosmo_slice(ds,[2 4]);
    assertEqual(es.samples,ds.samples([2 4],:))
    assertEqual(es.fa,ds.fa);
    assertEqual(es.a,ds.a);
    assertEqual(es.sa.targets,[2;2])

    fs=cosmo_slice(ds,(1:6)==2|(1:6)==4);
    assertEqual(es.samples,fs.samples);

    f=@() cosmo_slice(ds,-1);
    assertExceptionThrown(f,id_bad_index)



