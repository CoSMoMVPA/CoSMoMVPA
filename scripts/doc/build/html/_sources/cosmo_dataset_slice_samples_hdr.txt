.. cosmo_dataset_slice_samples_hdr

cosmo dataset slice samples hdr
-------------------------------
.. code-block:: matlab

    function dataset=cosmo_dataset_slice_samples(dataset, samples_to_select)
    % Slice a dataset by samples
    %
    % This function returns a dataset that is a copy of the original dataset
    % but contains just the rows indictated in sample_indices, and the 
    % corresponding values in sample attributes.