.. run_demean

run demean
==========
.. code-block:: matlab

    %% Example of de-meaning
    %
    
    %% Generate random dataset
    ds=struct();
    ds.samples=(rand(20,12));
    subplot(1,2,1);
    imagesc(ds.samples,[-1 1])
    colorbar();
    title('before de-meaning');
    
    %% Demean the dataset
    ds.samples = bsxfun(@minus, ds.samples, mean(ds.samples,1));
    subplot(1,2,2);
    imagesc(ds.samples,[-1 1])
    colorbar();
    title('after de-meaning');
    
    
    