.. cosmo_dataset_slice_sa_hdr

cosmo dataset slice sa hdr
--------------------------
.. code-block:: matlab

    function dataset=cosmo_dataset_slice_sa(dataset, samples_to_select)
    % Slice a dataset by samples, aka rows
    %   
    %   dataset = cosmo_dataset_slice_sa(dataset, samples_to_select)
    %   
    %   Input
    %       dataset: an instance of cosmo_fmri_dataset with N samples
    %       samples_to_select:  Either an Nx1 boolean mask, or a vector with 
    %                           indices.
    %   Returns
    %       dataset:    an instance of an fmri_dataset that is a copy of the input dataset
    %                   but contains just the rows indictated in sample_indices, and the 
    %                   corresponding values in sample attributes.