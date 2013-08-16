.. cosmo_dataset_slice_sa_hdr

cosmo dataset slice sa hdr
==========================
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