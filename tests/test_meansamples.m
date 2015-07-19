function test_suite = test_meansamples
    %initTestSuite;
    test_meansamples_()

function test_meansamples_()
    ntargets=4;
    nchunks=6;
    
    ds=cosmo_synthetic_dataset('ntargets', ntargets, 'nchunks', nchunks);
    samples=ds.samples;
    targets=ds.sa.targets;
    
    [mean_samples, mean_targets] = cosmo_meansamples(samples, targets, nchunks);
    
    assert(isequal(size(mean_samples), [ntargets, size(samples, 2)]));
    for k=unique(targets)'
       assert(sum((mean(samples(targets == k, :), 1) - mean_samples(k, :))) < 10^-15); 
    end
    
    % check it doesn't puke with a different number of nmean_trl
    try
        [mean_samples, mean_targets] = cosmo_meansamples(samples, targets, 3);
    catch err
        rethrow(err);
    end
