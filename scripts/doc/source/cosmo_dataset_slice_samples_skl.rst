.. cosmo_dataset_slice_samples_skl

cosmo dataset slice samples skl
===============================
.. code-block:: matlab

    function dataset=cosmo_dataset_slice_samples(dataset, samples_to_select)
    % Slice a dataset by samples
    %
    % This function returns a dataset that is a copy of the original dataset
    % but contains just the rows indictated in sample_indices, and the 
    % corresponding values in sample attributes.
    
    dataset.samples=dataset.samples(samples_to_select,:);
    
    fns=fieldnames(dataset.sa);
    n=numel(fns);
    for k=1:n
        fn=fns{k};
        v=dataset.sa.(fn);
        if iscell(v)
            w={v{samples_to_select}};
        else
            dataset.sa.(fn)=v(samples_to_select,:);
        end
    end
    
    