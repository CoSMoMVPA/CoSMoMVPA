.. cosmo_dataset_slice_features_hdr

cosmo dataset slice features hdr
================================
.. code-block:: matlab

    function dataset=cosmo_dataset_slice_features(dataset, features_to_select)
    % Slice a dataset by samples
    %
    % This function returns a dataset that is a copy of the original dataset
    % but contains just the rows indictated in features_to_select, and the 
    % corresponding values in feature attributes.