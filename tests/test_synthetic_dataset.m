function test_suite=test_synthetic_dataset
    initTestSuite;

function test_synthetic_dataset_basics()
    ds=cosmo_synthetic_dataset();
    assertElementsAlmostEqual(ds.samples([1 6,1 6]),...
                             [2.0317 -1.3265 2.0317 -1.3265],...
                             'absolute',1e-4);
    assertEqual(size(ds.samples),[6 6]);
    assertEqual(sort(fieldnames(ds)),{'a';'fa';'sa';'samples'});
    assertEqual(ds.sa.targets,[1 2 1 2 1 2]');
    assertEqual(ds.sa.chunks,[1 1 2 2 3 3]');

    ds=cosmo_synthetic_dataset('seed',2);
    assertElementsAlmostEqual(ds.samples([1 6,1 6]),...
                              [2.0801 -0.4390 2.0801 -0.4390],...
                             'absolute',1e-4);

    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',2);
    assertEqual(ds.sa.targets,[1 2 3 1 2 3]');
    assertEqual(ds.sa.chunks,[1 1 1 2 2 2]');


