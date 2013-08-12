.. exercise_permutation_test_skl

exercise permutation test skl
=============================
.. code-block:: matlab

    %% Permutation test example
    %
    % A simple example of running a permutation test to determine the
    % signifance of classification accuracies
    
    %% Set the number of permutations
    niter=1000;
    
    %% Define dataset, classifier, partitioner
    data_path=cosmo_get_data_path('s01');
    
    data_fn=fullfile(data_path,'glm_betas_perrun.nii.gz');
    mask_fn=fullfile(data_path,'vt_mask.nii.gz');
    ds=cosmo_fmri_dataset(data_fn,'mask',mask_fn,...
                            'targets',repmat(1:6,1,10),...
                            'chunks',floor(((1:60)-1)/6)+1);
    
    % select only a few samples - otherwise we have too much power (!)
    ds=cosmo_dataset_select_samples(ds,ds.sa.chunks<=4);
                        
    classifier=@cosmo_classify_nn;
    partitions=cosmo_nfold_partition(ds);
    
    %% compute classification accuracy of the original data
    [pred, acc]=cosmo_cross_validate(ds, classifier, partitions);
    
    %% prepare for permutations
    acc0=zeros(niter,1); % allocate space for permuted accuracies 
    ds0=ds; % make a copy of the dataset
    
    %% for _niter_ iterations, reshuffle the labels and compute accuracy
    % [your code here]
    
    p=sum(acc<acc0)/niter;
    fprintf('%d permutations: p=%.4f\n', niter, p);
    
    bins=0:20/niter:1; % 
    h=histc(acc0,bins);
    bar(bins,h)
    hold on
    line([acc acc],[0,max(h)])
    hold off
    
    