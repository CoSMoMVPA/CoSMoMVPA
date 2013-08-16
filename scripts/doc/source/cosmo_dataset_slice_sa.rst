.. cosmo_dataset_slice_sa

cosmo dataset slice sa
----------------------
.. code-block:: matlab

    function dataset=cosmo_dataset_slice_sa(dataset, samples_to_select)
    % Slice a dataset by samples, aka rows
    %   
    %   dataset = cosmo_dataset_slice_sa(dataset, samples_to_select)
    %   
    %   Input
    %       dataset: an instance of cosmo_fmri_dataset
    %       samples_to_select:  An N x 1 array of ones and zeros, where N is the
    %                           number of samples in the dataset, ones correspond to
    %                           samples indices to keep
    %   Returns
    %       dataset:    an instance of an fmri_dataset that is a copy of the input dataset
    %                   but contains just the rows indictated in sample_indices, and the 
    %                   corresponding values in sample attributes.
    
    %%
    % First slice the samples array by rows
    
    dataset.samples=dataset.samples(samples_to_select,:);
    
    %%
    %   Then go through each of the sample attributes and slice each one.
    %
    %   Hint: we used the matlab function 'fieldnames' to list the field in
    %   dataset.sa in case it is missing either targets or chunk, or in case there
    %   may be extra unknown sample attributes
    
    fns = fieldnames(dataset.sa); 
    n = numel(fns);
    
    for k=1:n
        fn = fns{k};
        sa = dataset.sa.(fn);
        dataset.sa.(fn)=sa(samples_to_select,:);
    end
    